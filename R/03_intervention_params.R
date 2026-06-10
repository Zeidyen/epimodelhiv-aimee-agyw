# 03_intervention_params.R
# Translate Clover-cohort chatbot effect sizes into EpiModelHIV parameter changes.
# These are AGGREGATE inputs only — no patient-level data here.

# ---- 1. Observed (associational) effects from the Clover cohort ------------
# From section3_analysis.py Cox models (timing-corrected, same-day excluded,
# N = 9,310). Exposure = MEANINGFUL ENGAGEMENT (>=2 active days) vs single-day
# users, adjusted for registration month. HRs are hazard-rate ratios, which map
# directly onto the model's per-step test.rate / prep.start.rate.
#
# INTERPRETATION: the effect applies to AGYW who become *meaningful engagers*,
# so the model's `reach` = fraction of AGYW who reach >=2 active days on Aimee
# (not merely those who open it once).
obs_effect <- list(
  testing_rate_RR = 2.11,   # HR_hiv  (95% CI 1.87-2.39, p~4e-32)
  prep_init_RR    = 2.22,   # HR_prep (95% CI 1.88-2.63, p~1e-20)
  prep_persist_RR = NA_real_  # not estimated in main analysis
)
# Associational (single-arm cohort, no no-chatbot control) -> self-selection
# confounded -> apply ONLY a causal fraction (below), never the raw HR.

# ---- 2. Causal-fraction scenarios ------------------------------------------
# Observed effects are confounded by self-selection; apply only a FRACTION as
# causal. Range = the primary sensitivity analysis.
causal_fraction <- c(conservative = 0.25, central = 0.50, optimistic = 1.00)

scale_effect <- function(rr, frac) 1 + (rr - 1) * frac

intervention_grid <- lapply(causal_fraction, function(f) {
  list(
    testing_rate_RR = scale_effect(obs_effect$testing_rate_RR, f),
    prep_init_RR    = scale_effect(obs_effect$prep_init_RR,    f),
    prep_persist_RR = scale_effect(obs_effect$prep_persist_RR, f)
  )
})

# ---- 3. Reach (share of AGYW using Aimee) ----------------------------------
reach <- c(0.10, 0.30, 0.50)

# Effective population-level parameter multiplier = blend of users (scaled effect)
# and non-users (no effect), weighted by reach.
apply_reach <- function(rr, reach) 1 + (rr - 1) * reach

saveRDS(list(intervention_grid = intervention_grid, reach = reach,
             apply_reach = apply_reach),
        "results/intervention_params.rds")
message("03_intervention_params.R ready — replace placeholder effect sizes with Clover estimates.")
