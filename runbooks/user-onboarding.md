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

---

## Permissions Required (Microsoft Graph)

The operator account (the account you sign into when `Connect-MgGraph` prompts you) must be able to create users and manage group membership in the tenant.

**Delegated Graph scopes requested by the script:**
- `User.ReadWrite.All`
- `Group.ReadWrite.All`

> In many tenants, **being Global Administrator** (or another sufficiently privileged role) is required to consent to these scopes and perform user creation.

---

## Failure Modes & Troubleshooting

### A) “User already exists” (idempotency guard)
**Symptom:** The script reports the user exists and skips creation.  
**Cause:** The UPN is already present in Entra ID.  
**Fix:** Confirm the intended UPN, or choose a new UPN. You can verify:
```powershell
Get-MgUser -Filter "userPrincipalName eq 'jane.doe@faithfultechinnovations.onmicrosoft.com'"

B) “403 Forbidden” when running Graph commands

Symptom: Get-MgUser or New-MgUser returns 403 (Forbidden).
Cause: Missing Graph scopes, no admin consent, or insufficient Entra role permissions.
Fix:

Reconnect with the required scopes:
```powershell Disconnect-MgGraph
Connect-MgGraph -Scopes "User.ReadWrite.All","Group.ReadWrite.All" -TenantId "faithfultechinnovations.onmicrosoft.com"
```
2) Ensure the signed-in operator is in an appropriate role (e.g., Global Administrator).

C) “405 MethodNotAllowed” when creating users

Symptom: New-MgUser returns 405 (MethodNotAllowed).
Cause (common):

You authenticated against the wrong tenant

The token/context is invalid or stale

The request was made without proper authorization context
Fix:
```powershell Get-MgContext | Format-List
```
2) Disconnect/reconnect explicitly to the correct tenant:
```powershell Disconnect-MgGraph
Connect-MgGraph -Scopes "User.ReadWrite.All","Group.ReadWrite.All" -TenantId "faithfultechinnovations.onmicrosoft.com"
```
3) Re-run the script.

D) Interactive login window “hidden” / doesn’t appear

Symptom: You see a warning about WAM and don’t see the login prompt.
Cause: The browser sign-in window may open behind other windows.
Fix: Alt-Tab to find the sign-in window, or temporarily minimize all windows.

E) Group add fails (invalid group id / not allowed)

Symptom: Adding to group errors out.
Cause: Bad GroupObjectId, not a security group, or insufficient group privileges.
Fix:

Verify the group exists:
```powershell Get-MgGroup -GroupId "11111111-1111-1111-1111-111111111111"
```
Confirm you have permission to manage membership for that group.

F) Temp password shown when you don’t want it

Symptom: Script prints or returns the temporary password.
Cause: Output settings (or RevealTempPassword) allow it.
Fix: Keep RevealTempPassword off for normal runs; only enable when explicitly needed.
Confirm your Graph context:

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
