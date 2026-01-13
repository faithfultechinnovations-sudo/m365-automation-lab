# User Onboarding Runbook

## Purpose
Automate Microsoft 365 user onboarding using Microsoft Graph with secure, repeatable steps.

## Script
`scripts/onboarding/New-M365User.ps1`

## Prerequisites
- PowerShell 7 recommended
- Microsoft Graph PowerShell SDK installed:
  - `Install-Module Microsoft.Graph -Scope CurrentUser`
- Permissions (consented for the operator account):
  - `User.ReadWrite.All`
  - `Group.ReadWrite.All`

## Recommended Pattern
Use **group-based licensing**:
- Create licensing groups in Entra ID
- Assign licenses to groups in M365
- Add users to the appropriate groups during onboarding

## Example Usage

### Dry run (no changes)
```powershell
.\scripts\onboarding\New-M365User.ps1 `
  -UserPrincipalName "jane.doe@contoso.com" `
  -DisplayName "Jane Doe" `
  -GivenName "Jane" `
  -Surname "Doe" `
  -UsageLocation "US" `
  -GroupObjectIds @("00000000-0000-0000-0000-000000000000") `
  -DryRun
