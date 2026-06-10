# data/

## What belongs here
- **Aggregate, non-identifiable inputs only**: effect-size summaries from the
  Clover cohort analysis, public calibration targets, and parameter tables.

## What must NEVER be committed
- Patient-level or de-identified individual records from the Clover Field Study.
- Any line-list, message logs, or per-user data.

Individual-level data files are gitignored (`*.csv`, `*.rds`, `*.dta`, `*.sav`,
`data/raw/`). Keep raw inputs outside the repo or in `data/raw/` (ignored).

## Public data sources
- **Thembisa** — SA national HIV model outputs (prevalence/incidence by age/sex)
- **HSRC SABSSM** — South African National HIV survey
- **UNAIDS / DHIS** — ART coverage, viral suppression, PrEP, testing
- **SA sexual-behaviour surveys** — partnership rates, age-mixing
