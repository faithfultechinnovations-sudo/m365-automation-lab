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
- Optionally sets usageLocation (needed for license assignment in many tenants)
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

  TempPassword      = if ($RevealTempPassword) { $TempPassword } else { $null }

  # Group-based licensing / role groups
  [Parameter()]
  [string[]]$GroupObjectIds = @(),

  # Safe execution
  [Parameter()]
  [switch]$DryRun,

  [Parameter()]
  [switch]$RevealTempPassword

  # Logging
  [Parameter()]
  [string]$LogDirectory = "logs"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Ensure-Directory {
  param([Parameter(Mandatory)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Path $Path | Out-Null
  }
}

function New-StrongTempPassword {
  # Simple generator (lab use). In production, enforce your org policy.
  $chars = "abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ23456789!@#$%*?"
  $rand = New-Object System.Random
  -join (1..16 | ForEach-Object { $chars[$rand.Next(0, $chars.Length)] })
}

function Connect-GraphIfNeeded {
  # Require Microsoft Graph module
  if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    throw "Microsoft.Graph PowerShell SDK not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
  }

  # Scopes: create users, read users, update users, manage group membership
  $scopes = @(
    "User.ReadWrite.All",
    "Group.ReadWrite.All"
  )

  # Connect only if not already connected
  $ctx = Get-MgContext -ErrorAction SilentlyContinue
  if (-not $ctx) {
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
    Connect-MgGraph -Scopes $scopes | Out-Null
  }
}

function Get-UserByUpn {
  param([Parameter(Mandatory)][string]$Upn)
  # Try direct by UPN (works in many tenants). Fallback to filter.
  try {
    return Get-MgUser -UserId $Upn -ErrorAction Stop
  } catch {
    $escaped = $Upn.Replace("'", "''")
    $result = Get-MgUser -Filter "userPrincipalName eq '$escaped'" -ConsistencyLevel eventual -CountVariable c -ErrorAction SilentlyContinue
    return $result | Select-Object -First 1
  }
}

# --- Begin main ---
Ensure-Directory -Path $LogDirectory
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$transcriptPath = Join-Path $LogDirectory "onboarding-$($UserPrincipalName.Replace('@','_'))-$timestamp.log"

Start-Transcript -Path $transcriptPath -Append | Out-Null

try {
  if (-not $MailNickname -or [string]::IsNullOrWhiteSpace($MailNickname)) {
    # Default mailNickname: left side of UPN, cleaned
    $MailNickname = ($UserPrincipalName.Split('@')[0]) -replace '[^a-zA-Z0-9._-]', ''
  }

  if (-not $TempPassword -or [string]::IsNullOrWhiteSpace($TempPassword)) {
    $TempPassword = New-StrongTempPassword
  }

  Write-Host "---- M365 Onboarding شروع (Onboarding Start) ----" -ForegroundColor Cyan
  Write-Host "UPN: $UserPrincipalName"
  Write-Host "DisplayName: $DisplayName"
  Write-Host "UsageLocation: $UsageLocation"
  Write-Host "Groups to add: $($GroupObjectIds.Count)"

  if ($DryRun) {
    Write-Host "[DryRun] No changes will be made." -ForegroundColor Yellow
  } else {
    Connect-GraphIfNeeded
  }

  # Idempotency guard: check if user already exists
  $existing = $null
  if (-not $DryRun) {
    $existing = Get-UserByUpn -Upn $UserPrincipalName
  }

  if ($existing) {
    Write-Host "User already exists: $($existing.Id) ($($existing.UserPrincipalName)). Skipping creation." -ForegroundColor Yellow
    $userId = $existing.Id
  } else {
    $createBody = @{
      accountEnabled = $true
      displayName    = $DisplayName
      mailNickname   = $MailNickname
      userPrincipalName = $UserPrincipalName
      givenName      = $GivenName
      surname        = $Surname
      usageLocation  = $UsageLocation
      passwordProfile = @{
        password = $TempPassword
        forceChangePasswordNextSignIn = $ForceChangePasswordNextSignIn
      }
    }

    if ($PSCmdlet.ShouldProcess($UserPrincipalName, "Create Entra ID user")) {
      if ($DryRun) {
        Write-Host "[DryRun] Would create user with body:" -ForegroundColor Yellow
        $createBody | ConvertTo-Json -Depth 6 | Write-Host
        $userId = "DRYRUN-USER"
      } else {
        Write-Host "Creating user in Entra ID..." -ForegroundColor Cyan
        $newUser = New-MgUser -BodyParameter $createBody
        $userId = $newUser.Id
        Write-Host "Created user: $userId" -ForegroundColor Green
      }
    }
  }

  # Add to groups (recommended approach for licensing)
  foreach ($gid in $GroupObjectIds) {
    if ([string]::IsNullOrWhiteSpace($gid)) { continue }

    if ($PSCmdlet.ShouldProcess($UserPrincipalName, "Add to group $gid")) {
      if ($DryRun) {
        Write-Host "[DryRun] Would add user to group: $gid" -ForegroundColor Yellow
      } else {
        # Add user as group member
        New-MgGroupMemberByRef -GroupId $gid -BodyParameter @{
          "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$userId"
        } | Out-Null

        Write-Host "Added to group: $gid" -ForegroundColor Green
      }
    }
  }

  # Output (structured)
  $result = [pscustomobject]@{
    UserPrincipalName = $UserPrincipalName
    DisplayName       = $DisplayName
    UserId            = $userId
    UsageLocation     = $UsageLocation
    MailNickname      = $MailNickname
    GroupsAdded       = $GroupObjectIds
    TempPassword      = $TempPassword
    DryRun            = [bool]$DryRun
    TranscriptPath    = $transcriptPath
    Timestamp         = (Get-Date).ToString("o")
  }

  Write-Host "---- Completed ----" -ForegroundColor Green
  $result | Format-List | Out-String | Write-Host

  # Also return object to pipeline
  $result
}
catch {
  Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
  throw
}
finally {
  Stop-Transcript | Out-Null
}

