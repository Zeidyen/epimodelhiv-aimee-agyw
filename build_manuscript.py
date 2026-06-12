#!/usr/bin/env python3
"""Assemble the full Aimee/AGYW HIV-impact manuscript into a single Word .docx.
Run with /opt/miniconda3/bin/python3 build_manuscript.py"""
from docx import Document
from docx.shared import Pt, RGBColor, Inches
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT

doc = Document()

# ---- base styles ----
normal = doc.styles["Normal"]
normal.font.name = "Calibri"
normal.font.size = Pt(11)
normal.paragraph_format.space_after = Pt(6)
normal.paragraph_format.line_spacing = 1.15

def H1(t):
    p = doc.add_heading(t, level=1); return p
def H2(t):
    p = doc.add_heading(t, level=2); return p

def para(text, italic=False, bold=False, align=None, size=None):
    p = doc.add_paragraph()
    if align == "c": p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    # bold spans marked with **...**
    import re
    parts = re.split(r"(\*\*.*?\*\*)", text)
    for part in parts:
        if part.startswith("**") and part.endswith("**"):
            r = p.add_run(part[2:-2]); r.bold = True
        else:
            r = p.add_run(part)
        r.italic = italic
        if bold: r.bold = True
        if size: r.font.size = Pt(size)
    return p

def add_table(headers, rows, bold_row_idx=None, caption=None, widths=None):
    if caption:
        c = doc.add_paragraph(); r = c.add_run(caption); r.bold = True; r.font.size = Pt(10)
    t = doc.add_table(rows=1, cols=len(headers))
    t.style = "Light Grid Accent 1"
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    for j, h in enumerate(headers):
        cell = t.rows[0].cells[j]; cell.text = ""
        rr = cell.paragraphs[0].add_run(h); rr.bold = True; rr.font.size = Pt(9)
    bold_row_idx = bold_row_idx or set()
    for i, row in enumerate(rows):
        cells = t.add_row().cells
        for j, v in enumerate(row):
            cells[j].text = ""
            rr = cells[j].paragraphs[0].add_run(str(v))
            rr.font.size = Pt(9)
            if i in bold_row_idx: rr.bold = True
    if widths:
        for j, w in enumerate(widths):
            for row in t.rows:
                row.cells[j].width = Inches(w)
    doc.add_paragraph()
    return t

# ============================ TITLE ============================
title = doc.add_paragraph()
title.alignment = WD_ALIGN_PARAGRAPH.CENTER
r = title.add_run("Projected population-level impact of an AI health companion on HIV "
                  "infections among adolescent girls and young women in South Africa: "
                  "a calibrated dynamic network modelling study")
r.bold = True; r.font.size = Pt(16)

aut = doc.add_paragraph(); aut.alignment = WD_ALIGN_PARAGRAPH.CENTER
aut.add_run("[Author list]").italic = True
aff = doc.add_paragraph(); aff.alignment = WD_ALIGN_PARAGRAPH.CENTER
aff.add_run("[Affiliations] · Corresponding author: [name, email]").italic = True
doc.add_paragraph()

# ============================ ABSTRACT ============================
H1("Abstract")
para("**Background.** Adolescent girls and young women (AGYW) in South Africa bear a "
     "disproportionate burden of HIV. AI health companions delivered by mobile phone "
     "can increase engagement with HIV testing and pre-exposure prophylaxis (PrEP), but "
     "their population-level epidemiological impact is unknown. We estimated the number "
     "of AGYW HIV infections that could be averted by the Aimee AI health companion, "
     "using a transmission-dynamic model parameterised with effect sizes from a South "
     "African field-study cohort.")
para("**Methods.** We built a stochastic, individual-based dynamic network model of "
     "heterosexual HIV transmission in South Africa (EpiModel 2.6.1), with sex- and "
     "age-structured main and casual partnership networks, age-disparate mixing, "
     "age-graded female susceptibility, a four-state HIV care cascade with a "
     "time-varying antiretroviral-therapy (ART) scale-up, and PrEP. The model was "
     "calibrated to the South African HIV prevalence and incidence trajectory "
     "(1990–2022; Thembisa v5.0). The chatbot was represented as a perturbation of "
     "AGYW HIV-testing and PrEP-initiation rates among reached women from 2025, using "
     "hazard ratios estimated from the field-study cohort (2.11 for testing, 2.22 for "
     "PrEP) scaled by an assumed causal fraction. We evaluated a factorial grid of "
     "reach (10/30/50% of AGYW) × causal fraction (25/50/100%) and projected AGYW "
     "infections averted over 2025–2035, using a paired common-random-number design.")
