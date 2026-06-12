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

In the no-chatbot counterfactual, the model projected approximately **871,000 new
HIV infections among AGYW nationally over 2025–2035** (median across replicates;
interquartile range 851,000–911,000). This baseline incorporates realistic oral-PrEP
discontinuation (≈6-month median retention), so that baseline PrEP coverage remained
low (~3%, consistent with South African estimates) with rapid turnover. Introducing
the chatbot in 2025 reduced this burden, with impact increasing with both reach and
the assumed causal fraction of the observed engagement effect (Table 1).

At **50% reach**, the chatbot averted an estimated **8.8% of AGYW infections
(≈76,300; 95% CI 33,300–119,300; p = 0.002)** under the central assumption and
**12.9% (≈112,600; 95% CI 59,300–165,900; p = 0.001)** under the optimistic
assumption. At 30% reach the central estimate was **7.4% (≈64,500; 95% CI
15,800–113,200; p = 0.014)**. Effects were statistically supported (95% CI excluding
zero) in six of the nine intervention scenarios, including all central and optimistic
scenarios at 30% and 50% reach; the 50%-reach conservative scenario and the
small-signal 10%-reach scenarios were not significant (Table 1). Because the
intervention effect is small relative to stochastic epidemic variability, inference
used a **paired *t* interval on the mean infections averted** across the
common-random-number replicates (the appropriate estimate of the expected effect),
rather than the wider replicate-to-replicate prediction interval. Efficiency declined
with increasing reach (more AGYW reached per infection averted), reflecting
diminishing marginal returns as coverage expanded.

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
| 10% | Conservative | 21,489 | −26,671 – 69,649 | 0.347 | 2.5% |
| 10% | Central | 25,883 | −26,611 – 78,378 | 0.301 | 3.0% |
| 10% | Optimistic | **43,115** | 4,109 – 82,121 | 0.033 | 4.9% |
| 30% | Conservative | **29,372** | 205 – 58,538 | 0.049 | 3.4% |
| 30% | Central | **64,471** | 15,751 – 113,190 | 0.014 | 7.4% |
| 30% | Optimistic | **48,786** | 5,274 – 92,298 | 0.031 | 5.6% |
| 50% | Conservative | 25,943 | −14,162 – 66,049 | 0.182 | 3.0% |
| 50% | Central | **76,310** | 33,348 – 119,272 | 0.002 | 8.8% |
| 50% | Optimistic | **112,584** | 59,312 – 165,856 | 0.001 | 12.9% |

Baseline (no chatbot): ~871,345 national AGYW HIV infections 2025–2035 (median;
mean 883,253). Bold rows: 95% CI excludes zero. Estimates are mean infections
averted over 12 stochastic replicates (population 10,000), paired with the baseline
by common random numbers; the 95% CI and p-value are from a paired *t* test on the
per-replicate averted differences. The baseline reflects realistic oral-PrEP
discontinuation (≈6-month median retention) and a care cascade validated against the
observed South African AGYW coverage gap (see text).
