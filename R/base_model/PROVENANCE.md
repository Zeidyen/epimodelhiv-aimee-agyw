# Base model provenance

`model.R` and `module-fx.R` are vendored from the **EpiModel Gallery**, example
*"HIV Transmission with Care Cascade and PrEP"*:
https://github.com/EpiModel/EpiModel-Gallery (examples/hiv).

- **License:** MIT (© Statnet) — compatible with this repository's MIT license.
- **Engine:** runs on current **EpiModel 2.6.x** (verified locally on 2.6.1).
- **Why this base:** it already provides, on a *maintained* engine, the two things
  the EpiModelHIV 1.5.0 heterosexual module lacked (see ../../FINDINGS.md):
  a **care cascade** (testing → diagnosis → ART → suppression) and **PrEP**
  (initiation/discontinuation, susceptibility-side protection), plus an
  infections-averted scenario comparison.

## What it provides out of the box
- Two-layer **main + casual** partnership network (TERGM) with a `concurrent`
  term — designed for *generalized* (not MSM-specific) HIV spread.
- Four-state cascade: undiagnosed → diagnosed → on ART → virally suppressed.
- PrEP with efficacy, eligibility (degree/partner-status), start/stop rates.
- Modules (in `module-fx.R`): `progress`, `cascade`, `prep`, `infect`,
  `afunc`/`dfunc` (arrivals/departures).
- Chatbot levers map directly onto existing params:
  - **Testing** → `test.rate` (+ `linkage.rate`, `suppression.rate`)
  - **PrEP** → `prep.start.rate` / `prep.init.cov`

## What we must change for the SA AGYW study
See `ADAPTATION.md`. In short: add **sex + age** structure and make
partnerships **heterosexual + age-disparate**, then calibrate to SA targets
(`../../calibration/targets.md`).

This base is unmodified from upstream so it can be re-synced; all study-specific
changes go in sibling files, not by editing these two directly.