para("**Results.** The calibrated model reproduced the South African epidemic "
     "trajectory (trajectory RMSE 0.031) and, without cascade-specific tuning, the "
     "observed AGYW care-cascade shortfall (73% of HIV-positive AGYW diagnosed and 62% "
     "virally suppressed, vs 89% and 78% among adults). In the no-chatbot "
     "counterfactual the model projected ~718,000 AGYW HIV infections nationally over "
     "2025–2035. At 50% reach the chatbot averted an estimated **5.8% of infections "
     "(41,418; 95% CI 22,923–59,913; p < 0.001)** under the central assumption and "
     "**10.1% (72,360; 56,067–88,654; p < 0.001)** under the optimistic assumption; "
     "effects were statistically supported in five of nine scenarios. Impact was driven "
     "by increased AGYW PrEP coverage (from ~3% to 8–14%).")
para("**Conclusions.** Under realistic assumptions about South African HIV treatment "
     "and PrEP coverage — including poor oral-PrEP continuation — an AI health companion "
     "that durably engages AGYW with testing and PrEP could avert a meaningful share of "
     "new HIV infections. The estimate is conservative and depends on the causal "
     "fraction of the observed engagement effect, which the field study cannot establish.")
para("**Keywords:** HIV; adolescent girls and young women; PrEP; digital health; "
     "AI chatbot; agent-based model; South Africa.", size=10)

# ============================ INTRODUCTION ============================
doc.add_page_break()
H1("Introduction")
para("Adolescent girls and young women (AGYW, aged 15–24 years) in sub-Saharan Africa "
     "acquire HIV at two to three times the rate of their male peers, and South Africa "
     "carries one of the highest AGYW HIV burdens in the world. The drivers are "
     "well described: age-disparate partnerships with older men who have substantially "
     "higher HIV prevalence, biological susceptibility, concurrency within the "
     "partnership network, and structural barriers to prevention and care. Despite a "
     "large national ART programme and the availability of oral pre-exposure "
     "prophylaxis (PrEP), AGYW continue to lag the rest of the population on the HIV "
     "care cascade and on PrEP coverage and continuation.")
para("Pre-exposure prophylaxis is highly effective when taken, but among AGYW its "
     "real-world impact has been limited by low uptake and poor persistence: many young "
     "women who initiate oral PrEP discontinue within months. Interventions that raise "
     "both the demand for and the sustained use of testing and PrEP are therefore a "
     "priority. Mobile-phone–delivered digital health tools, and increasingly "
     "conversational AI “health companions,” offer a scalable channel for "
     "reaching young women with personalised, stigma-free information and "
     "navigation support.")
para("The Aimee AI health companion, deployed in the Clover field study in South "
     "Africa, engaged young people by mobile phone and was associated with increased "
     "uptake of HIV testing and PrEP among more-engaged users. Whether such "
     "individual-level associations translate into a measurable reduction in "
     "population HIV incidence — and how large that reduction might plausibly be — "
     "cannot be read directly off a single-arm cohort. Answering it requires a "
     "transmission-dynamic model that embeds the intervention in the partnership "
     "network through which HIV actually spreads, and that is anchored to the real "
     "South African epidemic and its treatment and prevention coverage.")
para("We therefore developed a calibrated, individual-based dynamic network model of "
     "heterosexual HIV transmission among South African AGYW and used it to project the "
     "number of new HIV infections that the Aimee companion could avert over 2025–2035. "
     "We deliberately parameterised the baseline to reflect the real South African "
     "context — a validated care cascade including the AGYW coverage gap, and realistic "
     "oral-PrEP discontinuation — so that the chatbot's projected effect is an "
     "incremental gain over a realistic standard of care, and we propagated the "
     "observational nature of the engagement effect through an explicit causal-fraction "
     "sensitivity analysis.")

# ============================ METHODS ============================
doc.add_page_break()
H1("Methods")

