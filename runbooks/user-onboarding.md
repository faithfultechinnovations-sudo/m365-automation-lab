# User Onboarding Runbook

## Purpose

Safely onboard a Microsoft 365 user using Microsoft Graph with **secure, repeatable, and auditable** automation.

This runbook creates a new Entra ID user, applies required attributes, and optionally assigns group memberships for license and access management.

Designed for:
- Security-first onboarding
- Least-privilege Microsoft Graph access
- Idempotent execution (safe re-runs)
- Operational and audit clarity

---

## What This Runbook Does

✔ Creates a new Entra ID user  
✔ Sets required identity attributes (UPN, name, usage location)  
✔ Forces password change at first sign-in (default)  
✔ Optionally adds the user to groups (recommended for licensing)  
✔ Writes a timestamped transcript for auditing  

## What This Runbook Does NOT Do

✖ Assign licenses directly (use group-based licensing)  
✖ Configure mailbox, OneDrive, or Teams settings  
✖ Manage Intune devices or compliance policies  

> These actions are intentionally handled in later onboarding phases.

---

## Script

Primary script:

- `scripts/onboarding/New-M365User.ps1`

---

## Prerequisites

- PowerShell 7 recommended (Windows PowerShell 5.1 supported)
- Microsoft Graph PowerShell SDK installed:

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
```

---

## Example Usage

> Run from the repository root (the folder containing `README.md`).

---

### 1) Dry run (no changes)

```powershell
.\scripts\onboarding\New-M365User.ps1 `
  -UserPrincipalName "jane.doe@faithfultechinnovations.onmicrosoft.com" `
  -DisplayName "Jane Doe" `
  -GivenName "Jane" `
  -Surname "Doe" `
  -UsageLocation "US" `
  -DryRun
```

### 2) Live run (creates the user)

```powershell
.\scripts\onboarding\New-M365User.ps1 `
  -UserPrincipalName "jane.doe@faithfultechinnovations.onmicrosoft.com" `
  -DisplayName "Jane Doe" `
  -GivenName "Jane" `
  -Surname "Doe" `
  -UsageLocation "US"
```

### 3) Onboarding with group-based licensing

```powershell
.\scripts\onboarding\New-M365User.ps1 `
  -UserPrincipalName "jane.doe@faithfultechinnovations.onmicrosoft.com" `
  -DisplayName "Jane Doe" `
  -GivenName "Jane" `
  -Surname "Doe" `
  -UsageLocation "US" `
  -GroupObjectIds @(
    "11111111-1111-1111-1111-111111111111",
    "22222222-2222-2222-2222-222222222222"
  )
```

### 4) Automation-friendly (no prompts)

```powershell
.\scripts\onboarding\New-M365User.ps1 `
  -UserPrincipalName "jane.doe@faithfultechinnovations.onmicrosoft.com" `
  -DisplayName "Jane Doe" `
  -GivenName "Jane" `
  -Surname "Doe" `
  -UsageLocation "US" `
  -Confirm:$false
```

---

## Expected Output (Example)

```text
UserPrincipalName : jane.doe@faithfultechinnovations.onmicrosoft.com
DisplayName       : Jane Doe
UserId            : 2c2c1669-9fa9-45f7-983b-1639f3604fcf
UsageLocation     : US
MailNickname      : jane.doe
GroupsAdded       : {11111111-1111-1111-1111-111111111111}
TempPassword      : ********
DryRun            : False
TranscriptPath    : logs/onboarding-jane.doe_faithfultechinnovations.onmicrosoft.com-20260113-102509.log
Timestamp         : 2026-01-13T10:25:22-06:00
```
