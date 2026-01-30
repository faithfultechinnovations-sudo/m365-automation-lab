# Microsoft 365 Automation Portfolio

## Overview
This repository demonstrates **real‑world, enterprise‑grade Microsoft 365 administration through automation‑first practices** — not one‑off scripts and not portal‑driven click paths.

It reflects how I design, document, and operate **production‑safe identity workflows** using:
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
- Re‑run
- Reviewed
- Audited
- Handed to another administrator

This is not a script dump — it is an **intentional automation lab**.

---

## What’s Included

### User Onboarding
- **New-M365User.ps1**
  - Idempotent user creation via Microsoft Graph
  - Security‑first defaults
  - Group‑based access and licensing
  - Structured execution logging

### User Updates (Day‑2 Operations)
- **Update-M365User.ps1**
  - Safe, scoped identity changes
  - No destructive overwrites
  - Optional group and access management
  - Designed for ongoing identity maintenance

### Runbooks
- Human‑readable operational documentation
- Clear boundaries, assumptions, and failure modes
- Designed for team and handoff scenarios

---

## Identity Lifecycle Model (Design Intent)

This repository models Microsoft 365 identity management as a **deliberate lifecycle**, not ad-hoc automation.

Each phase is isolated, auditable, and reversible where appropriate — mirroring how mature enterprises and MSPs operate identity systems.

### Identity Lifecycle Diagram

> **Rendered diagram (PNG/SVG) will be added in a future iteration.**  
> The ASCII diagram below is intentionally kept as a fallback for readability in GitHub, terminals, and code reviews.

<!-- TODO: Add rendered diagram at docs/identity-lifecycle.png -->

### ASCII Fallback Diagram

```
┌────────────┐
│  Request   │   HR / Ticket / Client Intake
└─────┬──────┘
      │
      ▼
┌────────────┐
│ Onboarding │  Phase 1 – Identity Creation
│  (Create)  │  • Entra ID user only
│            │  • No licenses
│            │  • Idempotent
└─────┬──────┘
      │
      ▼
┌────────────┐
│  Access &  │  Phase 2 – Readiness
│  Licensing │  • Group-based licensing
│            │  • Role & access groups
└─────┬──────┘
      │
      ▼
┌────────────┐
│   Change   │  Ongoing Maintenance
│            │  • Name / role updates
│            │  • License & group drift
└─────┬──────┘
      │
      ▼
┌────────────┐
│ Suspension │  Non-Destructive Hold
│            │  • Disable sign-in
│            │  • Preserve data
└─────┬──────┘
      │
      ▼
┌────────────┐
│ Offboarding│  Decommissioning
│            │  • Remove licenses
│            │  • Retention / archive
└─────┬──────┘
      │
      ▼
┌────────────┐
│  Restore   │  Human Error Recovery
│            │  • Re-enable safely
└────────────┘
```

This lifecycle-first approach ensures:
- Clear separation of responsibilities
- Safer automation with rollback paths
- Strong audit and compliance posture
- Reduced blast radius from human error

### Lifecycle Phases

**1. Onboarding – Phase 1 (Identity Creation)**  
→ Create the Entra ID user object only  
→ No licenses, no mailbox assumptions  
→ Safe to re-run (idempotent)

**2. Onboarding – Phase 2 (Access & Readiness)**  
→ Assign licenses via group membership  
→ Prepare mailbox and service access  
→ Apply role and access groups

**3. Suspension (Non-Destructive)**  
→ Disable the user account  
→ Revoke active sign-in sessions  
→ Preserve licenses and data

**4. Offboarding – Decommissioning**  
→ Remove licenses  
→ Apply data protection and retention  
→ Prepare for deletion or archival

**5. Restore (Human Error Recovery)**  
→ Re-enable suspended accounts  
→ Restore access safely without rebuilding identity

**6. Change (Ongoing Maintenance)**  
→ Name and profile updates  
→ Group and license adjustments  
→ Models real-world identity drift

---

## How to Review This Repository (Hiring Managers)

If you are reviewing this repository as part of an interview or technical evaluation, here is the recommended path:

1. **Start with this README**  
   Understand the design philosophy and identity lifecycle model.

2. **Review `scripts/onboarding/New-M365User.ps1`**  
   Focus on idempotency, permission scope discipline, and logging — not just functionality.

3. **Review `scripts/updates/Update-M365User.ps1`**  
   This demonstrates safe day-2 operations and change control thinking.

4. **Scan the `runbooks/` directory**  
   These documents show how automation is operationalized and handed off in team environments.

This repository is evaluated best by *how risk is reduced*, not by script count.

---

## Repository Structure
```
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
```

---

## What This Repository Is Not

- A bulk‑user import tool
- A licensing click‑replacement
- A “run everything as Global Admin” shortcut
- A demo without guardrails

---

## Target Environments & Tone

This repository is intentionally written to translate cleanly between **internal IT teams** and **MSP / consulting environments**.

### MSP / Consulting Context
- Multi-tenant–ready patterns
- Clear phase boundaries suitable for ticket-driven work
- Idempotent scripts safe for re-execution across clients
- Runbooks designed for junior-to-senior handoff
- Reduced risk when operating under limited delegated permissions

### Internal IT Context
- Models long-lived identity ownership
- Emphasizes auditability and change control
- Supports HR-driven lifecycle events
- Designed to survive admin turnover and security reviews

The automation patterns remain the same — only the *operational framing* changes.

---

## Why This Matters

Most Microsoft 365 identity failures aren’t caused by lack of features —  
they’re caused by **unclear process, unsafe defaults, and undocumented change**.

This repository demonstrates how I:
- Reduce risk before scale
- Treat identity and security as code
- Design automation that survives audits and handoffs

---

## Roadmap

- Automated offboarding workflows
- License drift detection
- Access review and reporting
- Change and audit event correlation

---

Successfully executed against a live Microsoft Entra ID tenant using delegated Microsoft Graph permissions.