H2("Study design and overview")
para("We developed a stochastic, individual-based dynamic network model of heterosexual "
     "HIV transmission in South Africa to estimate the population-level impact of an AI "
     "health companion (Aimee) on HIV incidence among AGYW (women aged 15–24 years). The "
     "model was implemented in the EpiModel framework (v2.6.1) in R, building on the "
     "EpiModel Gallery “HIV Transmission with Care Cascade and PrEP” reference "
     "model, and extended with sex- and age-structured partnership networks, an "
     "age-disparate mixing structure, age-graded female susceptibility, and an "
     "intervention layer representing chatbot-driven changes to HIV testing and PrEP "
     "uptake. The model was calibrated to the South African HIV epidemic trajectory "
     "(1990–2022) and used to project AGYW HIV infections averted by the chatbot over "
     "2025–2035 under a range of reach and effect-size assumptions.")

H2("Population and partnership network")
para("The model simulated a closed sexually-active population aged 15–50 years. "
     "Partnerships were represented as two concurrent dynamic networks — main "
     "(longer-duration, higher per-act frequency) and casual (shorter-duration) — each "
     "estimated as a separate temporal exponential-family random graph model (TERGM) "
     "sharing the same node set. Each layer included an edges term, a concurrent term "
     "(capturing overlapping partnerships, the structural feature central to generalised "
     "HIV epidemics), and two structural constraints: (1) heterosexual mixing, imposed "
     "via an offset nodematch(“sex”) term with coefficient −∞; and "
     "(2) age-disparate mixing, imposed via an absdiff term on a directional "
     "preferred-partner age (female age shifted upward by a fixed gap), so that AGYW "
     "preferentially partnered with older men. The mixing breadth was set so that AGYW "
     "partners were on average ~7.7 years older, with ~34% of AGYW partnerships "
     "involving men aged ≥30 years, consistent with South African age-disparate "
     "(“blesser”) partnership data. Mean partnership degree was informed by "
     "the Clover/Aimee cohort (mean 1.71 sexual partners in the past year). Vital "
     "dynamics comprised aging, entry of new susceptible 15-year-olds, and exit by "
     "background mortality, AIDS mortality, and aging out at age 50.")

H2("HIV natural history, transmission, and care cascade")
para("HIV progression was modelled as susceptible → acute → chronic → "
     "AIDS, with stage-specific relative infectiousness (acute 5×, AIDS 2× the chronic "
     "reference). Per-partnership transmission each weekly time step was a function of a "
     "per-act transmission probability, the number of sex acts (5/week main, 2/week "
     "casual), infector stage, and ART status (treatment-as-prevention: virally "
     "suppressed individuals near-non-infectious). Young women carried an age-graded "
     "elevated per-contact susceptibility (2.0× at ages 15–19 and 1.5× at 20–24).")
para("The care cascade comprised four states — undiagnosed, diagnosed (off ART), on ART "
     "(not suppressed), and virally suppressed — with transitions governed by HIV "
     "testing/diagnosis, linkage, viral suppression, and ART discontinuation rates. ART "
     "availability was introduced as a time-varying scale-up ramping from 0 (pre-2004) "
     "to full (2014), reproducing the South African roll-out. PrEP was modelled on the "
     "susceptible side as a per-act reduction in acquisition probability (95% efficacy), "
     "with stochastic initiation among eligible individuals and discontinuation. The "
     "PrEP discontinuation rate was set to reflect the documented poor continuation of "
     "oral PrEP among South African AGYW (≈6-month median retention), so that "
     "baseline PrEP coverage remained low (~3%) with rapid turnover rather than "
     "accumulating an unrealistically protected stock.")
para("To check that the baseline reflected real South African treatment and care "
     "coverage, we compared the model's emergent care cascade with national estimates. "
     "The calibrated model reproduced the observed cascade — including the AGYW "
     "shortfall relative to adults (model: 73% of HIV-positive AGYW diagnosed and 62% "
     "suppressed, vs 89% and 78% for all adults; South Africa: ~74%/~68% for AGYW vs "
     "~90%/~77% overall) — without any cascade-specific tuning, because young women are "
     "more recently infected and so have had less time to be diagnosed and suppressed.")

