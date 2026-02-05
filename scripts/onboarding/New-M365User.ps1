<#
.SYNOPSIS
Creates a new Microsoft 365 user in Entra ID (Azure AD) and performs onboarding actions.

.DESCRIPTION
Automation-first onboarding using Microsoft Graph:
- Validates inputs
- Connects to Microsoft Graph with least-privilege scopes
- Checks for existing user (idempotency guard)
- Creates user with a temporary password (optionally force change at next sign-in)
- Adds user to specified groups (preferred: group-based licensing)
- Sets usageLocation (often required for licensing)
- Writes structured output and logs a transcript

.NOTES
- Designed for lab/educational use. Review before production usage.
- Prefer group-based licensing in M365 (add user to licensing groups).
#>

[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
  # User identity
  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string]$UserPrincipalName,

  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string]$DisplayName,

  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string]$GivenName,

  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string]$Surname,

  # Optional user attributes
  [Parameter()]
  [ValidatePattern('^[A-Z]{2}$')]
  [string]$UsageLocation = 'US',

  [Parameter()]
  [ValidateNotNullOrEmpty()]
  [string]$MailNickname,

  # Security / password
  [Parameter()]
  [ValidateNotNullOrEmpty()]
  [string]$TempPassword,

  [Parameter()]
  [bool]$ForceChangePasswordNextSignIn = $true,

  # Group-based licensing / role groups
  [Parameter()]
  [string[]]$GroupObjectIds = @(),

  # Safe execution
  [Parameter()]
  [switch]$DryRun,

  # Logging
  [Parameter()]
  [string]$LogDirectory = "logs",

  # Output control
  [Parameter()]
  [switch]$RevealTempPassword
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Common module import (repo-root relative) ---
$repoRoot = (git rev-parse --show-toplevel 2>$null).Trim()
if (-not $repoRoot) { throw "Run inside the git repo; unable to locate repo root." }

# Suppress unapproved-verb warnings for internal helper module
Import-Module (
  Join-Path $repoRoot "modules/M365Automation.Common/M365Automation.Common.psm1"
) -Force -DisableNameChecking

Import-Module (
  Join-Path $repoRoot "modules/M365Automation.Common/M365Automation.Common.psm1"
) -Force -DisableNameChecking

function New-StrongTempPassword {
  # Simple generator (lab use). In production, enforce your org policy.
  $chars = "abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ23456789!@#$%*?"
  $rand = New-Object System.Random
  -join (1..16 | ForEach-Object { $chars[$rand.Next(0, $chars.Length)] })
}

function Connect-GraphIfNeeded {
  if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    throw "Microsoft.Graph PowerShell SDK not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
  }

  $scopes = @(
    "User.ReadWrite.All",
    "Group.ReadWrite.All"
  )

  $ctx = Get-MgContext -ErrorAction SilentlyContinue
  if (-not $ctx) {
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
    Connect-MgGraph -Scopes $scopes | Out-Null
  }
}

function Get-UserByUpn {
  param([Parameter(Mandatory)][string]$Upn)

  try {
    return Get-MgUser -UserId $Upn -ErrorAction Stop
  } catch {
    $escaped = $Upn.Replace("'", "''")
    $result = Get-MgUser -Filter "userPrincipalName eq '$escaped'" -ConsistencyLevel eventual -CountVariable c -ErrorAction SilentlyContinue
    return $result | Select-Object -First 1
  }
}

# --- Begin main ---

$runName = $UserPrincipalName.Replace("@","_")
$transcriptPath = Start-RunTranscript -Area "onboarding" -RunName $runName

Confirm-TenantContext `
  -ExpectedTenantDomain $env:M365_TENANT_DOMAIN `
  -ExpectedTenantId $env:M365_TENANT_ID `
  -ExpectedAccountSuffix $env:M365_ACCOUNT_SUFFIX `
  -Scopes @("User.ReadWrite.All","Group.ReadWrite.All","Organization.Read.All")

