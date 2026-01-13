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
