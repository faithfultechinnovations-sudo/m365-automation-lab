USER ONBOARDING RUNBOOK

PURPOSE
Safely onboard a Microsoft 365 user using Microsoft Graph with secure, repeatable, and auditable automation.

This runbook creates a new Entra ID user, applies required attributes, and optionally assigns group memberships for license and access management.

Designed for:
- Security-first onboarding
- Least-privilege Microsoft Graph access
- Idempotent execution (safe re-runs)
- Operational and audit clarity


WHAT THIS RUNBOOK DOES
- Creates a new Entra ID user
- Sets required identity attributes (UPN, name, usage location)
- Forces password change at first sign-in (default)
- Optionally adds the user to groups (recommended for licensing)
- Writes a timestamped transcript for auditing


WHAT THIS RUNBOOK DOES NOT DO
- Assign licenses directly (use group-based licensing)
- Configure mailbox, OneDrive, or Teams settings
- Manage Intune devices or compliance policies

These actions are intentionally handled in later onboarding phases.


SCRIPT
Primary script:
scripts/onboarding/New-M365User.ps1


PREREQUISITES
- PowerShell 7 recommended (Windows PowerShell 5.1 supported)
- Microsoft Graph PowerShell SDK installed

Install command:
Install-Module Microsoft.Graph -Scope CurrentUser


PERMISSIONS REQUIRED (MICROSOFT GRAPH)
The operator account (the account used during Connect-MgGraph) must be able to create users and manage group membership.

Delegated Graph scopes required:
- User.ReadWrite.All
- Group.ReadWrite.All

In many tenants, Global Administrator (or equivalent) is required.


FAILURE MODES & TROUBLESHOOTING

A) User already exists
Symptom: Script reports user exists and skips creation
Cause: UPN already exists in Entra ID
Check:
Get-MgUser -Filter "userPrincipalName eq 'jane.doe@faithfultechinnovations.onmicrosoft.com'"

B) 403 Forbidden
Cause: Missing Graph scopes or insufficient role
Fix:
Disconnect-MgGraph
Connect-MgGraph -Scopes "User.ReadWrite.All","Group.ReadWrite.All" -TenantId "faithfultechinnovations.onmicrosoft.com"

C) 405 MethodNotAllowed
Cause: Wrong tenant or stale auth context
Fix:
Get-MgContext | Format-List
Then reconnect explicitly.

D) Login window hidden (WAM)
Fix: Alt-Tab or minimize windows to locate the sign-in prompt.

E) Group add fails
Fix:
Get-MgGroup -GroupId "<group-guid>"
Confirm the group exists and you have permission.


EXAMPLE USAGE
Run from the repository root (folder containing README.md)

1) Dry run (no changes)
New-M365User.ps1 with -DryRun

2) Live run (creates user)
New-M365User.ps1 without -DryRun

3) Group-based licensing
Provide -GroupObjectIds with security group GUIDs

4) Automation-friendly
Use -Confirm:$false


EXPECTED OUTPUT (EXAMPLE)
UserPrincipalName : jane.doe@faithfultechinnovations.onmicrosoft.com
DisplayName       : Jane Doe
UserId            : 2c2c1669-9fa9-45f7-983b-1639f3604fcf
UsageLocation     : US
MailNickname      : jane.doe
GroupsAdded       : <group-guid>
TempPassword      : ********
DryRun            : False
TranscriptPath    : logs/onboarding-jane.doe_faithfultechinnovations.onmicrosoft.com.log
Timestamp         : 2026-01-13T10:25:22-06:00
