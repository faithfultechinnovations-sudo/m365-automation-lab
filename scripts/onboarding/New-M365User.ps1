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
