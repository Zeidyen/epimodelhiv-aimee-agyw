# Calibration targets — SA AGYW HIV epidemic

The baseline (no-chatbot) model must reproduce these before any intervention is
applied. Primary sources: **SABSSM VI** (HSRC national survey, fieldwork 2022,
released Nov 2023) and **Thembisa v4.6** (2023). All values are **national**;
if the model is targeted to the Clover study's specific provinces, prefer
province-stratified values where available.

## A. Firm targets (cited)

| Target | Population | Value | Source |
|---|---|---|---|
| HIV prevalence | Women 15–19 | **5.6%** | SABSSM VI 2022 |
| HIV prevalence | Women 20–24 | **8.0%** | SABSSM VI 2022 |
| HIV prevalence | Men 15–19 | **3.0%** | SABSSM VI 2022 |
| HIV prevalence | Men 20–24 | **4.0%** | SABSSM VI 2022 |
| HIV incidence | Youth 15–24 (both sexes) | **0.39% / yr** | SABSSM VI 2022 |
| Viral suppression | Women 15–24 | **68.2%** | SABSSM VI 2022 |
| Viral suppression | Men 25–34 | **66.3%** | SABSSM VI 2022 |
| Knowledge of status | Youth 15–24 | **73.1%** | SABSSM VI 2022 |
| ART coverage (on ART) | Females (all ages) | **83.2%** | SABSSM VI 2022 |
| ART coverage (on ART) | Males (all ages) | **76.2%** | SABSSM VI 2022 |
| 15+ treatment cascade | PLHIV 15+ | **90%** aware → **91%** of aware on ART → **94%** of ART suppressed | Thembisa v4.6 2022 |
| PrEP coverage | Sexually active AGYW | **4%** (2022; was 0.1% in 2018) | Thembisa v4.6 |
| National HIV prevalence | All ages | **12.7%** (~7.8M PLHIV) | SABSSM VI 2022 |

## B. RESOLVED via Thembisa v5.0 (Age-specific outputs, 2022) + Aimee

Downloaded from thembisa.org → Downloads → "Age-specific National and Provincial
Model Outputs" v5.0 (`/content/filedl/AgeOutputs5_0`; sheet `SA`, year col 38=2022).

| Target | Value | Source | Status |
|---|---|---|---|
| Women 15–24 **incidence** | **0.96 / 100 PY** | Thembisa 2022 | ✅ (was the key gap) |
| Men **25–29** prevalence | 7.1% | Thembisa | ✅ driver |
| Men **30–34** prevalence | 12.0% | Thembisa | ✅ driver |
| Men **35–39** prevalence | 18.1% | Thembisa | ✅ driver |
| Men **40–44** prevalence | 22.4% | Thembisa | ✅ driver |
| Women 15–19 / 20–24 prevalence | 5.4% / 12.4% | Thembisa | ✅ (Thembisa 20–24 > SABSSM 8.0%) |
| **Partnership degree** (AGYW) | 1.71 past-yr | **Aimee** | ✅ (see AIMEE_DERIVED.md) |
| **Age gap** (AGYW↔older men) | ~5 yr (≥5y = disparate) | Maughan-Brown / HPTN 068 | ✅ literature default |

> The older-men prevalence rise (7%→12%→18%→22% across 25–44) is the quantified
> age-disparate driver: AGYW partner up the curve into a far higher-prevalence pool.

### Still outstanding (minor)
| Target | Source |
|---|---|
| Baseline AGYW HIV-testing rate | Aimee (derivable) or DHIS/DHS; or fit as free param |
| Partnership **durations** (main / casual) | SA behaviour / EpiModelHIV-SSA papers |

### Note on Thembisa vs SABSSM (women 20–24)
Thembisa models 12.4%, SABSSM survey measured 8.0%. Calibrate to **Thembisa**
(primary, age/sex/year consistent) and report SABSSM as the empirical cross-check;
flag the gap in limitations.

## Notes
- **Thembisa** = SA's official national HIV model — primary anchor for incidence/prevalence by age & sex; pull the version-matched age/sex spreadsheets for B.
- **SABSSM VI** women 15–24 carry ~2× the prevalence of male peers (5.6/8.0 vs 3.0/4.0) — the model must reproduce this **sex gap among youth**, which arises from age-disparate partnering, not biology alone.
- Viral suppression among young women (68%) and their likely older male partners (men 25–34, 66%) is **below** the 15+ average — important because it raises partner infectiousness. Calibrate these age-specific suppression values, not just the national 94%-of-ART.
- Match the calibration **year** across sources (2022) so prevalence/cascade/PrEP are mutually consistent.
