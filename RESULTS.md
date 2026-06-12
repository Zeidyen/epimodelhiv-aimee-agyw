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

In the no-chatbot counterfactual, the model projected approximately **718,000 new
HIV infections among AGYW nationally over 2025–2035** (median across replicates;
interquartile range 691,000–741,000). This baseline incorporates realistic oral-PrEP
discontinuation (≈6-month median retention), so that baseline PrEP coverage remained
low (~3%, consistent with South African estimates) with rapid turnover. Introducing
the chatbot in 2025 reduced this burden, with impact increasing monotonically with
both reach and the assumed causal fraction of the observed engagement effect (Table 1).

At **50% reach**, the chatbot averted an estimated **5.8% of AGYW infections
(≈41,400; 95% CI 22,900–59,900; p < 0.001)** under the central assumption and
**10.1% (≈72,400; 95% CI 56,100–88,700; p < 0.001)** under the optimistic
assumption; even the conservative assumption averted a significant **3.4% (≈24,300;
95% CI 6,600–42,100; p = 0.009)**. At 30% reach the central estimate was **3.5%
(≈25,500; 95% CI 7,400–43,500; p = 0.008)** and the optimistic estimate **5.8%
(≈41,500; 95% CI 26,500–56,600; p < 0.001)**. Effects were statistically supported
(95% CI excluding zero) in five of the nine intervention scenarios — all central and
optimistic scenarios at 30% and 50% reach, plus the 50%-reach conservative scenario;
the 30%-reach conservative and the small-signal 10%-reach scenarios (averting ≤1% of
infections) were not significant (Table 1). Because the intervention effect is small
relative to stochastic epidemic variability, inference used a **paired *t* interval on
the mean infections averted** across the common-random-number replicates (the
appropriate estimate of the expected effect), rather than the wider
replicate-to-replicate prediction interval. Efficiency improved with increasing reach
under the optimistic assumption (fewer AGYW reached per infection averted) but was
highly uncertain for the marginal conservative and low-reach scenarios.

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
| 10% | Conservative | −3,447 | −19,864 – 12,970 | 0.668 | −0.5% |
| 10% | Central | 988 | −16,911 – 18,887 | 0.910 | 0.1% |
| 10% | Optimistic | 8,075 | −15,670 – 31,819 | 0.489 | 1.1% |
| 30% | Conservative | 13,290 | −4,652 – 31,233 | 0.139 | 1.9% |
| 30% | Central | **25,473** | 7,426 – 43,521 | 0.008 | 3.5% |
| 30% | Optimistic | **41,528** | 26,472 – 56,584 | <0.001 | 5.8% |
| 50% | Conservative | **24,326** | 6,582 – 42,070 | 0.009 | 3.4% |
| 50% | Central | **41,418** | 22,923 – 59,913 | <0.001 | 5.8% |
| 50% | Optimistic | **72,360** | 56,067 – 88,654 | <0.001 | 10.1% |

Baseline (no chatbot): ~718,267 national AGYW HIV infections 2025–2035 (median;
mean 712,851; IQR 690,753–741,146). Bold rows: 95% CI excludes zero. Estimates are
mean infections averted over 24 stochastic replicates (population 20,000), paired with
the baseline by common random numbers; the 95% CI and p-value are from a paired *t*
test on the per-replicate averted differences. The baseline reflects realistic
oral-PrEP discontinuation (≈6-month median retention) and a care cascade validated
against the observed South African AGYW coverage gap (see text).
