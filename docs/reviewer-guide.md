# Reviewer Guide (10 minutes)

## 1) What this repo is
A PowerShell automation lab that models real Microsoft 365 / Entra ID admin workflows:
- Onboarding
- Change (day-2 updates)
- Suspension
- Offboarding
- Recovery

## 2) Where to start
1. `README.md` (overview + structure)
2. `scripts/onboarding/README.md` (how scripts are run)
3. `runbooks/onboarding/runbook.md` (human workflow)

## 3) Safety / guardrails
- Scripts include tenant-context confirmation (prevents “wrong tenant” runs).
- `-WhatIf` supported where applicable.
- Transcripts + summaries written to `logs/` (gitignored).

## 4) Quick demo (safe)
Run a script with WhatIf:
```powershell
pwsh -File .\scripts\onboarding\New-M365User.ps1 -UserPrincipalName "test@contoso.com" -WhatIf
