# 05_analysis.R
# Compute outcomes: HIV infections averted vs baseline, incidence reduction, NNT.

library(EpiModel)

# results <- readRDS("results/scenario_runs.rds")

# ---- Outcomes (per scenario vs baseline) -----------------------------------
# cumulative infections averted = baseline cumulative incidence - scenario
# % averted                     = averted / baseline cumulative incidence
# incidence-rate reduction      = 1 - (scenario incidence / baseline incidence)
# NNT                           = chatbot users / infections averted

summarise_scenario <- function(sim_base, sim_sc, reach, n_agyw) {
  # TODO: extract cumulative incidence among AGYW from each netsim object,
  # across the stochastic ensemble -> median + 95% simulation interval.
  list(
    infections_averted = NA_real_,
    pct_averted        = NA_real_,
    irr_reduction      = NA_real_,
    nnt                = NA_real_
  )
}

# ---- Reporting -------------------------------------------------------------
# Build a tidy data.frame: effect x reach x outcome (median [lo, hi]).
# Headline figure: % infections averted over 5 / 10 yr across the grid,
# with the effect-size range shown as the dominant uncertainty band.

message("05_analysis.R is a scaffold — wire to scenario_runs.rds once runs exist.")
