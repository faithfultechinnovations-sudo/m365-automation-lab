Microsoft 365 Automation Portfolio

This repository demonstrates real-world Microsoft 365 administration through automation, not one-off scripts.

It reflects how I design, document, and operate production-safe identity workflows using:
	PowerShell
	Microsoft Graph
	Entra ID best practices


Design Philosophy
	Automation first, portal last
	Least privilege over convenience
	Idempotency over speed
	Groups as the control plane
	Logs over assumptions
Every script here is written as if it will be:
	Re-run
	Reviewed
	Audited
	Handed to another admin


What’s Included
User Onboarding
	New-M365User.ps1
	Idempotent user creation
	Group-based access and licensing
	Full execution logging
User Updates
	Update-M365User.ps1
	Safe, scoped day-2 changes
	No destructive overwrites
	Optional group management


Runbooks
	Human-readable operational documentation
	Clear boundaries and failure modes
	Designed for team environments


What This Repo Is Not
	A bulk-user import tool
	A licensing click-replacement
	A “run as Global Admin” shortcut
	A demo without guardrails


Why This Matters
Most identity issues aren’t caused by lack of tools —
they’re caused by unclear process and unsafe defaults.

This repo demonstrates how I reduce risk before scale.


Roadmap
	Automated offboarding
	License drift detection
	Access review reporting
	Change auditing