# Supplementary Table S1. Model parameters

Per-time-step rates are weekly. Values are from the calibrated model
(`R/calibrated_params.R`); "calibrated" indicates a value fit to the SA
trajectory, "data"/"literature" indicates a fixed input.

## Transmission and susceptibility
| Parameter | Value | Source / note |
|---|---|---|
| Per-act transmission probability | 0.0035 | **Calibrated** to SA trajectory |
| Sex acts per week, main / casual | 5 / 2 | Calibrated (within plausible range) |
| Relative infectiousness, acute / AIDS | 5× / 2× | Literature (vs chronic reference) |
| Relative infectiousness on ART, unsuppressed / suppressed | 0.30 / 0.01 | Literature (treatment-as-prevention) |
| AGYW susceptibility multiplier, 15–19 / 20–24 | 2.0 / 1.5 | Literature (elevated young-women risk) |
| PrEP efficacy (per-act acquisition reduction) | 0.95 | Literature (consistent oral/injectable PrEP) |

## Partnership network
| Parameter | Value | Source / note |
|---|---|---|
| Mean degree, main / casual | 0.50 / 0.35 | Aimee cohort (≈1.71 past-year partners) |
| Concurrency target, main / casual | 4% / 10% | Bounded by mean degree |
| Age-mixing breadth, main / casual | 8 / 9 | Set to mean AGYW partner gap ≈7.7y, 34% with men ≥30 |
| Preferred partner age gap (AGYW) | 5 years | SA age-disparate literature |
| Partnership duration, main / casual | 200 / 26 weeks | Literature |
| Sex ratio (proportion male) | 0.50 | Assumption |

## Disease progression (per week)
| Parameter | Value | Implied duration |
|---|---|---|
| Acute → chronic | 1/12 | 12-week acute stage |
| Chronic → AIDS | 1/520 | ~10-year chronic stage |
| AIDS departure (untreated) | 1/104 | ~2-year AIDS survival |
| ART progression multiplier | 0.5 | Suppressive ART halves progression |
| ART AIDS-survival multiplier | 0.1 | ART extends AIDS survival ~10× |

## Care cascade (per week, baseline)
| Parameter | Value |
|---|---|
| HIV testing/diagnosis rate | 0.01 |
| AIDS-stage diagnosis rate | 0.05 |
| Linkage to ART | 0.50 |
| ART re-initiation | 0.10 |
| Viral suppression | 0.30 |
| ART discontinuation | 0.01 |
| ART scale-up window | ramp 2004 → 2014 |

## PrEP (per week, baseline)
| Parameter | Value |
|---|---|
| Initial PrEP coverage (eligible) | 0.02 |
| PrEP initiation rate | 0.005 |
| PrEP discontinuation rate | 0.027 (≈6-month median retention; SA oral-PrEP literature) |
| PrEP indication degree threshold | 2 |

The PrEP discontinuation rate is set to reflect the documented poor continuation of
oral PrEP among South African AGYW (median retention on the order of months rather
than years). At this rate baseline PrEP coverage among AGYW remains ~3% (consistent
with South African program estimates) with rapid turnover.

## Demography and epidemic timing
| Parameter | Value |
|---|---|
| Background departure (mortality) | 0.0005 / week |
| Arrival rate | 0.0010 / week |
| Entry / exit ages | 15 / 50 years |
| Demographic burn-in | 1965–1990 (25 y, HIV-free) |
| HIV seed year / prevalence | 1990 / 0.8% |

## Intervention
| Parameter | Value(s) |
|---|---|
| Chatbot start year | 2025 |
| Reach (fraction of AGYW reached) | 0.10 / 0.30 / 0.50 |
| Causal fraction | 0.25 / 0.50 / 1.00 |
| Testing rate ratio (= 1 + (2.11−1)×fraction) | 1.28 / 1.55 / 2.11 |
| PrEP rate ratio (= 1 + (2.22−1)×fraction) | 1.31 / 1.61 / 2.22 |
| National AGYW population (scaling) | 5,071,746 (Thembisa 2022) |
| Replicates per scenario / population size | 24 / 20,000 |

## Calibration targets (Thembisa v5.0, 2022)
| Target | Value |
|---|---|
| HIV prevalence, women 15–19 / 20–24 | 5.4% / 12.4% |
| HIV prevalence, adult 15–49 | 17.6% |
| HIV incidence, women 15–24 | 0.96 / 100 PY |
| Older-men prevalence, 25–29 / 30–34 / 35–39 / 40–44 | 7.1 / 12.0 / 18.1 / 22.4% |
| Best-fit trajectory RMSE | 0.031 |

## Care-cascade validation (model vs South Africa, 2022)

The cascade was not tuned to these targets; the values below emerged from the
calibrated transmission/age structure and are reported as an out-of-sample check.

| Group | Diagnosed | On ART | Suppressed | SA reference |
|---|---|---|---|---|
| AGYW (women 15–24) | 73% | 66% | 62% | ~74% diagnosed, ~68% suppressed |
| Adults (15–49) | 89% | 81% | 78% | ~90% diagnosed, ~77% suppressed |
| Men 25–34 | 84% | 78% | 76% | ~66% suppressed |

The model reproduces the empirical AGYW cascade shortfall relative to adults
(young women more recently infected, hence less diagnosed/suppressed) without
cascade-specific parameters.