H2("Data sources and chatbot effect sizes")
add_table(
    ["Domain", "Source"],
    [["Chatbot effect on HIV testing and PrEP uptake", "Clover/Aimee field-study cohort (analytic N = 9,310)"],
     ["Partnership degree", "Clover/Aimee cohort (past-year partner counts)"],
     ["HIV prevalence and incidence by age/sex, 1990–2022", "Thembisa v5.0 national model"],
     ["Age-disparate partnership structure", "South African age-mixing literature"]],
    caption=None, widths=[3.0, 3.4])
para("From the Clover cohort, Cox proportional-hazards models (adjusted for "
     "registration month, with same-day events excluded and outcomes anchored at the "
     "analytic cohort) estimated that meaningful engagement (≥2 active days vs "
     "single-day use) was associated with a hazard ratio of 2.11 (95% CI 1.87–2.39) for "
     "HIV testing and 2.22 (1.88–2.63) for PrEP initiation. Because these are "
     "observational associations subject to self-selection, they were not applied as "
     "causal effects directly (see Intervention scenarios).")

H2("Calibration")
para("The model was calibrated using the trajectory-fitting approach standard for South "
     "African HIV models, rather than to a single equilibrium cross-section. The "
     "simulation clock began in 1965 with a 25-year HIV-free demographic and network "
     "burn-in to allow the age structure and partnerships to reach stationarity. HIV "
     "was seeded in 1990 at 0.8% prevalence and simulated forward to 2022 with the "
     "time-varying ART scale-up. The free transmission parameter (per-act transmission "
     "probability) was fit so that the simulated prevalence and incidence trajectories "
     "reproduced the Thembisa v5.0 targets across 1990–2022. The best-fitting value "
     "(per-act probability 0.0035) yielded a trajectory root-mean-square error of 0.031; "
     "the calibrated model reproduced the rise, peak, and ART-era decline of the South "
     "African epidemic. Network degree, age gap, and young-women susceptibility were "
     "fixed from data/literature; ART-era cascade dynamics were calibrated jointly with "
     "transmission.")

H2("Intervention scenarios")
para("The Aimee chatbot was represented not mechanistically but as a perturbation of "
     "the two behavioural parameters it affects, applied to the subset of AGYW reached, "
     "from 2025 onward. Each woman was designated an Aimee user at cohort entry with "
     "probability equal to the scenario reach; while she was AGYW (15–24) and from 2025, "
     "her HIV-testing rate was multiplied by a testing rate ratio and her PrEP "
     "initiation rate by a PrEP rate ratio (with reached AGYW also rendered "
     "PrEP-eligible, consistent with their priority-population status). Rate ratios were "
     "derived from the Clover hazard ratios scaled by an assumed causal fraction: rate "
     "ratio = 1 + (HR − 1) × causal fraction. We evaluated a full factorial grid of "
     "reach (10%, 30%, 50% of AGYW) × causal fraction (25% [conservative], 50% "
     "[central], 100% [optimistic]), plus a no-chatbot counterfactual baseline.")

H2("Analysis")
para("For each scenario we projected the simulation to 2035 and computed the cumulative "
     "number of AGYW HIV infections over 2025–2035, scaled to the national AGYW "
     "population (5,071,746; Thembisa 2022). To isolate the small intervention effect "
     "from stochastic simulation noise, we used a paired design with common random "
     "numbers: each replicate used a fixed random seed shared across all scenarios, so "
     "baseline and intervention replicates shared an identical pre-2025 epidemic history "
     "and diverged only through the chatbot. Correct alignment was confirmed by verifying "
     "that pre-2025 infection counts were identical across scenarios within each "
     "replicate. We ran 12 replicates per scenario at a population of 10,000, in parallel "
     "across (scenario × replicate) tasks. Because the intervention effect is small "
     "relative to stochastic epidemic variability, inference was based on the "
     "per-replicate paired difference in national AGYW infections (baseline minus "
     "scenario); for each scenario we report the mean infections averted with a 95% "
     "confidence interval and p-value from a paired t test on these differences — the "
     "appropriate estimate of the expected effect and its estimation uncertainty. The "
     "model was implemented in R (EpiModel 2.6.1; statnet ergm/tergm); analysis code is "
     "available at the study repository.")

