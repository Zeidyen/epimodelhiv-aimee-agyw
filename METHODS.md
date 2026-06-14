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
sexual partners in the past year), with main and casual partnerships of
approximately 200- and 26-week mean duration. The model operated on a **weekly
time step** over a closed sexually-active population aged 15–50 years.

Demographic turnover comprised three processes. (i) **Entry:** each week, new
susceptible individuals entered at age 15 as a Poisson draw with mean equal to the
active population size multiplied by an arrival rate of **0.0010 per week (≈5% per
year)**, with sex assigned at a 1:1 ratio. (ii) **Mortality and exit:** all
non-AIDS individuals departed at a background rate of **0.0005 per week (≈2.6% per
year)**; AIDS-stage individuals departed at an elevated rate of **1/104 per week
(≈2-year mean survival untreated)**, reduced 10-fold (multiplier 0.1) for those on
suppressive ART, modelling extended survival on treatment. (iii) **Aging out:**
individuals deterministically left the sexually-active population at **age 50**.
Because per-capita entry slightly exceeded background exit, the population grew
modestly over time, consistent with South Africa's young, expanding demographic
structure. All individuals aged one week per time step, and the two partnership
networks and the age-disparate mixing structure were re-simulated each step to
reflect the updated ages. These demographic rates were not fit to vital statistics
but set to maintain a stable-to-growing age structure during the HIV-free burn-in.

## HIV natural history, transmission, and care cascade

HIV progression was modelled as susceptible → acute → chronic → AIDS. The acute
stage lasted a mean of 12 weeks (progression rate 1/12 per week), the chronic
stage a mean of ~10 years (1/520 per week); untreated AIDS survival averaged ~2
years (the AIDS departure rate above). Suppressive ART halved the rate of disease
progression (multiplier 0.5) and extended AIDS survival ~10-fold (multiplier 0.1).
Infectiousness was stage-specific: relative to the chronic reference, the acute
stage was **5×** and the AIDS stage **2×** as infectious; individuals on ART but
not yet suppressed had relative infectiousness 0.30, and the virally suppressed
0.01 (near-non-infectious, treatment-as-prevention). Per-partnership transmission
each weekly time step was computed from a per-act transmission probability
(calibrated to 0.0035), the number of sex acts (**5/week main, 2/week casual**),
the infector's stage and ART status, and — on the susceptible side — PrEP status
and an **age-graded elevated per-contact susceptibility** for young women (**2.0×**
at ages 15–19 and **1.5×** at 20–24), reflecting documented biological
vulnerability.

The care cascade comprised four states — undiagnosed, diagnosed (off ART), on ART
(not suppressed), and virally suppressed. Each week, undiagnosed individuals were
diagnosed at a routine HIV-testing rate of **0.01 per week** (≈41% per year; a
higher **0.05 per week** at the symptomatic AIDS stage); diagnosed individuals
linked to ART at **0.50 per week** (re-initiation after a lapse at 0.10);
ART-treated individuals achieved viral suppression at **0.30 per week**; and
treated individuals discontinued ART at **0.01 per week**. Antiretroviral therapy
availability was introduced as a time-varying scale-up: the linkage,
re-initiation, and suppression rates were multiplied by a factor rising linearly
from 0 (pre-2004) to 1 (from 2014), reproducing the South African ART roll-out.

PrEP was modelled on the susceptible side as a **95% per-act reduction** in
acquisition probability. Individuals became PrEP-indicated if they had a partnership
degree ≥ 2, an HIV-positive partner, or (for reached AGYW from 2025) were designated
priority-population eligible. Indicated susceptibles initiated PrEP at **0.005 per
week** and discontinued at **0.027 per week**. The discontinuation rate corresponds
to a **median time on PrEP of ~6 months** and was set to reflect the documented poor
continuation of oral PrEP among South African AGYW, so that baseline PrEP coverage
remained low (~3%) with rapid turnover rather than accumulating an unrealistically
protected stock. The full set of parameter values is given in Supplementary Table S1.

To check that the baseline reflected real South African treatment and care
coverage, we compared the model's emergent care cascade with national estimates.
The calibrated model reproduced the observed cascade — including the AGYW shortfall
relative to adults (model: 73% of HIV-positive AGYW diagnosed and 62% suppressed,
versus 89% and 78% for all adults; South Africa: ~74%/~68% for AGYW versus
~90%/~77% overall) — without any cascade-specific tuning, because young women are
more recently infected and so have had less time to be diagnosed and suppressed.

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

Rate ratios were derived from the Clover hazard ratios (HR 2.11 for testing, 2.22
for PrEP) scaled by an assumed **causal fraction**, to address the observational
nature of the effect sizes: `rate ratio = 1 + (HR − 1) × causal fraction`. We
evaluated a full factorial grid of **reach** (10%, 30%, 50% of AGYW) × **causal
fraction** (Table 1), plus a no-chatbot counterfactual baseline — ten scenarios in
total.

**Table 1. Intervention scenario grid.** Rate ratios applied to the HIV-testing and
PrEP-initiation rates of reached AGYW, by causal fraction; each was crossed with the
three reach levels for a 3 × 3 factorial grid plus baseline.

| Causal fraction | HIV-testing rate ratio | PrEP-initiation rate ratio |
|---|---|---|
| Conservative (25% of HR causal) | 1.28 | 1.31 |
| Central (50% of HR causal) | 1.55 | 1.61 |
| Optimistic (100% of HR causal) | 2.11 | 2.22 |
| *crossed with reach:* | 10% / 30% / 50% of AGYW | + no-chatbot baseline |

### Implementation strategies: demand generation versus persistence support

To inform how a chatbot programme should be designed, a secondary analysis
decomposed the PrEP effect into the implementation levers the chatbot could act on,
at a fixed 50% reach and central initiation effect (testing held at baseline to
isolate the PrEP pathway). We distinguished three strategies: (i) **demand
generation** — the chatbot expands PrEP eligibility among reached AGYW and raises
their initiation rate (the mechanism used in the primary analysis); (ii)
**persistence support** — the chatbot recruits no new users but reduces
discontinuation among reached AGYW already on PrEP, representing digital
adherence/retention support; and (iii) **both** combined. Because the cohort
provides a hazard ratio for PrEP *initiation* but not for *continuation*, the
persistence effect was not estimated from data but explored as a scenario range — a
20%, 40%, or 60% reduction in the weekly discontinuation rate, corresponding to a
median time on PrEP increasing from ~6 months to ~7.4, ~9.8, and ~14.8 months
respectively, within the range reported for digital adherence-support interventions
(a limitation we return to in the Discussion).

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
counts were identical across scenarios within each replicate. We ran 96 replicates
per scenario at a population of 20,000. Scenarios were run in parallel across
(scenario × replicate) tasks.

Because the intervention effect is small relative to stochastic epidemic
variability, we based inference on the **per-replicate paired difference** in
national AGYW infections (baseline minus scenario), which removes the shared
epidemic variance. For each scenario we report the **mean infections averted with a
95% confidence interval and p-value from a paired *t* test** on these differences —
the appropriate estimate of the expected (population-average) effect and its
estimation uncertainty. We additionally inspected the distribution of paired
differences across replicates; the central and optimistic scenarios at 30% and 50%
reach averted infections in the large majority of replicates.

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
