# Methods

## Study design and overview

We developed a stochastic, individual-based dynamic network model of heterosexual
HIV transmission in South Africa to estimate the population-level impact of an AI
health companion (Aimee) on HIV incidence among adolescent girls and young women
(AGYW, women aged 15–24 years). The model was implemented in the `EpiModel`
framework (v2.6.1) in R, building on the EpiModel Gallery "HIV Transmission with
Care Cascade and PrEP" reference model, and extended with sex- and age-structured
partnership networks, an age-disparate mixing structure, age-graded female
susceptibility, and an intervention layer representing chatbot-driven changes to
HIV testing and pre-exposure prophylaxis (PrEP) uptake. The model was calibrated
to the South African HIV epidemic trajectory (1990–2022) and used to project the
number of AGYW HIV infections averted by the chatbot over 2025–2035 under a range
of reach and effect-size assumptions.

## Population and partnership network

The model simulated a closed sexually-active population aged 15–50 years.
Partnerships were represented as two concurrent dynamic networks — **main**
(longer-duration, higher per-act frequency) and **casual** (shorter-duration) —
each estimated as a separate temporal exponential-family random graph model
(TERGM) sharing the same node set. Each layer included an `edges` term, a
`concurrent` term (capturing overlapping partnerships, the structural feature
central to generalized HIV epidemics), and two structural constraints:

1. **Heterosexual mixing**, imposed via an offset `nodematch("sex")` term with
   coefficient −∞, so partnerships formed only between male and female nodes.
2. **Age-disparate mixing**, imposed via an `absdiff` term on a directional
   "preferred-partner age" (female age shifted upward by a fixed gap), so that
   AGYW preferentially partnered with older men. The mixing breadth was set so
   that AGYW partners were on average ~7.7 years older, with ~34% of AGYW
   partnerships involving men aged ≥30 years, consistent with South African
   age-disparate ("blesser") partnership data.

Mean partnership degree was informed by the Clover/Aimee cohort (mean 1.71
sexual partners in the past year). Vital dynamics comprised aging (individuals
aged one week per time step), entry of new susceptible 15-year-olds, and exit by
background mortality, AIDS mortality, and aging out of the sexually-active
population at age 50.

## HIV natural history, transmission, and care cascade

HIV progression was modelled as susceptible → acute → chronic → AIDS, with
stage-specific relative infectiousness (acute 5×, AIDS 2× the chronic reference).
Per-partnership transmission each weekly time step was a function of a per-act
transmission probability, the number of sex acts (5/week main, 2/week casual),
infector stage, and ART status (treatment-as-prevention: virally suppressed
individuals near-non-infectious). Young women carried an **age-graded elevated
per-contact susceptibility** (2.0× at ages 15–19 and 1.5× at 20–24), reflecting
documented biological vulnerability.

The care cascade comprised four states — undiagnosed, diagnosed (off ART), on ART
(not suppressed), and virally suppressed — with transitions governed by HIV
testing/diagnosis, linkage, viral suppression, and ART discontinuation rates.
Antiretroviral therapy availability was introduced as a time-varying scale-up
ramping from 0 (pre-2004) to full (2014), reproducing the South African ART
roll-out. PrEP was modelled on the susceptible side as a per-act reduction in
acquisition probability (95% efficacy), with stochastic initiation among eligible
individuals and discontinuation.

## Data sources and parameterization

| Domain | Source |
|---|---|
| Chatbot effect on HIV testing and PrEP uptake | Clover/Aimee field-study cohort (analytic N = 9,310) |
| Partnership degree | Clover/Aimee cohort (past-year partner counts) |
| HIV prevalence and incidence by age/sex, 1990–2022 | Thembisa v5.0 national model |
| Age-disparate partnership structure | South African age-mixing literature |

**Chatbot effect sizes.** From the Clover cohort, Cox proportional-hazards models
(adjusted for registration month, with same-day events excluded and outcomes
anchored at the analytic cohort) estimated that meaningful engagement (≥2 active
days vs single-day use) was associated with a hazard ratio of **2.11**
(95% CI 1.87–2.39) for HIV testing and **2.22** (1.88–2.63) for PrEP initiation.
Because these are observational associations subject to self-selection, they were
not applied as causal effects directly (see Intervention scenarios).

