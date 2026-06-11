## calibrated_params.R — the calibrated baseline parameter set.
## Time-trend calibration to Thembisa v5.0 (1990-2022), with a 25-yr demographic
## burn-in (HIV-free 1965-1990) before seeding HIV in 1990. N=3000, 3 sims.
## Best fit: trajectory RMSE = 0.031 (women 15-24 AND adult 15-49).
##   women 15-24: model peak ~15.5% (Thembisa 16%), 2022 ~7.5% (9%)
##   adult 15-49: model peak ~21%   (Thembisa 18.6%), 2022 ~18.5% (17.6%)
##
## The intervention scenarios perturb test.rate / prep.start.rate among AGYW
## (chatbot reach x effect) on top of this baseline.

CALIBRATED <- list(
  # transmission / structure
  inf.prob.act    = 0.0035,   # per-act transmission (calibrated)
  acts.main       = 5,        # coital frequency/week (robust endemicity, off-threshold)
  acts.casual     = 2,
  age.gap         = 5,        # AGYW<->older men (literature)
  mix_main        = 8,        # age-mixing breadth (AGYW partners ~7.7y older, 34% men 30+)
  mix_cas         = 9,
  conc_main       = 0.04,     # concurrency (bounded by degree)
  conc_cas        = 0.10,
  deg_main        = 0.5,      # degree -> Aimee 1.71 past-year partners
  deg_cas         = 0.35,
  # young-women susceptibility (age-graded; biology)
  agyw.susc.15_19 = 2.0,
  agyw.susc.20_24 = 1.5,
  # epidemic timing / burn-in / ART
  first.year      = 1965,     # sim clock start (burn-in begins)
  burnin.year     = 25,       # HIV-free demographic/network settle
  seed.year       = 1990,     # HIV introduced
  seed.prev       = 0.008,
  art.start.year  = 2004,     # ART roll-out ramp start
  art.full.year   = 2014      # ART ramp reaches full
)

## Caveats (see CALIBRATION_STATUS.md):
## - Preliminary; single best-beta point (no formal posterior / parameter CIs).
## - Model's early-1990s rise lags Thembisa's explosive growth slightly; adult
##   peak runs ~2-3pp high. RMSE 0.031 over the full curve.
## - For publication: ABC over (beta, acts) with uncertainty; more sims; consider
##   a high-risk core for the steep early rise.
