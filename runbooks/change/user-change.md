# User Change Runbook (Profile + Access)

## Purpose

Safely update an existing Microsoft 365 (Entra ID) user using Microsoft Graph with **repeatable, auditable, and idempotent** steps.

This runbook covers “day‑2” lifecycle changes such as:
- **Profile updates** (name, title, department, manager, usage location)
- **Access updates** via **group membership changes** (recommended for permission + license group-based management)

> This runbook intentionally **does not** rename UPN/email identity. That’s a higher‑risk change and should be handled by a separate “Rename UPN / Mail” runbook.

---

## What This Runbook Does

✔ Updates selected user profile fields (only the fields you pass)  
✔ Optionally sets `usageLocation` (needed for many licensing flows)  
✔ Adds/removes user to/from groups (licensing groups and access groups)  
✔ Produces a structured result object (automation friendly)  
✔ Writes a timestamped transcript log for auditing  

## What This Runbook Does NOT Do

✖ Rename UserPrincipalName (UPN) / primary SMTP  
✖ Directly assign/remove licenses (use group-based licensing)  
✖ Modify mailbox, OneDrive, Teams settings (Phase-2 workflows)  
✖ Touch Intune devices or compliance policies  

---

## Script

Primary script:

- `scripts/change/Update-M365User.ps1`

---

## Prerequisites

- PowerShell 7 recommended (Windows PowerShell 5.1 supported)
- Microsoft Graph PowerShell SDK installed:

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
```

---

## Permissions Required (Microsoft Graph)

**Delegated Graph scopes requested by the script:**
- `User.ReadWrite.All`
- `Group.ReadWrite.All`
- `Directory.ReadWrite.All` *(only needed if you use manager updates)*

> In many tenants, an appropriate Entra role (often **Global Administrator** or **User Administrator** + group management privileges) is required to consent to these scopes and perform changes.

---

## Examples

> Run from the repository root (the folder containing `README.md`).

### 1) Dry run (no changes)

```powershell
.\scripts\change\Update-M365User.ps1 `
  -UserPrincipalName "jane.doe@faithfultechinnovations.onmicrosoft.com" `
  -JobTitle "Support Specialist" `
  -Department "IT" `
  -DryRun
```

### 2) Update profile fields

```powershell
.\scripts\change\Update-M365User.ps1 `
  -UserPrincipalName "jane.doe@faithfultechinnovations.onmicrosoft.com" `
  -DisplayName "Jane A. Doe" `
  -GivenName "Jane" `
  -Surname "Doe" `
  -JobTitle "Senior Support Specialist" `
  -Department "IT" `
  -OfficeLocation "Dallas" `
  -MobilePhone "+1 555 555 5555" `
  -UsageLocation "US"
```

### 3) Add/remove groups (access + licensing)

```powershell
.\scripts\change\Update-M365User.ps1 `
  -UserPrincipalName "jane.doe@faithfultechinnovations.onmicrosoft.com" `
  -AddGroupObjectIds @(
    "11111111-1111-1111-1111-111111111111"
  ) `
  -RemoveGroupObjectIds @(
    "22222222-2222-2222-2222-222222222222"
  )
```

### 4) Set manager (optional)

```powershell
.\scripts\change\Update-M365User.ps1 `
  -UserPrincipalName "jane.doe@faithfultechinnovations.onmicrosoft.com" `
  -ManagerUpn "joerussell@faithfultechinnovations.onmicrosoft.com"
```

### 5) Automation-friendly (no prompts)

```powershell
.\scripts\change\Update-M365User.ps1 `
  -UserPrincipalName "jane.doe@faithfultechinnovations.onmicrosoft.com" `
  -Department "IT" `
  -Confirm:$false
```

---

## Expected Output (Example)

```text
UserPrincipalName : jane.doe@faithfultechinnovations.onmicrosoft.com
UserId            : 2c2c1669-9fa9-45f7-983b-1639f3604fcf
ProfileUpdated    : True
FieldsUpdated     : {department, jobTitle, usageLocation}
GroupsAdded       : {11111111-1111-1111-1111-111111111111}
GroupsRemoved     : {22222222-2222-2222-2222-222222222222}
ManagerUpdated    : False
DryRun            : False
TranscriptPath    : logs/change-jane.doe_faithfultechinnovations.onmicrosoft.com-20260113-120000.log
Timestamp         : 2026-01-13T12:00:00-06:00
```

---

## Notes / Guardrails

- **Idempotent:** safe to re-run; it only updates what you pass.
- **UPN rename:** handle separately (Exchange + identity implications).
- **Group-based licensing:** prefer adding/removing licensing groups instead of setting licenses directly.