## Calibration

The model was calibrated using the trajectory-fitting approach standard for South
African HIV models, rather than to a single equilibrium cross-section. The
simulation clock began in 1965 with a 25-year HIV-free **demographic and network
burn-in** to allow the age structure and partnerships to reach stationarity. HIV
was then seeded in 1990 at 0.8% prevalence, and the epidemic was simulated forward
to 2022 with the time-varying ART scale-up.

The free transmission parameter (per-act transmission probability) was fit so that
the simulated **prevalence and incidence trajectories** reproduced the Thembisa
v5.0 targets — HIV prevalence among women 15–19 and 20–24 and adults 15–49, and
HIV incidence among women 15–24 — across 1990–2022. The best-fitting value
(per-act probability 0.0035) yielded a trajectory root-mean-square error of 0.031;
the calibrated model reproduced the rise, peak, and ART-era decline of the South
African epidemic (women 15–24 prevalence peaking ~15–16% around 2002–2005;
adult 15–49 peaking ~19–21%). Network degree, age gap, and young-women
susceptibility were fixed from data/literature; ART-era cascade dynamics were
calibrated jointly with transmission.

## Intervention scenarios

The Aimee chatbot was represented not mechanistically but as a perturbation of the
two behavioural parameters it affects, applied to the subset of AGYW reached, from
2025 onward. Each woman was designated an Aimee user at cohort entry with
probability equal to the scenario **reach**; while she was AGYW (15–24) and from
2025, her HIV-testing rate was multiplied by a testing rate ratio and her PrEP
initiation rate by a PrEP rate ratio (with reached AGYW also rendered
PrEP-eligible, consistent with their priority-population status).

Rate ratios were derived from the Clover hazard ratios scaled by an assumed
**causal fraction**, to address the observational nature of the effect sizes:
`rate ratio = 1 + (HR − 1) × causal fraction`. We evaluated a full factorial grid
of **reach** (10%, 30%, 50% of AGYW) × **causal fraction** (25% [conservative],
50% [central], 100% [optimistic]), giving rate ratios of 1.28–2.11 for testing and
1.31–2.22 for PrEP, plus a no-chatbot counterfactual baseline.

## Analysis

For each scenario we projected the simulation to 2035 and computed the cumulative
number of HIV infections among AGYW over the intervention window (2025–2035),
scaled to the national AGYW population (Thembisa 2022). The primary outcome was
the **number and percentage of AGYW HIV infections averted** relative to the
no-chatbot baseline. We additionally computed an efficiency measure (AGYW reached
per infection averted).

To isolate the (small) intervention effect from stochastic simulation noise, we
used a **paired design with common random numbers**: each simulation replicate
used a fixed random seed shared across all scenarios, so baseline and intervention
replicates shared an identical pre-2025 epidemic history and diverged only through
the chatbot. Correct alignment was verified by confirming that pre-2025 infection
counts were identical across scenarios within each replicate. We ran 12 replicates
per scenario at a population of 10,000 and report medians with 2.5th–97.5th
percentile simulation intervals. Scenarios were run in parallel across (scenario ×
replicate) tasks.

The model was implemented in R (`EpiModel` 2.6.1; `statnet` `ergm`/`tergm`).
Analysis code is available at <repository>.

## Ethical considerations

Only aggregate, de-identified, study-level summary statistics from the Clover
field study were used to parameterize the model; no individual-level participant
data were incorporated into or distributed with the model.

## Limitations

The model has several limitations. (i) The calibration is preliminary: a single
best-fitting parameter set was used rather than a full Bayesian (e.g. ABC)
posterior, so parameter uncertainty is not fully propagated into the projections.
(ii) The simulated epidemic's early-1990s rise is slightly slower than the
observed explosive growth, reflecting the absence of an explicit high-risk core
group. (iii) The chatbot effect sizes are observational and subject to
self-selection; we address this with the causal-fraction sensitivity range but
cannot establish causality from the cohort data. (iv) Partnership age data were
drawn from the literature rather than the study population. (v) Projections are
illustrative of relative impact under stated assumptions rather than precise
forecasts.