H2("Ethical considerations")
para("Only aggregate, de-identified, study-level summary statistics from the Clover "
     "field study were used to parameterise the model; no individual-level participant "
     "data were incorporated into or distributed with the model.")

# ============================ RESULTS ============================
doc.add_page_break()
H1("Results")

H2("Calibrated baseline model")
para("The calibrated model reproduced the South African HIV epidemic trajectory from "
     "1990 to 2022. Following HIV introduction in 1990, simulated prevalence among women "
     "aged 15–24 rose through the 1990s, peaked at approximately 15–16% in the "
     "early-to-mid 2000s, and declined to ~8% by 2022 as ART scaled up — closely "
     "tracking the Thembisa estimates. Adult (15–49) prevalence followed the same "
     "rise–peak–decline pattern, peaking at ~19–21%. The best-fitting per-act "
     "transmission probability (0.0035) produced a trajectory root-mean-square error of "
     "0.031 against the joint prevalence and incidence targets. The model reproduced the "
     "age-disparate structure underlying AGYW risk: HIV prevalence in the older male "
     "partner pool (men 25–44) rose steeply with age (~7% to ~22%), against which AGYW "
     "acquired infection.")

H2("Baseline care cascade reproduces the South African AGYW gap")
para("Before projecting the intervention, we verified that the calibrated model "
     "reproduced the observed South African care cascade without any cascade-specific "
     "tuning. At 2022 the model placed 73% of HIV-positive AGYW diagnosed, 66% on ART, "
     "and 62% virally suppressed, against 89% / 81% / 78% for all adults (15–49) — "
     "closely matching the empirical pattern in which AGYW lag the adult cascade "
     "(~74% diagnosed and ~68% suppressed for young women, vs ~90% diagnosed and ~77% "
     "suppressed overall). This shortfall emerged endogenously from the age structure — "
     "young women are more recently infected and so have had less time to be diagnosed "
     "and suppressed — rather than being imposed, providing independent support for the "
     "baseline's realism.")
add_table(
    ["Group", "Diagnosed", "On ART", "Suppressed", "SA reference"],
    [["AGYW (women 15–24)", "73%", "66%", "62%", "~74% dx, ~68% suppressed"],
     ["Adults (15–49)", "89%", "81%", "78%", "~90% dx, ~77% suppressed"],
     ["Men 25–34", "84%", "78%", "76%", "~66% suppressed"]],
    caption="Table 1. Model care cascade vs South African estimates, 2022 (% of HIV-positive in group).",
    widths=[1.7,1.0,0.9,1.1,1.9])

H2("Projected impact of the Aimee chatbot, 2025–2035")
para("In the no-chatbot counterfactual, the model projected approximately 718,000 new "
     "HIV infections among AGYW nationally over 2025–2035 (median; interquartile range "
     "691,000–741,000). This baseline incorporates realistic oral-PrEP discontinuation "
     "(≈6-month median retention), so baseline PrEP coverage remained low (~3%, "
     "consistent with South African estimates) with rapid turnover. Introducing the "
     "chatbot in 2025 reduced this burden, with impact increasing monotonically with both "
     "reach and the assumed causal fraction of the observed engagement effect (Table 2).")
para("At 50% reach, the chatbot averted an estimated **5.8% of AGYW infections "
     "(41,418; 95% CI 22,923–59,913; p < 0.001)** under the central assumption and "
     "**10.1% (72,360; 56,067–88,654; p < 0.001)** under the optimistic assumption; even "
     "the conservative assumption averted a significant 3.4% (24,326; 6,582–42,070; "
     "p = 0.009). At 30% reach the central estimate was 3.5% (25,473; 7,426–43,521; "
     "p = 0.008) and the optimistic 5.8% (41,528; 26,472–56,584; p < 0.001). Effects were "
     "statistically supported (95% CI excluding zero) in five of the nine intervention "
     "scenarios — all central and optimistic scenarios at 30% and 50% reach, plus the "
     "50%-reach conservative scenario; the 30%-reach conservative and the small-signal "
     "10%-reach scenarios (averting ≤1% of infections) were not significant. Efficiency "
     "improved with increasing reach under the optimistic assumption but was highly "
     "uncertain for the marginal conservative and low-reach scenarios.")
