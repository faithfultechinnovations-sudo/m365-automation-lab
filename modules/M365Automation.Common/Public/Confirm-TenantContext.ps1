function Confirm-TenantContext {
  [CmdletBinding(SupportsShouldProcess=$true)]
  param(
    [string]$ExpectedTenantDomain,
    [string]$ExpectedTenantId,
    [string]$ExpectedAccountSuffix,
    [string[]]$Scopes = @("User.Read.All"),
    [switch]$RequireConfirmation
  )

  if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    throw "Microsoft.Graph module not found. Install-Module Microsoft.Graph -Scope CurrentUser"
  }

  Import-Module Microsoft.Graph -ErrorAction Stop

  $ctx = Get-MgContext -ErrorAction SilentlyContinue
  if (-not $ctx -or -not $ctx.TenantId) {
    if ($PSCmdlet.ShouldProcess("Microsoft Graph", "Connect")) {
      Connect-MgGraph -Scopes $Scopes -ErrorAction Stop | Out-Null
      $ctx = Get-MgContext
    }
  }

  if (-not $ctx -or -not $ctx.TenantId) { throw "Unable to determine Graph tenant context." }

  $tenantId = $ctx.TenantId
  $tenantDomain = $null

  try {
    $org = Get-MgOrganization -Top 1 -ErrorAction Stop
    $tenantDomain = ($org.VerifiedDomains | Where-Object { $_.IsDefault } | Select-Object -First 1).Name
    if (-not $tenantDomain) { $tenantDomain = ($org.VerifiedDomains | Select-Object -First 1).Name }
  } catch {}

  Write-Host "Connected TenantId: $tenantId"
  if ($tenantDomain) { Write-Host "Default Domain:     $tenantDomain" }
  if ($ctx.Account)  { Write-Host "Account:           $($ctx.Account)" }

  if ($ExpectedTenantId -and ($tenantId -ne $ExpectedTenantId)) {
    throw "Wrong tenant: expected TenantId '$ExpectedTenantId' but connected to '$tenantId'."
  }

  if ($ExpectedTenantDomain -and $tenantDomain -and ($tenantDomain.ToLower() -ne $ExpectedTenantDomain.ToLower())) {
    throw "Wrong tenant: expected domain '$ExpectedTenantDomain' but connected to '$tenantDomain'."
  }

  if ($ExpectedAccountSuffix -and $ctx.Account -and (-not $ctx.Account.ToLower().EndsWith($ExpectedAccountSuffix.ToLower()))) {
    throw "Wrong account: expected suffix '$ExpectedAccountSuffix' but connected as '$($ctx.Account)'."
  }

  if ($RequireConfirmation) {
    $ok = Read-Host "Type YES to continue in this tenant"
    if ($ok -ne "YES") { throw "User aborted." }
  }

  [pscustomobject]@{
    TenantId     = $tenantId
    TenantDomain = $tenantDomain
    Account      = $ctx.Account
    Scopes       = $ctx.Scopes
  }
}
