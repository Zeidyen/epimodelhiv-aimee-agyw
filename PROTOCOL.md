# Study protocol — modelled HIV impact of the Aimee chatbot among SA AGYW

> Working protocol. Sections marked **TODO** need data or decisions before coding.

## 1. Research question

Among South African AGYW (15–24), what is the population HIV-incidence impact over
5 and 10 years if an AI health companion (Aimee) increases HIV-testing frequency
and PrEP uptake by the magnitudes observed in the Clover Field Study cohort?

## 2. Model & population

- **Engine:** EpiModelHIV — **SSA heterosexual module** (dynamic ERGM/tergm
  sexual networks + stochastic agent-based epidemic).
- **Focal population:** AGYW 15–24 and their (frequently older) male partners.
- **Network structure:** retain **age-disparate partnerships** — primary driver
  of AGYW incidence. Partnership types: main / casual / one-time as supported.

## 3. How the intervention enters the model

The chatbot is represented as a perturbation of existing parameters, applied to
the share of AGYW reached by Aimee:

| Lever | EpiModelHIV parameter | Clover evidence? |
|---|---|---|
| HIV testing | testing rate / inter-test interval | yes |
| PrEP initiation | PrEP coverage / initiation prob (eligible) | yes |
| PrEP persistence | discontinuation / adherence | **TODO** — check data |

Only perturb levers the cohort can credibly inform.

## 4. Effect sizes and causal discipline

- Estimate chatbot effects on testing & PrEP from the Clover cohort.
- These are **associational** (self-selection: motivated users engage *and*
  test/PrEP regardless). Do **not** treat as causal point estimates.
- Enter as a **scenario range** of the causal fraction of the observed effect:
  - Conservative = 25%
  - Central = 50%
  - Optimistic = 100%
- This range is the primary sensitivity analysis and the main reviewer defense.

## 5. Scenario grid

`baseline` (calibrated, no chatbot) × `effect ∈ {conservative, central, optimistic}`
× `reach ∈ {10%, 30%, 50%}` of AGYW using Aimee.

Separating **effect** from **reach** distinguishes "does it work?" from
"does it scale?"

## 6. Calibration targets (SA AGYW)

| Quantity | Source |
|---|---|
| HIV prevalence & incidence by age/sex | Thembisa; HSRC SABSSM |
| ART coverage, viral suppression | UNAIDS; DHIS |
| Baseline PrEP & HIV-testing coverage | DHIS; PEPFAR |
| Partnership rates, age-mixing | SA sexual-behaviour surveys |

See [`calibration/targets.md`](calibration/targets.md).

## 7. Outcomes

- Cumulative **HIV infections averted** and **% averted** (5 / 10 yr) — headline.
- **HIV incidence-rate reduction** among AGYW.
- (Optional) **NNT** = chatbot users per infection averted; cost-effectiveness.

## 8. Analysis & uncertainty

- Stochastic ensemble (many simulations per scenario) → median + simulation
  interval.
- Sensitivity: effect-size range (§4), reach (§5), PrEP adherence, baseline
  coverage assumptions.

## 9. Limitations (state explicitly)

- Associational → causal extrapolation from observational cohort.
- SSA-module calibration to *youth specifically* is non-trivial.
- SA partnership/network data thinner than US ARTnet.
- Generalizability beyond the platform's user base.

## 10. Precedent

SA combination-prevention agent-based modelling: a 50% testing + 50% PrEP
scale-up averted ~34% of infections over 5 years (PMC4232469) — structural
template for the scenario design.
