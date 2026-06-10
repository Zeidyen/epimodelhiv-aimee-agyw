# 03_intervention_params.R
# Translate Clover-cohort chatbot effect sizes into EpiModelHIV parameter changes.
# These are AGGREGATE inputs only — no patient-level data here.

# ---- 1. Observed (associational) effects from the Clover cohort ------------
# TODO: fill from the empirical analysis (point estimate + CI).
# Example placeholders (NOT real):
obs_effect <- list(
  testing_rate_RR = 1.40,   # relative increase in HIV-testing rate among users
  prep_init_RR    = 1.60,   # relative increase in PrEP initiation among eligible
  prep_persist_RR = 1.15    # relative increase in PrEP persistence (if supported)
)

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
