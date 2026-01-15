# Microsoft 365 Automation Lab

## Overview
This repository demonstrates **enterprise-grade Microsoft 365 administration using automation-first practices**.  
It is designed to reflect how M365 is managed in real environments: securely, repeatably, and at scale — without relying on manual portal clicks.

The focus is on **identity, security, governance, and operational automation** using PowerShell and Microsoft Graph.

---

## Goals of This Repository
- Demonstrate real-world Microsoft 365 administration skills
- Replace manual tasks with auditable automation
- Treat configuration and security as code
- Model how M365 is operated in enterprise and MSP environments

This is not a collection of scripts — it is a **structured automation lab** with documentation, runbooks, and intentional design.

---

## Core Capabilities
- Automated user onboarding and offboarding
- Group-based licensing and role assignment
- Conditional Access policy deployment as code
- Security and audit log automation
- Power Platform governance and inventory
- Multi-tenant–ready configuration patterns
- Operational runbooks and documentation

---

## Technologies Used
- PowerShell 7
- Microsoft Graph API
- Entra ID (Azure AD)
- Exchange Online
- Microsoft Teams
- SharePoint / OneDrive
- Power Platform Admin APIs

---

## Repository Structure
m365-automation-lab/
├─ .gitignore
├─ LICENSE
├─ README.md
├─ scripts/
  ├─ onboarding
├─ modules/
├─ runbooks/
└─ docs/

## Implemented Automations
- Automated Microsoft 365 user onboarding
  - Identity creation via Microsoft Graph
  - Group-based licensing
  - Security-first defaults
  - Logged and idempotent execution
  - Additional lifecycle phases are documented and implemented incrementally as part of a defined identity lifecycle

Successfully executed against a live Microsoft Entra ID tenant using delegated Microsoft Graph permissions

User creation verified in Microsoft 365 admin center

---

## Identity Lifecycle Model (Design Intent)

This repository models Microsoft 365 identity management as a **deliberate lifecycle**, not ad-hoc scripts.

Each phase is isolated, auditable, and reversible where appropriate — mirroring how mature enterprises operate identity systems.

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
→ Designed for HR or security holds

**4. Offboarding – Phase 2 (Decommissioning)**  
→ Remove licenses  
→ Apply data protection / retention  
→ Prepare for deletion or archival  
→ Performed only after business confirmation

**5. Restore (Human Error Recovery)**  
→ Re-enable suspended accounts  
→ Restore access safely  
→ Undo suspension without rebuilding identity

**6. Change (Ongoing Identity Maintenance)**  
→ Name changes (e.g., marriage/divorce)  
→ Title / department updates  
→ Group and license adjustments  
→ Models real-world identity drift

---

This lifecycle-first design ensures:
- Clear separation of responsibilities
- Safer automation with rollback paths
- Strong audit and compliance posture
- Reduced blast radius from human error