try {
  if (-not $MailNickname -or [string]::IsNullOrWhiteSpace($MailNickname)) {
    $MailNickname = ($UserPrincipalName.Split('@')[0]) -replace '[^a-zA-Z0-9._-]', ''
  }
  
  if (-not $TempPassword -or [string]::IsNullOrWhiteSpace($TempPassword)) {
    $TempPassword = New-StrongTempPassword
  }

  Write-Host "---- M365 Onboarding (Start) ----" -ForegroundColor Cyan
  Write-Host "UPN: $UserPrincipalName"
  Write-Host "DisplayName: $DisplayName"
  Write-Host "UsageLocation: $UsageLocation"
  Write-Host "Groups to add: $($GroupObjectIds.Count)"

  $userId = $null

  if ($DryRun) {
    Write-Host "[DryRun] No changes will be made." -ForegroundColor Yellow
  } else {
    Connect-GraphIfNeeded
  }

  # Idempotency guard
  $existing = $null
  if (-not $DryRun) {
    $existing = Get-UserByUpn -Upn $UserPrincipalName
  }

  if ($existing) {
    Write-Host "User already exists: $($existing.Id) ($($existing.UserPrincipalName)). Skipping creation." -ForegroundColor Yellow
    $userId = $existing.Id
  } else {
    $createBody = @{
      accountEnabled    = $true
      displayName       = $DisplayName
      mailNickname      = $MailNickname
      userPrincipalName = $UserPrincipalName
      givenName         = $GivenName
      surname           = $Surname
      usageLocation     = $UsageLocation
      passwordProfile   = @{
        password = $TempPassword
        forceChangePasswordNextSignIn = $ForceChangePasswordNextSignIn
      }
    }

    if ($PSCmdlet.ShouldProcess($UserPrincipalName, "Create Entra ID user")) {

  if ($DryRun) {
    Write-Host "[DryRun] Would create user with body:" -ForegroundColor Yellow

    $safeBody = $createBody.Clone()
    $safeBody.passwordProfile = $safeBody.passwordProfile.Clone()
    $safeBody.passwordProfile.password = "***redacted***"

    $safeBody | ConvertTo-Json -Depth 6 | Write-Host
    $userId = "DRYRUN-USER"
  }
  else {
    Write-Host "Creating user in Entra ID..." -ForegroundColor Cyan
    $newUser = New-MgUser -BodyParameter $createBody
    $userId = $newUser.Id
    Write-Host "Created user: $userId" -ForegroundColor Green
  }

}


  # Group membership (preferred: group-based licensing)
  foreach ($gid in $GroupObjectIds) {
    if ([string]::IsNullOrWhiteSpace($gid)) { continue }

    if ($PSCmdlet.ShouldProcess($UserPrincipalName, "Add to group $gid")) {
      if ($DryRun) {
        Write-Host "[DryRun] Would add user to group: $gid" -ForegroundColor Yellow
      } else {
        New-MgGroupMemberByRef -GroupId $gid -BodyParameter @{
          "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$userId"
        } | Out-Null

        Write-Host "Added to group: $gid" -ForegroundColor Green
      }
    }
  }

  # Output object
  $result = [pscustomobject]@{
    UserPrincipalName = $UserPrincipalName
    DisplayName       = $DisplayName
    UserId            = $userId
    UsageLocation     = $UsageLocation
    MailNickname      = $MailNickname
    GroupsAdded       = $GroupObjectIds
    TempPassword      = if ($RevealTempPassword) { $TempPassword } else { $null }
    DryRun            = [bool]$DryRun
    TranscriptPath    = $transcriptPath
    Timestamp         = (Get-Date).ToString("o")
  }

  if ($DryRun) {
    Write-Host "[DryRun] Onboarding simulation completed." -ForegroundColor Yellow
  }

  Write-Host "---- Completed ----" -ForegroundColor Green
  $result | Format-List | Out-String | Write-Host

# --- Run summary (success) ---
$summary = @{
  area      = "onboarding"
  upn       = $UserPrincipalName
  userId    = $userId
  groups    = $GroupObjectIds
  outcome   = "success"
  transcript= $transcriptPath
  timestamp = (Get-Date).ToString("o")
}
Write-RunSummary -Area "onboarding" -RunName $RunName -Summary $summary | Out-Null

  # Return to pipeline
  $result
}
}
catch {
  $summary = @{
    area      = "onboarding"
    upn       = $UserPrincipalName
    userId    = $userId
    groups    = $GroupObjectIds
    outcome   = "failed"
    error     = $_.Exception.Message
    transcript= $transcriptPath
    timestamp = (Get-Date).ToString("o")
  }

  Write-RunSummary -Area "onboarding" -RunName $runName -Summary $summary | Out-Null
  Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
  throw
}

finally {
  Stop-RunTranscript | Out-Null
}
