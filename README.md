Microsoft 365 Automation Portfolio
Overview

This repository demonstrates real‑world, enterprise‑grade Microsoft 365 administration through automation‑first practices — not one‑off scripts and not portal‑driven click paths.

It reflects how I design, document, and operate production‑safe identity workflows using:

PowerShell (PowerShell 7)

Microsoft Graph API

Microsoft Entra ID (Azure AD)

The goal is to show how I think as an administrator: prioritizing safety, repeatability, and auditability over speed or convenience.

Design Philosophy

Automation first, portal last

Least privilege over convenience

Idempotency over speed

Groups as the control plane

Logs over assumptions

Every script in this repository is written as if it will be:

Re‑run

Reviewed

Audited

Handed to another administrator

This is not a script dump — it is an intentional automation lab.

What’s Included
User Onboarding

New-M365User.ps1

Idempotent user creation via Microsoft Graph

Security‑first defaults

Group‑based access and licensing

Structured execution logging

User Updates (Day‑2 Operations)

Update-M365User.ps1

Safe, scoped identity changes

No destructive overwrites

Optional group and access management

Designed for ongoing identity maintenance

Runbooks

Human‑readable operational documentation

Clear boundaries, assumptions, and failure modes

Designed for team and handoff scenarios

Identity Lifecycle Model (Design Intent)

This repository models Microsoft 365 identity management as a deliberate lifecycle, not ad‑hoc automation.

Each phase is isolated, auditable, and reversible where appropriate — mirroring how mature enterprises operate identity systems.

Lifecycle Phases

1. Onboarding – Phase 1 (Identity Creation)
→ Create the Entra ID user object only
→ No licenses, no mailbox assumptions
→ Safe to re‑run (idempotent)

2. Onboarding – Phase 2 (Access & Readiness)
→ Assign licenses via group membership
→ Prepare mailbox and service access
→ Apply role and access groups

3. Suspension (Non‑Destructive)
→ Disable the user account
→ Revoke active sign‑in sessions
→ Preserve licenses and data

4. Offboarding – Decommissioning
→ Remove licenses
→ Apply data protection and retention
→ Prepare for deletion or archival

5. Restore (Human Error Recovery)
→ Re‑enable suspended accounts
→ Restore access safely without rebuilding identity

6. Change (Ongoing Maintenance)
→ Name and profile updates
→ Group and license adjustments
→ Models real‑world identity drift

Repository Structure
m365-automation-portfolio/
├─ .gitignore
├─ LICENSE
├─ README.md
├─ scripts/
│  ├─ onboarding/
│  ├─ updates/
├─ modules/
├─ runbooks/
└─ docs/
What This Repository Is Not

A bulk‑user import tool

A licensing click‑replacement

A “run everything as Global Admin” shortcut

A demo without guardrails

Why This Matters

Most Microsoft 365 identity failures aren’t caused by lack of features —
they’re caused by unclear process, unsafe defaults, and undocumented change.

This repository demonstrates how I:

Reduce risk before scale

Treat identity and security as code

Design automation that survives audits and handoffs

Roadmap

Automated offboarding workflows

License drift detection

Access review and reporting

Change and audit event correlation

Successfully executed against a live Microsoft Entra ID tenant using delegated Microsoft Graph permissions.
