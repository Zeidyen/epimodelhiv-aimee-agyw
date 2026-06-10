# Engineering findings — EpiModelHIV heterosexual module

Status of the SSA **heterosexual** module in `EpiModelHIV 1.5.0`, discovered while
wiring up the chatbot intervention. These shape the project plan and belong in
the manuscript's methods/limitations.

## 1. The het module has neither of our intervention levers
- **No PrEP.** Only `prep_msm` exists; there is no `prep_het` and `param_het`
  has no PrEP parameters. The MSM module has full PrEP; the het module has none.
- **No testing-rate diagnosis.** `dx_het` diagnoses **only** when CD4 falls to
  the treatment-eligibility threshold (symptomatic presentation). There is no
  HIV-testing-rate parameter and no `hivtest_het`.

The het model is the original ~2014 sub-Saharan treatment-cascade model — it
predates both routine HIV-testing campaigns and PrEP.

## 2. `param_het` is broken in this build
Its body contains a stub: `ltGhana <- 1`, then
`ds.rates <- ltGhana[ltGhana$year == 2011, ]` — which errors because the life
table was reduced to the number `1`. It also references `trans.rate`,
`dx.prob.feml`, `dx.prob.male` that are not in its formals. **A vanilla het
baseline will not run** without replacing this constructor.

## 3. EpiModelHIV 1.5.0 is pinned to a 2018-era EpiModel
`DESCRIPTION` declares `EpiModel (>= 1.7.0)`; the package SHA is from ~2018–2019.
The het modules use the **old list-based `dat$attr$` API** and an old control
class. Current **EpiModel 2.6.1** (post-2.x rewrite: `netsim_dat`,
`get_attr`/`set_attr`, new control system) rejects it:
`netsim()` fails with *"no applicable method for 'as.control.list' applied to
control.net"*. So the het model needs the **old engine** (≈ EpiModel 1.8.0) to
run at all.

## What we built anyway (works on the old API)
Because our extension modules are written against the same old `dat$attr$` API,
they slot into a pinned old-engine setup:
- `R/modules/dx_het_test.R` — testing-rate diagnosis (lever 1)
- `R/modules/prep_het.R` — PrEP initiation/discontinuation/adherence (lever 2)
- `R/modules/trans_het_prep.R` — transmission with PrEP protection on susceptibles
- `R/modules/param_control_het_prep.R` — working param constructor (repairs the
  stubbed life table) + control wrapper that wires in the three modules
- `R/01b_smoke_test.R` — plumbing test (network fit succeeds; `netsim` blocked
  only by the engine-version mismatch above)

## The decision this forces
To make the extension run we must either:
- **(A) Pin the old engine** — project-local `renv` with EpiModel ≈ 1.8.0. The
  extension then runs, but the whole study sits on a 2018-era **abandoned,
  unmaintained** stack (fragile; little community support).
- **(B) Modern maintained tool** — the current EpiModel HIV template (new
  architecture) or **EMOD-HIV** (the field standard for SA AGYW PrEP modelling).
  More upfront switch cost, but a maintained, PrEP-native foundation.
