<#
.SYNOPSIS
Onboarding Phase 2 - License / Access via group membership (recommended).

.DESCRIPTION
Adds an existing Entra ID user to one or more groups (typically licensing groups).
This supports enterprise best practice: group-based licensing in M365.

- Validates inputs
- Connects to Microsoft Graph with least-privilege delegated scopes
- Resolves user by UPN (idempotent)
- Adds user to specified groups (idempotent-ish: ignores "already exists")
- Writes a transcript and returns a structured object
- Optional: set UsageLocation (some tenants require before licensing)

.NOTES
- Does NOT assign licenses directly. Use group-based licensing in Entra/M365.
- Requires Microsoft.Graph PowerShell SDK.
#>

[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string]$UserPrincipalName,

  # Group(s) to add the user to (licensing and/or access groups)
  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string[]]$GroupObjectIds,

  # Optional, often required for license assignment
  [Parameter()]
  [ValidatePattern('^[A-Z]{2}$')]
  [string]$UsageLocation,

  # Optional: force explicit tenant when you have multiple accounts signed in
  [Parameter()]
  [string]$TenantId,

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

function Ensure-GraphModule {
  if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    throw "Microsoft.Graph PowerShell SDK not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
  }
}

function Connect-GraphIfNeeded {
  param(
    [string]$TenantId
  )

  Ensure-GraphModule

  $scopes = @(
    "User.ReadWrite.All",
    "Group.ReadWrite.All"
  )

  $ctx = Get-MgContext -ErrorAction SilentlyContinue
  if (-not $ctx) {
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
    if ($TenantId) {
      Connect-MgGraph -TenantId $TenantId -Scopes $scopes | Out-Null
    } else {
      Connect-MgGraph -Scopes $scopes | Out-Null
    }
  } elseif ($TenantId -and ($ctx.TenantId -ne $TenantId)) {
    Write-Host "Graph context is for a different tenant. Reconnecting..." -ForegroundColor Yellow
    Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
    Connect-MgGraph -TenantId $TenantId -Scopes $scopes | Out-Null
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

function Try-AddToGroup {
  param(
    [Parameter(Mandatory)][string]$UserId,
    [Parameter(Mandatory)][string]$GroupId
  )

  # Graph returns an error if member already exists; handle gracefully.
  try {
    New-MgGroupMemberByRef -GroupId $GroupId -BodyParameter @{
      "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$UserId"
    } | Out-Null

    return "Added"
  } catch {
    $msg = $_.Exception.Message
    if ($msg -match "added object references already exist" -or $msg -match "One or more added object references already exist") {
      return "AlreadyMember"
    }
    throw
  }
}

# --- Begin main ---
Ensure-Directory -Path $LogDirectory
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$transcriptPath = Join-Path $LogDirectory "onboarding-phase2-license-$($UserPrincipalName.Replace('@','_'))-$timestamp.log"

Start-Transcript -Path $transcriptPath -Append | Out-Null

try {
  Write-Host "---- M365 Onboarding Phase 2 (License/Access via Groups) ----" -ForegroundColor Cyan
  Write-Host "UPN: $UserPrincipalName"
  Write-Host "Groups to add: $($GroupObjectIds.Count)"
  if ($UsageLocation) { Write-Host "UsageLocation to set: $UsageLocation" }
  if ($DryRun) { Write-Host "[DryRun] No changes will be made." -ForegroundColor Yellow }

  if (-not $DryRun) {
    Connect-GraphIfNeeded -TenantId $TenantId
  }

  $user = $null
  if (-not $DryRun) {
    $user = Get-UserByUpn -Upn $UserPrincipalName
    if (-not $user) { throw "User not found in tenant: $UserPrincipalName" }
  }

  $userId = if ($DryRun) { "DRYRUN-USER" } else { $user.Id }

  # Optional usage location update
  $usageLocationSet = $false
  if ($UsageLocation) {
    if ($PSCmdlet.ShouldProcess($UserPrincipalName, "Set usageLocation to $UsageLocation")) {
      if ($DryRun) {
        Write-Host "[DryRun] Would set usageLocation to: $UsageLocation" -ForegroundColor Yellow
      } else {
        Update-MgUser -UserId $userId -UsageLocation $UsageLocation | Out-Null
        $usageLocationSet = $true
        Write-Host "usageLocation set to: $UsageLocation" -ForegroundColor Green
      }
    }
  }

  # Add to groups
  $groupResults = @()
  foreach ($gid in $GroupObjectIds) {
    if ([string]::IsNullOrWhiteSpace($gid)) { continue }

    if ($PSCmdlet.ShouldProcess($UserPrincipalName, "Add to group $gid")) {
      if ($DryRun) {
        Write-Host "[DryRun] Would add user to group: $gid" -ForegroundColor Yellow
        $groupResults += [pscustomobject]@{ GroupId=$gid; Result="WouldAdd" }
      } else {
        $r = Try-AddToGroup -UserId $userId -GroupId $gid
        Write-Host "Group $gid => $r" -ForegroundColor Green
        $groupResults += [pscustomobject]@{ GroupId=$gid; Result=$r }
      }
    }
  }

  $result = [pscustomobject]@{
    Phase            = "Onboarding-Phase2-LicenseAccess"
    UserPrincipalName= $UserPrincipalName
    UserId           = $userId
    UsageLocationSet = $usageLocationSet
    UsageLocation    = $UsageLocation
    GroupsRequested  = $GroupObjectIds
    GroupsProcessed  = $groupResults
    DryRun           = [bool]$DryRun
    TranscriptPath   = $transcriptPath
    Timestamp        = (Get-Date).ToString("o")
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