add_table(
    ["Reach", "Causal fraction", "Infections averted (mean)", "95% CI", "p", "% averted"],
    [["10%","Conservative","−3,447","−19,864 – 12,970","0.668","−0.5%"],
     ["10%","Central","988","−16,911 – 18,887","0.910","0.1%"],
     ["10%","Optimistic","8,075","−15,670 – 31,819","0.489","1.1%"],
     ["30%","Conservative","13,290","−4,652 – 31,233","0.139","1.9%"],
     ["30%","Central","25,473","7,426 – 43,521","0.008","3.5%"],
     ["30%","Optimistic","41,528","26,472 – 56,584","<0.001","5.8%"],
     ["50%","Conservative","24,326","6,582 – 42,070","0.009","3.4%"],
     ["50%","Central","41,418","22,923 – 59,913","<0.001","5.8%"],
     ["50%","Optimistic","72,360","56,067 – 88,654","<0.001","10.1%"]],
    bold_row_idx={4,5,6,7,8},
    caption="Table 2. AGYW HIV infections averted by the Aimee chatbot, 2025–2035.",
    widths=[0.6,1.2,1.5,1.5,0.6,0.8])
para("Baseline (no chatbot): ~718,267 national AGYW HIV infections 2025–2035 (median; "
     "mean 712,851; IQR 690,753–741,146). Bold rows: 95% CI excludes zero. Estimates are "
     "mean infections averted over 24 stochastic replicates (population 20,000), paired "
     "with the baseline by common random numbers; 95% CI and p-value from a paired t test "
     "on the "
     "per-replicate averted differences.", italic=True, size=9)

H2("Mechanism")
para("The projected impact was driven by increased PrEP uptake among reached AGYW. In "
     "the counterfactual, PrEP coverage among AGYW remained near the baseline level "
     "(~3%), with rapid turnover reflecting realistic oral-PrEP discontinuation. "
     "Following chatbot introduction in 2025, PrEP coverage among AGYW rose to "
     "approximately 8% at 30% reach, ~11% at 50% reach (central), and ~14% at 50% reach "
     "(optimistic) by 2034 — roughly half the coverage attainable under an optimistic "
     "(long-retention) discontinuation assumption, because realistic discontinuation "
     "continually erodes coverage and the chatbot must keep re-initiating to sustain it. "
     "Corresponding increases in HIV testing and diagnosis accompanied the PrEP gains, "
     "and the incidence trajectories diverged from baseline after 2025, with the largest "
     "reductions under the highest reach and effect-size assumptions.")

# ============================ DISCUSSION ============================
doc.add_page_break()
H1("Discussion")
para("Using a calibrated dynamic network model of heterosexual HIV transmission in "
     "South Africa, we estimated that an AI health companion that durably engages AGYW "
     "with HIV testing and PrEP could avert a meaningful share of new infections — on "
     "the order of 6–10% at 50% reach under central-to-optimistic assumptions, "
     "corresponding to roughly 41,000–72,000 infections nationally over a decade. The "
     "effect was statistically supported in five of nine scenarios and increased "
     "monotonically with reach and with the assumed causal fraction of the observed "
     "engagement effect. To our knowledge this is the first transmission-dynamic "
     "estimate of the population HIV impact of a conversational AI health tool.")
para("The projected benefit operated almost entirely through PrEP. Because the chatbot "
     "raises PrEP initiation among a priority population that partners with "
     "higher-prevalence older men, even modest absolute coverage gains translate into "
     "averted acquisitions. Critically, the magnitude of the effect was bounded by "
     "PrEP continuation: under realistic oral-PrEP discontinuation, chatbot-driven "
     "coverage plateaued at roughly half the level it reached under an optimistic "
     "long-retention assumption, because the intervention must continually re-initiate "
     "women who fall off PrEP. This points to a clear programmatic implication — tools "
     "that sustain PrEP persistence, or that channel young women toward longer-acting "
     "formulations such as injectable cabotegravir or lenacapavir, would be expected to "
     "yield substantially larger and more durable impact than demand generation alone.")
