<#
.SYNOPSIS
Onboarding Phase 2 - Mailbox readiness check (Exchange Online).

.DESCRIPTION
After licensing (typically via group-based licensing), a mailbox may take time to provision.
This script verifies mailbox existence and (optionally) waits until it appears.

- Uses Exchange Online PowerShell (ExchangeOnlineManagement module)
- Checks if a mailbox exists for the given user principal name
- Optionally waits/polls until mailbox is provisioned (timeout)
- Writes a transcript and returns structured output

NOTES
- This script is intentionally separate from licensing/group membership.
- In many tenants, mailbox provisioning requires an Exchange license (directly or via group).
#>

[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Low')]
param(
  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string]$UserPrincipalName,

  # Wait until mailbox exists (poll)
  [Parameter()]
  [switch]$Wait,

  # How long to wait for mailbox provisioning
  [Parameter()]
  [ValidateRange(1, 240)]
  [int]$TimeoutMinutes = 20,

  # Poll interval while waiting
  [Parameter()]
  [ValidateRange(5, 300)]
  [int]$PollSeconds = 30,

  # Safe execution
  [Parameter()]
  [switch]$DryRun,

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

function Ensure-ExchangeModule {
  if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    throw "ExchangeOnlineManagement module not found. Install with: Install-Module ExchangeOnlineManagement -Scope CurrentUser"
  }
}

function Connect-ExchangeIfNeeded {
  Ensure-ExchangeModule

  # Detect existing EXO session
  $connected = $false
  try {
    $info = Get-ConnectionInformation -ErrorAction SilentlyContinue
    if ($info) { $connected = $true }
  } catch { $connected = $false }

  if (-not $connected) {
    Write-Host "Connecting to Exchange Online..." -ForegroundColor Cyan
    Connect-ExchangeOnline | Out-Null
  }
}

function Test-MailboxExists {
  param([Parameter(Mandatory)][string]$Upn)
  try {
    # Prefer EXO V3 cmdlet if available
    $mbx = Get-EXOMailbox -Identity $Upn -ErrorAction Stop
    return $true
  } catch {
    # fallback for older environments
    try {
      $mbx2 = Get-Mailbox -Identity $Upn -ErrorAction Stop
      return $true
    } catch {
      return $false
    }
  }
}

# --- Begin main ---
Ensure-Directory -Path $LogDirectory
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$transcriptPath = Join-Path $LogDirectory "onboarding-phase2-mailbox-$($UserPrincipalName.Replace('@','_'))-$timestamp.log"

Start-Transcript -Path $transcriptPath -Append | Out-Null

try {
  Write-Host "---- M365 Onboarding Phase 2 (Mailbox Readiness) ----" -ForegroundColor Cyan
  Write-Host "UPN: $UserPrincipalName"
  Write-Host "Wait: $([bool]$Wait)  TimeoutMinutes: $TimeoutMinutes  PollSeconds: $PollSeconds"
  if ($DryRun) { Write-Host "[DryRun] No changes will be made." -ForegroundColor Yellow }

  if (-not $DryRun) {
    Connect-ExchangeIfNeeded
  }

  $start = Get-Date
  $exists = $false

  if ($DryRun) {
    $exists = $false
  } else {
    $exists = Test-MailboxExists -Upn $UserPrincipalName
  }

  if (-not $exists -and $Wait -and -not $DryRun) {
    Write-Host "Mailbox not found yet. Waiting for provisioning..." -ForegroundColor Yellow
    $deadline = $start.AddMinutes($TimeoutMinutes)

    while ((Get-Date) -lt $deadline) {
      Start-Sleep -Seconds $PollSeconds
      $exists = Test-MailboxExists -Upn $UserPrincipalName
      if ($exists) { break }
      Write-Host "Still waiting... ($(Get-Date -Format T))" -ForegroundColor DarkYellow
    }
  }

  $elapsed = (Get-Date) - $start

  $result = [pscustomobject]@{
    Phase            = "Onboarding-Phase2-MailboxReadiness"
    UserPrincipalName= $UserPrincipalName
    MailboxExists    = $exists
    Wait             = [bool]$Wait
    TimeoutMinutes   = $TimeoutMinutes
    PollSeconds      = $PollSeconds
    ElapsedSeconds   = [int]$elapsed.TotalSeconds
    DryRun           = [bool]$DryRun
    TranscriptPath   = $transcriptPath
    Timestamp        = (Get-Date).ToString("o")
  }

  if ($exists) {
    Write-Host "Mailbox is present." -ForegroundColor Green
  } else {
    Write-Host "Mailbox NOT found." -ForegroundColor Red
    Write-Host "If this is unexpected, confirm the user has an Exchange license (often via licensing group) and wait a few minutes." -ForegroundColor Yellow
  }

  Write-Host "---- Completed ----" -ForegroundColor Green
  $result | Format-List | Out-String | Write-Host

  $result
}
catch {
  Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
  throw
}
finally {
  Stop-Transcript | Out-Null
}
