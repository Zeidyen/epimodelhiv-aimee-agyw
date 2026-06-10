# Calibration status

Honest state of the baseline calibration (no-chatbot) to SA 2022 prevalence.
All runs were local (laptop, single-core, N≤2000, ≤3 sims).

## What is done
- **Model structure complete & verified** — heterosexual, age-disparate (AGYW↔older
  men), AGYW-targeted chatbot levers, on maintained EpiModel 2.6.x.
- **All data inputs wired in**: degree (Aimee 1.71), effect sizes (Aimee HRs),
  prevalence/incidence targets (Thembisa v5.0), age gap (SA literature).
- **Free parameters identified, with defensible interpretations:**
  - `inf.prob.act` (β) — per-act transmission / epidemic level
  - `mix_main/mix_cas` — age-mixing breadth (mix=8 ⇒ AGYW partners ~7.7y older,
    34% with men 30+; matches SA age-disparate/blesser data)
  - `agyw.susc.15_19`, `agyw.susc.20_24` — age-graded young-women susceptibility
    (15-19 highest per-contact risk; well-documented biology)

## Best fit reached (preliminary)
- **N=1200**, β≈0.007, mix=8, susc≈1.5–2.5: **RMSE ≈ 0.031**. Men calibrate well;
  women reach the right region (15-19 lifted off zero by the wider mixing).
- The age-graded susceptibility lands the youngest band (15-19 → ~0.05 at N=2000).

## The blocker: the model is near the epidemic threshold
Point calibration does not converge cleanly because the epidemic is **near-critical**:
- A ~1.4× change in β swings the model from fading (R0≈1) to hyperendemic (~46%).
- Results are **finite-size sensitive** (N=1200 runs cooler than N=2000 at the same β).
- So there is a razor-thin β window, narrower than the stochastic + finite-size noise.

Real SA HIV is **robustly hyperendemic**, not knife-edge. A near-critical model
signals the transmission structure is too sparse to sustain a generalized epidemic
robustly — most likely **effective connectivity too low** (Aimee degree + literature
acts put HIV right at its sustainability threshold).

## Recommended path to a final calibration
1. **Make the epidemic robustly endemic** (move it off the threshold) before fitting:
   raise concurrency and/or acts-per-partnership and/or untreated infectious
   duration so prevalence is stable to small β changes. Re-check against the Aimee
   degree constraint.
2. **Fix a production N** large enough that finite-size effects stabilize (N≥5000).
3. **Use a proper optimizer** — ABC-SMC or Bayesian optimization over
   (β, mix, susc_15_19, susc_20_24), with multi-sim averaging, parallelized across
   cores. Hand-grids are inadequate for a 4-parameter near-critical fit.

## Limitations to state in the manuscript
- Preliminary, uncalibrated-at-production-scale; absolute numbers illustrative.
- Equilibrium burn-in approximates a 2022 cross-section of a non-equilibrium,
  ART-era epidemic.
- Thembisa (model) vs SABSSM (survey) differ for women 20-24 (12.4% vs 8.0%);
  calibrated to Thembisa.
- Network parameters: degree from Aimee (past-year proxy), durations/age-gap from
  literature; partner ages not in Aimee.

## Files
- `R/model_components.R` — reusable model (network builder + modules + run/extract)
- `R/20_calibration.R` — grid driver (history of passes 1-6)
- `R/21_confirm.R` — multi-sim production-N confirmation
- `R/diagnostic.R` — population/trajectory instrumentation
- `R/plot_calibration.R`, `R/plot_agedisparity.R` — figures → `results/*.png`
- `results/calibration_pass*.rds` — saved grid results
