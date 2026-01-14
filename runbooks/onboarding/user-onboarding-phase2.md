# \# User Onboarding – Phase 2 (License + Mailbox Readiness)

# 

# \## Purpose

# 

# Phase 2 finishes \*service readiness\* after the identity exists (Phase 1).  

# We keep this split into \*\*two scripts\*\* so runs are \*\*clean, auditable, and reversible\*\*:

# 

# 1\) \*\*License / Access\*\* via group membership (recommended)

# 2\) \*\*Mailbox readiness\*\* verification (and optional wait/poll)

# 

# ---

# 

# \## Scripts

# 

# \- License / Access (group-based licensing): `scripts/onboarding-phase2/Add-M365UserToGroups.ps1`

# \- Mailbox readiness (Exchange Online): `scripts/onboarding-phase2/Test-M365MailboxReadiness.ps1`

# 

# ---

# 

# \## Prerequisites

# 

# \### Common

# \- Run from repository root.

# \- PowerShell 7 recommended.

# \- Microsoft Graph PowerShell SDK:

# ```powershell

# Install-Module Microsoft.Graph -Scope CurrentUser

# ```

# 

# \### Mailbox readiness script only

# \- Exchange Online module:

# ```powershell

# Install-Module ExchangeOnlineManagement -Scope CurrentUser

# ```

# 

# ---

# 

# \## 1) License / Access via groups

# 

# \### Dry run

# ```powershell

# .\\scripts\\onboarding-phase2\\Add-M365UserToGroups.ps1 `

# &nbsp; -UserPrincipalName "jane.doe@faithfultechinnovations.onmicrosoft.com" `

# &nbsp; -GroupObjectIds @(

# &nbsp;   "11111111-1111-1111-1111-111111111111",

# &nbsp;   "22222222-2222-2222-2222-222222222222"

# &nbsp; ) `

# &nbsp; -DryRun

# ```

# 

# \### Live run

# ```powershell

# .\\scripts\\onboarding-phase2\\Add-M365UserToGroups.ps1 `

# &nbsp; -UserPrincipalName "jane.doe@faithfultechinnovations.onmicrosoft.com" `

# &nbsp; -GroupObjectIds @(

# &nbsp;   "11111111-1111-1111-1111-111111111111",

# &nbsp;   "22222222-2222-2222-2222-222222222222"

# &nbsp; ) `

# &nbsp; -UsageLocation "US"

# ```

# 

# \### Automation-friendly (no prompts)

# ```powershell

# .\\scripts\\onboarding-phase2\\Add-M365UserToGroups.ps1 `

# &nbsp; -UserPrincipalName "jane.doe@faithfultechinnovations.onmicrosoft.com" `

# &nbsp; -GroupObjectIds @("11111111-1111-1111-1111-111111111111") `

# &nbsp; -Confirm:$false

# ```

# 

# ---

# 

# \## 2) Mailbox readiness

# 

# \### Check once

# ```powershell

# .\\scripts\\onboarding-phase2\\Test-M365MailboxReadiness.ps1 `

# &nbsp; -UserPrincipalName "jane.doe@faithfultechinnovations.onmicrosoft.com"

# ```

# 

# \### Wait until mailbox appears (poll)

# ```powershell

# .\\scripts\\onboarding-phase2\\Test-M365MailboxReadiness.ps1 `

# &nbsp; -UserPrincipalName "jane.doe@faithfultechinnovations.onmicrosoft.com" `

# &nbsp; -Wait `

# &nbsp; -TimeoutMinutes 30 `

# &nbsp; -PollSeconds 30

# ```

# 

# ---

# 

# \## Expected Outputs

# 

# Both scripts:

# \- Print a clear status summary

# \- Return a structured object

# \- Write a timestamped transcript in `logs/`



