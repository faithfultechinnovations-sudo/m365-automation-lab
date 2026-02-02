<#
.SYNOPSIS
Exports a point-in-time access snapshot for a Microsoft 365 (Entra ID) user.

.DESCRIPTION
Captures a reversible, auditable inventory of the user's access state prior to suspension/offboarding:
- User identity + account status
- Group memberships (security + M365 groups)
- Directory roles (Entra ID roles)
- License assignments (SKU IDs + part numbers)
- Optional manager
- Tenant context + timestamp

Outputs a JSON snapshot file, and optionally CSV exports.
Designed to pair with Suspend/Disable offboarding scripts.

.NOTES
- Requires Microsoft Graph PowerShell SDK
- Uses least-privilege READ scopes
- Supports -WhatIf for file writes
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$UserPrincipalName,

    [Parameter()]
    [string]$OutputDirectory = "logs\snapshots",

    [Parameter()]
    [switch]$IncludeCsv,

    [Parameter()]
    [switch]$IncludeManager,

    # Safety guard: ensure you're connected to the intended tenant
    [Parameter()]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string]$ExpectedTenantId,

    [Parameter()]
    [switch]$DryRun,

    [Parameter()]
    [string]$LogDirectory = "logs"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Helpers ----------------------------------------------------

function Ensure-Directory {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
}

