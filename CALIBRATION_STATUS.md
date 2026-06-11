# Calibration status

## ✅ ACHIEVED — preliminary calibrated baseline (time-trend)
The model reproduces the SA HIV trajectory 1990-2022. Calibrated via the
time-trend method with a 25-yr demographic burn-in (HIV-free 1965-1990) then HIV
seeded in 1990; N=3000, 3 sims. **Best fit: β=0.0035, trajectory RMSE=0.031**
(fits women 15-24 AND adult 15-49). Parameters in `R/calibrated_params.R`.
Residuals: early-1990s rise lags slightly; adult peak ~2-3pp high. Single
best-β point (no posterior yet). `results/production_fit.png`.

---

Honest state of the baseline calibration (no-chatbot) to SA prevalence.
History below documents the journey (equilibrium → time-trend). All runs local
(single-core).

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

## UPDATE — time-trend restructure solved the knife-edge
Switched from equilibrium cross-section to the **standard SA approach: fit the
prevalence trajectory 1990-2022** (`R/30_timetrend.R`): seed 0.8% in 1990,
time-varying ART scale-up (`cascade_tt`, ramp 2004-2014), run 33 yr, fit the
women-15-24 curve to Thembisa.

Findings:
- With **acts-per-partnership raised to 5/2** (coital frequency; the legitimate
  lever once degree is fixed by Aimee data), the epidemic **grows robustly off
  the threshold** and reproduces the **rise → peak → ART-driven decline shape**.
  The near-critical knife-edge is GONE.
- Note: concurrency is bounded by mean degree (can't exceed it) — raising it
  broke the ERGM; acts is the right lever instead.
- Level is set by β: acts=5/2 with β≈0.006 → peak ~50%; β≈0.003 → peak ~10%.
  Target peak ~16% sits near **β≈0.004**.
- **Right regime located: acts=5/2, β≈0.004.** But the AGYW band is a small
  subgroup (~125 at N=1000) so single-sim prevalence is noisy — can't pin β
  precisely at this scale.

## Recommended path to a final calibration
1. ✅ **Robust endemicity achieved** via acts=5/2 + the time-trend structure.
2. **Run at production scale** — N≥3000–5000 with multi-sim averaging, so the AGYW
   subgroup is large enough for a smooth trajectory (single-sim N=1000 is too noisy
   to pin β). Parallelize across cores; this is a long (overnight-scale) job.
3. **Optimize over (β, acts)** to the full trajectory (women 15-24 AND adult 15-49)
   — ABC-SMC or a fine β sweep at production N. Right regime is acts=5/2, β≈0.004.
4. Then run the 2022 age/sex cross-section check (the `00_targets.R` bands) and the
   intervention scenarios on the calibrated baseline.

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
