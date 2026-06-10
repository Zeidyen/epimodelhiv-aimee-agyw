# Data needs — what we must source to calibrate

Each item: **quantity** · **units** · **source** · **model parameter it feeds**.
Priority: ⓿ have · ① critical path · ② important · ③ nice-to-have.

## A. Epidemic targets (mostly HAVE)
| # | Quantity | Value / status | Source | Feeds |
|---|---|---|---|---|
| ⓿ | HIV prevalence women 15-19 / 20-24 | 5.6% / 8.0% | SABSSM VI 2022 | calibration target |
| ⓿ | Youth incidence 15-24 | 0.39%/yr | SABSSM VI 2022 | calibration target |
| ⓿ | Cascade 95-95-95 (15+) | 90 / 91 / 94 | Thembisa v4.6 | cascade rates |
| ⓿ | VLS women 15-24 | 68.2% | SABSSM VI 2022 | cascade target |
| ① | **AGYW-specific incidence (women 15-24)** | **MISSING** | Thembisa age/sex output | the key calibration target |

## B. Partner pool — older men (the AGYW infection source) ①
| # | Quantity | Units | Source | Feeds |
|---|---|---|---|---|
| ① | HIV prevalence men **25-34 and 35-44** | % | SABSSM VI **full report** (age×sex table) | force of infection on AGYW |
| ⓿ | VLS men 25-34 | 66.3% | SABSSM VI 2022 | partner infectiousness |

## C. Sexual-network / behaviour parameters ① (THE critical path)
These define the ERGM/tergm network — none are in press releases; need behaviour data.
| # | Quantity | Units | Likely source | Feeds |
|---|---|---|---|---|
| ① | **Mean partners** (concurrent), women 15-24, **main vs casual** | # ongoing | SABSSM behaviour module; CAPRISA / HPTN 068 / Africa Centre (AHRI) cohorts | ERGM `edges` + `concurrent` per layer |
| ① | **Age gap** AGYW↔male partner: mean & SD of partner-age difference; % partnerships age-disparate (≥5y, ≥10y) | years / % | SA age-mixing studies (Maughan-Brown; Akullian phylogenetic); SABSSM | `absdiff("age")` / `nodemix("agegrp")` |
| ① | **Partnership duration**, main / casual | months | SA behaviour / relationship-duration studies | tergm dissolution (duration) |
| ② | **Coital frequency** (acts), main / casual | acts/week | SA behaviour data | `acts.main`, `acts.casual` |
| ② | **Condom use** by partnership type / age | % acts protected | SABSSM behaviour; SADHS | per-act protection |

## D. Baseline prevention, pre-chatbot ②
| # | Quantity | Units | Source | Feeds |
|---|---|---|---|---|
| ② | Baseline **HIV-testing rate** AGYW (e.g. % tested last 12 mo, or tests/yr) | rate | SADHS; DHIS; SABSSM (status-knowledge 73.1% = proxy) | baseline `test.rate` |
| ⓿ | Baseline PrEP coverage AGYW | 4% | Thembisa v4.6 | baseline `prep.init.cov` |
| ② | ART linkage / discontinuation rates | per-time | Thembisa; cascade studies | cascade module rates |

## E. Intervention effect sizes — FROM YOUR CLOVER COHORT ① (you generate these)
The model's whole input. Estimate from the Clover Field Study:
| # | Quantity | Units | Feeds |
|---|---|---|---|
| ① | Chatbot effect on **HIV-testing uptake/frequency** (with 95% CI) | RR or absolute Δ | scenario shift to `test.rate` |
| ① | Chatbot effect on **PrEP initiation** among eligible (with CI) | RR or Δ | scenario shift to `prep.start.rate` |
| ③ | Chatbot effect on **PrEP persistence** | RR or Δ | `prep.stop.rate` |
> Report **adjusted** estimates; they enter as a **causal-fraction range**
> (25/50/100%), not a point estimate (PROTOCOL §4). This is the reviewer crux.

## F. Demography ③ (largely automatable)
| # | Quantity | Source | Feeds |
|---|---|---|---|
| ③ | SA age/sex structure, non-HIV mortality, fertility | StatsSA; Thembisa; UN WPP | arrival/departure, age structure |

---
### The short version
Three documents unlock most of this:
1. **Thembisa age/sex output spreadsheets** → A(AGYW incidence), B(men prevalence), F.
2. **SABSSM VI full report** (not the press release) → B(age×sex prevalence), D(testing), some behaviour.
3. **Your Clover cohort analysis** → all of E (the intervention effect — only you have this).

The hardest gap is **C (sexual-network parameters)** — these come from specialised
SA behaviour/cohort studies (CAPRISA, AHRI, HPTN 068, age-mixing papers), not a
single national report. If the **Clover study collected partnership data**, that
could supply C directly for this population — the best possible source.