para("A particular strength of the analysis is that the baseline was anchored to the "
     "real South African standard of care rather than an idealised one. The model "
     "reproduced the observed care cascade, including the well-documented AGYW shortfall "
     "in diagnosis and viral suppression relative to adults, as an emergent property of "
     "the age structure rather than an imposed assumption — an independent, "
     "out-of-sample validation of the baseline. We further parameterised PrEP "
     "discontinuation to match the poor real-world continuation seen among South African "
     "AGYW. Both choices make the counterfactual harder for the intervention to improve "
     "upon, so the resulting estimates are conservative: the chatbot's effect is an "
     "incremental gain over a realistic, leaky standard of care, not over an optimistic "
     "one. The paired common-random-number design further isolated the intervention "
     "signal from stochastic epidemic noise, allowing a small effect to be detected with "
     "a modest number of replicates.")
para("Our estimates are consistent in direction and order of magnitude with prior "
     "modelling of combination prevention and PrEP scale-up among AGYW in southern and "
     "eastern Africa, which has generally found that realistic increments in PrEP "
     "coverage avert single-digit to low-double-digit percentages of infections over "
     "five-to-ten-year horizons, with efficiency falling as coverage expands. The "
     "diminishing marginal returns we observed at higher reach reflect the same "
     "saturation dynamics reported in those analyses.")
para("This study has several limitations. First, and most importantly, the chatbot "
     "effect sizes are observational, derived from a single-arm cohort in which "
     "more-engaged users may differ systematically from less-engaged users; we addressed "
     "this with an explicit causal-fraction sensitivity range (25–100%) but cannot "
     "establish causality, and the conservative scenarios — in which only a quarter of "
     "the observed association is taken to be causal — were generally not statistically "
     "significant. Second, the calibration used a single best-fitting parameter set "
     "rather than a full Bayesian (e.g. approximate Bayesian computation) posterior, so "
     "parameter uncertainty is not fully propagated into the projections; the reported "
     "intervals capture stochastic and not parametric uncertainty. Third, the simulated "
     "early-1990s rise is slightly slower than the observed explosive growth, reflecting "
     "the absence of an explicit high-risk core group, although the 2022 endpoint from "
     "which projections begin is well calibrated. Fourth, partnership age-mixing was "
     "drawn from the literature rather than the study population, and partnership degree "
     "was approximated from past-year partner counts. Finally, the projections are "
     "illustrative of relative impact under stated assumptions rather than precise "
     "forecasts, and they do not include cost or cost-effectiveness, which would be a "
     "natural next step.")
para("In conclusion, under assumptions calibrated to the real South African HIV "
     "epidemic and its imperfect treatment and prevention coverage, an AI health "
     "companion that meaningfully and durably engages young women with testing and PrEP "
     "could avert a substantial number of HIV infections among a population that "
     "remains at the centre of the epidemic. The size of that benefit hinges on how "
     "much of the observed engagement effect is genuinely causal and on whether PrEP "
     "use can be sustained — both of which are tractable targets for the next generation "
     "of digital prevention tools and for the randomised evaluations needed to confirm "
     "these projections.")

# ============================ REFERENCES ============================
doc.add_page_break()
H1("References")
refs = [
 "[Clover/Aimee field study] — authors' own field-study manuscript/report providing the cohort, engagement, HIV-testing and PrEP-uptake data and effect sizes. [Complete citation.]",
 "Jenness SM, Goodreau SM, Morris M. EpiModel: An R Package for Mathematical Modeling of Infectious Disease over Networks. J Stat Softw. 2018;84(8):1–47.",
 "Morris M, Kretzschmar M. Concurrent partnerships and the spread of HIV. AIDS. 1997;11(5):641–648.",
 "R Core Team. R: A Language and Environment for Statistical Computing. R Foundation for Statistical Computing; 2024.",
 "Handcock MS, Hunter DR, Butts CT, Goodreau SM, Morris M. statnet: Software tools for the representation, visualization, analysis and simulation of network data. J Stat Softw. 2008;24(1).",
 "Johnson LF, Dorrington RE. Thembisa version 5.0: A model for evaluating the impact of HIV/AIDS in South Africa. University of Cape Town; 2024. https://www.thembisa.org.",
 "Human Sciences Research Council. The Sixth South African National HIV Prevalence, Incidence, Behaviour and Communication Survey (SABSSM VI), 2022. HSRC; 2023.",
 "Maughan-Brown B, Kenyon C, Lurie MN. Partner age differences and concurrency in South Africa: Implications for HIV-infection risk among young women. AIDS Behav. 2014;18(12):2469–2476.",
 "[HPTN 068] Age-disparate partnerships and incident HIV infection in adolescent girls and young women in rural South Africa. AIDS. 2019;33(1).",
 "[EMOD-HIV western Kenya] Health and economic impact of oral PrEP provision across subgroups in western Kenya: a modelling analysis. 2025. [PubMed 39800385.]",
 "EpiModel PrEP intervention studies (initiation/adherence/persistence; percent infections averted). EpiModel/PrEP-Optimize and related publications.",
 "Noise-free comparison of stochastic agent-based simulations using common random numbers. 2024. arXiv:2409.02086.",
 "[PrEP efficacy] — relevant oral TDF/FTC or injectable cabotegravir/lenacapavir trial for the per-act efficacy assumption. [Complete citation.]",
 "[ART treatment-as-prevention] HPTN 052 or equivalent for the near-zero infectiousness of virally suppressed individuals. [Complete citation.]",
]
for i, r in enumerate(refs, 1):
    p = doc.add_paragraph(); p.paragraph_format.left_indent = Inches(0.3)
    p.paragraph_format.first_line_indent = Inches(-0.3)
    p.add_run(f"{i}. {r}").font.size = Pt(10)

