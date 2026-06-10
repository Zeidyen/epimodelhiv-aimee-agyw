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

## B. Still to source (from primary reports)

| Target | Why it matters | Likely source |
|---|---|---|
| HIV **incidence in women 15–24 specifically** | The 0.39% is both-sexes-combined; AGYW incidence is higher and is the model's key calibration target | Thembisa age/sex outputs; SABSSM women-only |
| HIV prevalence **men 25–34 / 25–39** | Older male partners are the AGYW infection source — must be calibrated | SABSSM VI full report (age×sex table) |
| **Partnership degree** (main / casual) by age/sex | ERGM mean-degree target | SA behaviour surveys / SABSSM behaviour module |
| **Age-mixing / age-gap** for AGYW partnerships | Sets the age-disparate transmission that drives AGYW incidence | SABSSM; age-disparate-sex literature |
| **Partnership duration** (main / casual) | tergm dissolution coefficients | SA behaviour surveys |
| Baseline **HIV-testing rate/interval** AGYW | Pre-chatbot testing parameter | DHIS; DHS |

## Notes
- **Thembisa** = SA's official national HIV model — primary anchor for incidence/prevalence by age & sex; pull the version-matched age/sex spreadsheets for B.
- **SABSSM VI** women 15–24 carry ~2× the prevalence of male peers (5.6/8.0 vs 3.0/4.0) — the model must reproduce this **sex gap among youth**, which arises from age-disparate partnering, not biology alone.
- Viral suppression among young women (68%) and their likely older male partners (men 25–34, 66%) is **below** the 15+ average — important because it raises partner infectiousness. Calibrate these age-specific suppression values, not just the national 94%-of-ART.
- Match the calibration **year** across sources (2022) so prevalence/cascade/PrEP are mutually consistent.
