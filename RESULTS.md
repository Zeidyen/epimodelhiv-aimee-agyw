# Results

## Calibrated baseline model

The calibrated model reproduced the South African HIV epidemic trajectory from
1990 to 2022 (Figure 2). Following HIV introduction in 1990, simulated HIV
prevalence among women aged 15–24 rose through the 1990s, peaked at approximately
15–16% in the early-to-mid 2000s, and declined to ~8% by 2022 as antiretroviral
therapy scaled up — closely tracking the Thembisa estimates. Adult (15–49)
prevalence followed the same rise–peak–decline pattern, peaking at ~19–21%. The
best-fitting per-act transmission probability (0.0035) produced a trajectory
root-mean-square error of 0.031 against the joint prevalence and incidence
targets. Modelled HIV incidence among AGYW peaked in the early 2000s and declined
thereafter, consistent with the Thembisa incidence trajectory. The model
reproduced the age-disparate structure underlying AGYW risk: HIV prevalence in the
older male partner pool (men 25–44) rose steeply with age (~7% to ~22%), against
which AGYW acquired infection.

### Baseline care cascade reproduces the South African AGYW gap

Before projecting the intervention, we verified that the calibrated model
reproduced the observed South African care cascade without any cascade-specific
tuning. At 2022 the model placed **73% of HIV-positive AGYW diagnosed, 66% on ART,
and 62% virally suppressed**, against **89% / 81% / 78% for all adults (15–49)** —
closely matching the empirical South African pattern in which AGYW lag the adult
cascade (~74% diagnosed and ~68% suppressed for young women, versus ~90% diagnosed
and ~77% suppressed overall). This AGYW shortfall emerged endogenously from the age
structure — young women are more recently infected and so have had less time to be
diagnosed and suppressed — rather than being imposed, providing independent support
for the baseline's realism.

## Projected impact of the Aimee chatbot, 2025–2035

In the no-chatbot counterfactual, the model projected approximately **733,000 new
HIV infections among AGYW nationally over 2025–2035** (median across replicates;
interquartile range 696,000–762,000). This baseline incorporates realistic oral-PrEP
discontinuation (≈6-month median retention), so that baseline PrEP coverage remained
low (~3%, consistent with South African estimates) with rapid turnover. Introducing
the chatbot in 2025 reduced this burden, with impact increasing monotonically with
both reach and the assumed causal fraction of the observed engagement effect (Table 1).

At **50% reach**, the chatbot averted an estimated **6.2% of AGYW infections
(≈45,300; 95% CI 36,900–53,800; p < 0.001)** under the central assumption and
**10.3% (≈75,200; 95% CI 65,700–84,700; p < 0.001)** under the optimistic
assumption; even the conservative assumption averted a significant **4.9% (≈35,700;
95% CI 27,100–44,300; p < 0.001)**. At 30% reach the estimates were **3.3% / 4.3% /
6.3%** (conservative / central / optimistic; all p < 0.001), and at 10% reach **1.2–2.5%**.
Effects were statistically supported (95% CI excluding zero) in **eight of the nine
intervention scenarios** — every scenario except the 10%-reach central scenario
(0.9%; p = 0.11). Because the intervention effect is small relative to stochastic
epidemic variability, inference used a **paired *t* interval on the mean infections
averted** across the common-random-number replicates (the appropriate estimate of the
expected effect), rather than the wider replicate-to-replicate prediction interval;
with 96 replicates these intervals were tight (e.g. ±9,500 at 50% reach, optimistic).
Efficiency improved with increasing reach under the optimistic assumption (fewer AGYW
reached per infection averted), reflecting the dose–response of the intervention.

## Mechanism

The projected impact was driven by increased PrEP uptake among reached AGYW
(Figure 5). In the counterfactual, PrEP coverage among AGYW remained near the
baseline level (~3%), with rapid turnover reflecting realistic oral-PrEP
discontinuation. Following chatbot introduction in 2025, PrEP coverage among AGYW
rose to approximately **8% at 30% reach, ~11% at 50% reach (central)**, and **~14%
at 50% reach (optimistic)** by 2034 — roughly half the coverage attainable under an
optimistic (long-retention) discontinuation assumption, because realistic
discontinuation continually erodes coverage and the chatbot must keep re-initiating
to sustain it. Corresponding increases in HIV testing and diagnosis accompanied the
PrEP gains. The incidence trajectories diverged from baseline after 2025, with the
largest reductions under the highest reach and effect-size assumptions (Figure 5,
panel A).

---

## Table 1. AGYW HIV infections averted by the Aimee chatbot, 2025–2035

| Reach | Causal fraction | Infections averted (mean) | 95% CI | p | % averted |
|---|---|---|---|---|---|
| 10% | Conservative | **8,945** | 602 – 17,287 | 0.036 | 1.2% |
| 10% | Central | 6,641 | −1,559 – 14,840 | 0.111 | 0.9% |
| 10% | Optimistic | **18,521** | 8,529 – 28,513 | <0.001 | 2.5% |
| 30% | Conservative | **23,871** | 15,017 – 32,726 | <0.001 | 3.3% |
| 30% | Central | **31,546** | 23,023 – 40,069 | <0.001 | 4.3% |
| 30% | Optimistic | **45,858** | 38,529 – 53,188 | <0.001 | 6.3% |
| 50% | Conservative | **35,670** | 27,050 – 44,290 | <0.001 | 4.9% |
| 50% | Central | **45,333** | 36,884 – 53,782 | <0.001 | 6.2% |
| 50% | Optimistic | **75,191** | 65,724 – 84,659 | <0.001 | 10.3% |

Baseline (no chatbot): ~732,899 national AGYW HIV infections 2025–2035 (median;
mean 727,129; IQR 696,130–762,040). Bold rows: 95% CI excludes zero. Estimates are
mean infections averted over 96 stochastic replicates (population 20,000), paired with
the baseline by common random numbers; the 95% CI and p-value are from a paired *t*
test on the per-replicate averted differences. The baseline reflects realistic
oral-PrEP discontinuation (≈6-month median retention) and a care cascade validated
against the observed South African AGYW coverage gap (see text).
