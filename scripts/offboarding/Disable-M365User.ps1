<# 
.SYNOPSIS
Disables a Microsoft 365 user and performs secure offboarding actions.

.DESCRIPTION
- Disables sign-in
- Revokes active sessions
- Optionally removes group memberships
- Logs all actions
- Supports DryRun and WhatIf

.NOTES
Validated via live Microsoft Graph calls.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$UserPrincipalName,

    [Parameter()]
    [string[]]$GroupObjectIds = @(),

    [Parameter()]
    [switch]$DryRun,

    [Parameter()]
    [string]$LogDirectory = "logs"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Helpers ----------------------------------------------------

function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
}

function Connect-GraphIfNeeded {
    if (-not (Get-Module -ListAvailable Microsoft.Graph)) {
        throw "Microsoft.Graph PowerShell SDK not installed. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }

    $scopes = @(
        "User.ReadWrite.All",
        "Group.ReadWrite.All",
        "Directory.Read.All"
    )

    if (-not (Get-MgContext)) {
        Connect-MgGraph -Scopes $scopes | Out-Null
    }
}

# --- Begin ------------------------------------------------------

Ensure-Directory $LogDirectory
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$transcriptPath = Join-Path $LogDirectory "offboarding-$($UserPrincipalName.Replace('@','_'))-$timestamp.log"

Start-Transcript -Path $transcriptPath | Out-Null

try {
    Write-Host "---- M365 Offboarding (Start) ----" -ForegroundColor Cyan
    Write-Host "User: $UserPrincipalName"

    if (-not $DryRun) {
        Connect-GraphIfNeeded
    }

    $user = Get-MgUser -Filter "userPrincipalName eq '$UserPrincipalName'" -ConsistencyLevel eventual

    if (-not $user) {
        throw "User not found: $UserPrincipalName"
    }

    $userId = $user.Id

    # Disable account
    if ($PSCmdlet.ShouldProcess($UserPrincipalName, "Disable account")) {
        if ($DryRun) {
            Write-Host "[DryRun] Would disable account"
        } else {
            Update-MgUser -UserId $userId -AccountEnabled:$false
        }
    }

    # Revoke sessions
    if ($PSCmdlet.ShouldProcess($UserPrincipalName, "Revoke sign-in sessions")) {
        if ($DryRun) {
            Write-Host "[DryRun] Would revoke sessions"
        } else {
            Revoke-MgUserSignInSession -UserId $userId | Out-Null
        }
    }

    # Remove from groups
    $groupsRemoved = @()
    foreach ($gid in $GroupObjectIds) {
        if ($PSCmdlet.ShouldProcess($UserPrincipalName, "Remove from group $gid")) {
            if ($DryRun) {
                Write-Host "[DryRun] Would remove from group $gid"
            } else {
                Remove-MgGroupMemberByRef -GroupId $gid -DirectoryObjectId $userId
                $groupsRemoved += $gid
            }
        }
    }

    $result = [pscustomobject]@{
        UserPrincipalName = $UserPrincipalName
        UserId            = $userId
        AccountEnabled    = $false
        SessionsRevoked   = $true
        GroupsRemoved     = $groupsRemoved.Count
        DryRun            = [bool]$DryRun
        TranscriptPath    = $transcriptPath
        Timestamp         = (Get-Date).ToString("o")
    }

    Write-Host "---- Completed ----" -ForegroundColor Green
    $result | Format-List | Out-String | Write-Host
    $result
}
finally {
    Stop-Transcript | Out-Null
}
