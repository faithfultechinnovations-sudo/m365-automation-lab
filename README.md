# Microsoft 365 Automation Portfolio

## Overview
This repository demonstrates **real-world, enterprise-grade Microsoft 365 administration through automation-first practices** — not one-off scripts and not portal-driven click paths.

It reflects how I design, document, and operate **production-safe identity workflows** using:
- PowerShell (PowerShell 7)
- Microsoft Graph API
- Microsoft Entra ID (Azure AD)

The goal is to show *how I think as an administrator*: prioritizing safety, repeatability, and auditability over speed or convenience.

---

## Design Philosophy

- **Automation first, portal last**
- **Least privilege over convenience**
- **Idempotency over speed**
- **Groups as the control plane**
- **Logs over assumptions**

Every script in this repository is written as if it will be:
- Re-run
- Reviewed
- Audited
- Handed to another administrator

This is not a script dump — it is an **intentional automation lab**.

---

## What’s Included

### User Onboarding
- **New-M365User.ps1**
  - Idempotent user creation via Microsoft Graph
  - Security-first defaults
  - Group-based access and licensing
  - Structured execution logging

### User Updates (Day-2 Operations)
- **Update-M365User.ps1**
  - Safe, scoped identity changes
  - No destructive overwrites
  - Optional group and access management
  - Designed for ongoing identity maintenance

### Runbooks
- Human-readable operational documentation
- Clear boundaries, assumptions, and failure modes
- Designed for team and handoff scenarios

---

## Why DryRun Is Trustworthy

The `-DryRun` flag is not a mock or stub — it executes the **full control flow** of the process while explicitly preventing write operations.

When `-DryRun` is enabled:

- All input validation, tenant verification, and guardrails execute normally
- Microsoft Graph request payloads are fully constructed and logged
- No create, update, or membership changes are sent to Microsoft 365
- Secrets (temporary passwords) are redacted before output
- Transcripts and structured run summaries are still generated

DryRun failures should be treated as real failures and resolved before running without `-DryRun`.

---

## Identity Lifecycle Model (Design Intent)

This repository models Microsoft 365 identity management as a **deliberate lifecycle**, not ad-hoc automation.

Each phase is isolated, auditable, and reversible where appropriate — mirroring how mature enterprises and MSPs operate identity systems.

### Lifecycle Phases

1. **Onboarding – Phase 1 (Identity Creation)**
   - Create the Entra ID user object only
   - No licenses or mailbox assumptions
   - Safe to re-run (idempotent)

2. **Onboarding – Phase 2 (Access & Readiness)**
   - Assign licenses via group membership
   - Prepare mailbox and service access
   - Apply role and access groups

3. **Change (Ongoing Maintenance)**
   - Name and profile updates
   - Group and license adjustments
   - Models real-world identity drift

4. **Suspension (Non-Destructive)**
   - Disable the user account
   - Revoke active sign-in sessions
   - Preserve licenses and data

5. **Offboarding – Decommissioning**
   - Remove licenses
   - Apply data protection and retention
   - Prepare for deletion or archival

6. **Restore (Human Error Recovery)**
   - Re-enable suspended accounts
   - Restore access safely without rebuilding identity

---

## How to Review This Repository (Hiring Managers)

If you are reviewing this repository as part of an interview or technical evaluation, here is the recommended path:

1. **Start with this README**  
   Understand the design philosophy and lifecycle model.

2. **Review `scripts/onboarding/New-M365User.ps1`**  
   Focus on idempotency, permission scope discipline, and logging — not just functionality.

3. **Review `scripts/updates/Update-M365User.ps1`**  
   Demonstrates safe day-2 operations and change control thinking.

4. **Scan the `runbooks/` directory**  
   Shows how automation is operationalized and handed off in team environments.

This repository is evaluated best by *how risk is reduced*, not by script count.

---

## Repository Structure

m365-automation-portfolio/
├─ .gitignore
├─ LICENSE
├─ README.md
├─ scripts/
│ ├─ onboarding/
│ ├─ updates/
├─ modules/
├─ runbooks/
└─ docs/

---

## What This Repository Is Not

- A bulk-user import tool
- A licensing click-replacement
- A “run everything as Global Admin” shortcut
- A demo without guardrails

---

## Roadmap

- Automated offboarding workflows
- License drift detection
- Access review and reporting
- Change and audit event correlation

---

Successfully executed against a live Microsoft Entra ID tenant using delegated Microsoft Graph permissions.
