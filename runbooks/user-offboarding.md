# User Offboarding Runbook

## Purpose

Safely offboard a Microsoft 365 user using Microsoft Graph with **repeatable, auditable, and idempotent** steps.

This runbook immediately disables user access, revokes active sessions, and optionally removes group memberships — **without deleting the user object**.

Designed for:
- Security-first offboarding
- Least-privilege Microsoft Graph access
- Safe re-execution (idempotent)
- Audit and compliance validation

---

## What This Runbook Does

✔ Disables the Entra ID user account  
✔ Revokes all active sign-in sessions  
✔ Optionally removes group memberships  
✔ Writes a timestamped transcript for auditing  

## What This Runbook Does NOT Do

✖ Delete the user object  
✖ Remove licenses directly  
✖ Modify mailbox or OneDrive data  
✖ Touch Intune-managed devices  

> These actions are intentionally handled in later offboarding phases.

---

## Script

Primary script:

- `scripts/offboarding/Disable-M365User.ps1`

---

## Example Usage

> Run from the repository root (the folder containing `README.md`).

---

### 1) Dry run (no changes)

```powershell
.\scripts\offboarding\Disable-M365User.ps1 `
  -UserPrincipalName "jane.doe@faithfultechinnovations.onmicrosoft.com" `
  -DryRun
'''

### 2) Live run (makes changes)
```powershell
   .\scripts\offboarding\Disable-M365User.ps1 `
 -UserPrincipalName "jane.doe@faithfultechinnovations.onmicrosoft.com"
'''

### 3) Automation-friendly (no prompts)

'''powershell
   .\scripts\offboarding\Disable-M365User.ps1 `
  -UserPrincipalName "jane.doe@faithfultechinnovations.onmicrosoft.com" `
  -Confirm:$false
'''

### Expected Output (Example)

UserPrincipalName : jane.doe@faithfultechinnovations.onmicrosoft.com
UserId            : 2c2c1669-9fa9-45f7-983b-1639f3604fcf
AccountEnabled    : False
SessionsRevoked   : True
GroupsRemoved     : 0
DryRun            : True
TranscriptPath    : logs/offboarding-jane.doe_faithfultechinnovations.onmicrosoft.com-20260113-110157.log
Timestamp         : 2026-01-13T11:02:27-06:00
