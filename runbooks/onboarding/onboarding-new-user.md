Purpose

This runbook documents the safe, repeatable process for onboarding a new Microsoft 365 user using automation instead of manual portal clicks.

The goal is consistency, auditability, and least privilege — not speed at the cost of control.


What Problem This Solves

Manual M365 onboarding often results in:

Inconsistent user attributes
Over-permissioned accounts
Licensing errors
No audit trail
Fragile “tribal knowledge” processes


This runbook ensures:

Idempotent user creation
Group-driven access and licensing
Logged, reviewable execution
Clear failure boundaries


Preconditions

Before running the script:

Operator has delegated Graph permissions:
	User.ReadWrite.All
	Group.ReadWrite.All
	Directory.Read.All
Correct tenant context is confirmed
Required groups already exist
Licensing is assigned only via groups
PowerShell 7+ installed


Execution Flow

1. Operator provides required identity inputs (UPN, display name, etc.)
2. Script validates Graph connection and tenant
3. Script checks if user already exists (idempotency guard)
4. If user exists → exits safely
5. If user does not exist:
	User object is created
	Attributes are applied
	User is added to predefined groups
6. Licensing flows automatically via group membership
7. Transcript log is written


What This Script Intentionally Does NOT Do

❌ Assign licenses directly
❌ Rename UPNs or mail identities
❌ Modify tenant-wide settings
❌ Bypass approval workflows
❌ Store secrets or credentials

These exclusions are deliberate safety boundaries.


Failure Modes & Recovery
Scenario		Behavior
Graph connection fails	Script exits, no changes
User already exists	Script exits safely
Group add fails		User remains unlicensed
Partial execution	Logged for review


Rollback is achieved by:
	Removing user from groups
	Deleting user if required (manual confirmation)


Audit & Logging
	PowerShell transcript enabled
	Structured console output
	Logs stored locally under /logs
	Designed for SOC / change review


Definition of Done
	User exists in Entra ID
	User is in correct security groups
	License applied via group
	Execution log exists
	No manual portal changes required