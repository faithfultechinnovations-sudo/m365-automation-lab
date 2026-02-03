# M365 Automation Lab (Recruiter Summary)

This repository is a PowerShell automation portfolio that models real Microsoft 365 / Entra ID admin work.

## What it demonstrates
- Identity lifecycle automation (onboarding → change → suspension → offboarding → recovery)
- Microsoft Graph usage patterns with guardrails
- Operational discipline: transcripts, run summaries, and runbooks
- Review-friendly structure and documentation

## Why it’s valuable
It shows how I design admin automation to be:
- **Safe** (tenant confirmation to prevent wrong-tenant runs)
- **Auditable** (transcripts + structured output)
- **Reusable** (shared module used across scripts)
- **Maintainable** (clear lifecycle folders + runbooks)

## What to look at (in order)
1. `docs/reviewer-guide.md`
2. `modules/M365Automation.Common/` (shared safety + logging functions)
3. `scripts/onboarding/New-M365User.ps1`
4. `scripts/change/Update-M365User.ps1`
5. `runbooks/onboarding/runbook.md`

## Notes
- `logs/` is intentionally gitignored (local run artifacts)
- Scripts are written for a lab/portfolio environment and should be reviewed before production use