function Connect-GraphIfNeeded {
    if (-not (Get-Module -ListAvailable Microsoft.Graph)) {
        throw "Microsoft.Graph PowerShell SDK not installed. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }

    # Read-only scopes for snapshotting
    $scopes = @(
        "User.Read.All",
        "Group.Read.All",
        "Directory.Read.All",
        "Organization.Read.All"
    )

    if (-not (Get-MgContext)) {
        Connect-MgGraph -Scopes $scopes | Out-Null
    }
}

function Assert-ExpectedTenant {
    param([string]$Expected)

    if (-not $Expected) { return }

    $ctx = Get-MgContext
    if (-not $ctx -or -not $ctx.TenantId) {
        throw "Graph context not available. Connect-MgGraph did not establish a context."
    }

    if ($ctx.TenantId -ne $Expected) {
        throw "Connected tenant mismatch. Expected TenantId '$Expected' but connected to '$($ctx.TenantId)'. Aborting."
    }
}

function Safe-UpnForFilename {
    param([Parameter(Mandatory)][string]$Upn)
    return ($Upn -replace '[^a-zA-Z0-9@._-]', '_').Replace('@','_')
}

# --- Begin ------------------------------------------------------

Ensure-Directory $LogDirectory
Ensure-Directory $OutputDirectory

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$upnSafe = Safe-UpnForFilename $UserPrincipalName

$transcriptPath = Join-Path $LogDirectory "snapshot-$upnSafe-$timestamp.log"
Start-Transcript -Path $transcriptPath | Out-Null

try {
    Write-Host "---- Export M365 User Access Snapshot (Start) ----" -ForegroundColor Cyan
    Write-Host "User: $UserPrincipalName"
    Write-Host "OutputDirectory: $OutputDirectory"
    Write-Host "IncludeCsv: $IncludeCsv | IncludeManager: $IncludeManager | DryRun: $DryRun"

    $jsonPath = Join-Path $OutputDirectory "access-snapshot-$upnSafe-$timestamp.json"

    if ($DryRun) {
        Write-Host "[DryRun] Would connect to Microsoft Graph and export snapshot to:" -ForegroundColor Yellow
        Write-Host "[DryRun]   $jsonPath" -ForegroundColor Yellow

        if ($IncludeCsv) {
            Write-Host "[DryRun] Would also export CSVs for groups/roles/licenses." -ForegroundColor Yellow
        }

        return [pscustomobject]@{
            UserPrincipalName = $UserPrincipalName
            JsonPath          = $jsonPath
            IncludeCsv        = [bool]$IncludeCsv
            IncludeManager    = [bool]$IncludeManager
            DryRun            = $true
            TranscriptPath    = $transcriptPath
            Timestamp         = (Get-Date).ToString('o')
        }
    }

    Connect-GraphIfNeeded
    Assert-ExpectedTenant -Expected $ExpectedTenantId

    # Tenant context (best-effort)
    $org = $null
    try {
        $org = Get-MgOrganization -All | Select-Object -First 1
    } catch {
        Write-Host "[Warn] Unable to read organization details: $($_.Exception.Message)" -ForegroundColor Yellow
    }

    # Resolve user by UPN
    $user = Get-MgUser -Filter "userPrincipalName eq '$UserPrincipalName'" -ConsistencyLevel eventual
    if (-not $user) {
        throw "User not found: $UserPrincipalName"
    }

    $userId = $user.Id

    # --- Group memberships & directory roles --------------------
    $memberOf = @()
    try {
        $memberOf = Get-MgUserMemberOf -UserId $userId -All
    } catch {
        throw "Failed to read memberships (memberOf) for user. $($_.Exception.Message)"
    }

    $groups = @()
    $roles  = @()

    foreach ($obj in $memberOf) {
        $odataType = $null
        if ($obj.AdditionalProperties -and $obj.AdditionalProperties.ContainsKey('@odata.type')) {
            $odataType = [string]$obj.AdditionalProperties['@odata.type']
        }

        switch ($odataType) {
            '#microsoft.graph.group' {
                $groups += [pscustomobject]@{
                    Id          = $obj.Id
                    DisplayName = [string]$obj.AdditionalProperties['displayName']
                }
            }
            '#microsoft.graph.directoryRole' {
                $roles += [pscustomobject]@{
                    Id          = $obj.Id
                    DisplayName = [string]$obj.AdditionalProperties['displayName']
                }
            }
            default {
                # ignore other types (e.g., administrativeUnit)
            }
        }
    }

    # Sort for stable diffs
    $groups = $groups | Sort-Object DisplayName, Id
    $roles  = $roles  | Sort-Object DisplayName, Id

    # --- Licenses -----------------------------------------------
    $licenseDetails = @()
    try {
        $licenseDetails = Get-MgUserLicenseDetail -UserId $userId -All
    } catch {
        Write-Host "[Warn] Unable to read license details: $($_.Exception.Message)" -ForegroundColor Yellow
    }

    $licenses = @()
    foreach ($ld in $licenseDetails) {
        $licenses += [pscustomobject]@{
            SkuId         = $ld.SkuId
            SkuPartNumber = $ld.SkuPartNumber
        }
    }
    $licenses = $licenses | Sort-Object SkuPartNumber, SkuId

    # --- Manager (optional) -------------------------------------
    $manager = $null
    if ($IncludeManager) {
        try {
            $mgrObj = Get-MgUserManager -UserId $userId
            if ($mgrObj -and $mgrObj.Id) {
                $mgrUser = Get-MgUser -UserId $mgrObj.Id
                if ($mgrUser) {
                    $manager = [pscustomobject]@{
                        Id                = $mgrUser.Id
                        DisplayName       = $mgrUser.DisplayName
                        UserPrincipalName = $mgrUser.UserPrincipalName
                    }
                }
            }
        } catch {
            Write-Host "[Warn] Unable to read manager: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    # --- Build snapshot object ----------------------------------
    $ctx = Get-MgContext
    $snapshot = [pscustomobject]@{
        SnapshotVersion = '1.0'
        CapturedAtUtc   = (Get-Date).ToUniversalTime().ToString('o')
        Tenant          = [pscustomobject]@{
            TenantId   = $ctx.TenantId
            TenantName = if ($org) { $org.DisplayName } else { $null }
        }
        User = [pscustomobject]@{
            Id                = $user.Id
            UserPrincipalName = $user.UserPrincipalName
            DisplayName       = $user.DisplayName
            Mail              = $user.Mail
            AccountEnabled    = $user.AccountEnabled
            UserType          = $user.UserType
        }
        Manager  = $manager
        Groups   = $groups
        Roles    = $roles
        Licenses = $licenses
        Metadata = [pscustomobject]@{
            IncludeManager = [bool]$IncludeManager
            IncludeCsv     = [bool]$IncludeCsv
            Script         = $MyInvocation.MyCommand.Name
        }
    }

    # --- Write outputs ------------------------------------------
    if ($PSCmdlet.ShouldProcess($UserPrincipalName, "Write snapshot JSON to $jsonPath")) {
        $snapshot | ConvertTo-Json -Depth 8 | Out-File -FilePath $jsonPath -Encoding utf8
        Write-Host "Wrote JSON: $jsonPath" -ForegroundColor Green
    }

    $csvPaths = @{}
    if ($IncludeCsv) {
        $groupsCsv   = Join-Path $OutputDirectory "access-snapshot-$upnSafe-$timestamp-groups.csv"
        $rolesCsv    = Join-Path $OutputDirectory "access-snapshot-$upnSafe-$timestamp-roles.csv"
        $licensesCsv = Join-Path $OutputDirectory "access-snapshot-$upnSafe-$timestamp-licenses.csv"

        if ($PSCmdlet.ShouldProcess($UserPrincipalName, "Write groups CSV to $groupsCsv")) {
            $groups | Export-Csv -Path $groupsCsv -NoTypeInformation -Encoding utf8
            $csvPaths.Groups = $groupsCsv
        }
        if ($PSCmdlet.ShouldProcess($UserPrincipalName, "Write roles CSV to $rolesCsv")) {
            $roles | Export-Csv -Path $rolesCsv -NoTypeInformation -Encoding utf8
            $csvPaths.Roles = $rolesCsv
        }
        if ($PSCmdlet.ShouldProcess($UserPrincipalName, "Write licenses CSV to $licensesCsv")) {
            $licenses | Export-Csv -Path $licensesCsv -NoTypeInformation -Encoding utf8
            $csvPaths.Licenses = $licensesCsv
        }

        Write-Host "Wrote CSVs (if any objects existed)." -ForegroundColor Green
    }

    $result = [pscustomobject]@{
        UserPrincipalName = $user.UserPrincipalName
        UserId            = $userId
        TenantId          = $ctx.TenantId
        GroupsCount       = ($groups | Measure-Object).Count
        RolesCount        = ($roles  | Measure-Object).Count
        LicensesCount     = ($licenses | Measure-Object).Count
        JsonPath          = $jsonPath
        CsvPaths          = $csvPaths
        TranscriptPath    = $transcriptPath
        Timestamp         = (Get-Date).ToString('o')
    }

    Write-Host "---- Completed ----" -ForegroundColor Green
    $result | Format-List | Out-String | Write-Host
    return $result
}
finally {
    Stop-Transcript | Out-Null
}