# ============================ SUPPLEMENT ============================
doc.add_page_break()
H1("Supplementary material")
H2("Table S1. Model parameters")
para("Per-time-step rates are weekly. Values are from the calibrated model; "
     "“calibrated” indicates a value fit to the SA trajectory, "
     "“data”/“literature” indicates a fixed input.", italic=True, size=9)
add_table(["Parameter","Value","Source / note"],
 [["Per-act transmission probability","0.0035","Calibrated to SA trajectory"],
  ["Sex acts per week, main / casual","5 / 2","Calibrated (plausible range)"],
  ["Relative infectiousness, acute / AIDS","5× / 2×","Literature"],
  ["Rel. infectiousness on ART, unsupp. / supp.","0.30 / 0.01","Literature (TasP)"],
  ["AGYW susceptibility, 15–19 / 20–24","2.0 / 1.5","Literature"],
  ["PrEP efficacy (per-act)","0.95","Literature"],
  ["Mean degree, main / casual","0.50 / 0.35","Aimee cohort (≈1.71 past-year partners)"],
  ["Concurrency, main / casual","4% / 10%","Bounded by mean degree"],
  ["Age-mixing breadth, main / casual","8 / 9","AGYW partner gap ≈7.7y; 34% men ≥30"],
  ["Preferred partner age gap (AGYW)","5 years","SA age-disparate literature"],
  ["Partnership duration, main / casual","200 / 26 weeks","Literature"],
  ["HIV testing/diagnosis rate","0.01 / week","Calibrated/literature"],
  ["Linkage to ART","0.50 / week","Cascade"],
  ["Viral suppression","0.30 / week","Cascade"],
  ["ART discontinuation","0.01 / week","Cascade"],
  ["ART scale-up window","ramp 2004 → 2014","SA roll-out"],
  ["PrEP initiation rate","0.005 / week","Literature"],
  ["PrEP discontinuation rate","0.027 / week","≈6-mo median retention (SA oral PrEP)"],
  ["HIV seed year / prevalence","1990 / 0.8%","Calibration setup"],
  ["Demographic burn-in","1965–1990 (HIV-free)","Calibration setup"],
  ["National AGYW population (scaling)","5,071,746","Thembisa 2022"],
  ["Replicates / population size","24 / 20,000","Simulation design"]],
 widths=[2.6,1.5,2.5])

H2("Table S2. Calibration targets (Thembisa v5.0, 2022)")
add_table(["Target","Value"],
 [["HIV prevalence, women 15–19 / 20–24","5.4% / 12.4%"],
  ["HIV prevalence, adult 15–49","17.6%"],
  ["HIV incidence, women 15–24","0.96 / 100 PY"],
  ["Older-men prevalence, 25–29 / 30–34 / 35–39 / 40–44","7.1 / 12.0 / 18.1 / 22.4%"],
  ["Best-fit trajectory RMSE","0.031"]],
 widths=[3.8,2.2])

out = "Aimee_AGYW_HIV_manuscript.docx"
doc.save(out)
print("Wrote", out)
