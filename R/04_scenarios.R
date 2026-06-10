# 04_scenarios.R
# Run the effect x reach scenario grid against the calibrated baseline.

library(EpiModel)
# library(EpiModelHIV)

# est        <- readRDS("results/netest.rds")
# param_base <- readRDS("results/param_baseline.rds")
ip <- readRDS("results/intervention_params.rds")

# ---- Scenario grid ---------------------------------------------------------
# baseline + {conservative, central, optimistic} x {10%, 30%, 50% reach}
scenarios <- list(baseline = list(effect = "none", reach = 0))
for (eff in names(ip$intervention_grid)) {
  for (r in ip$reach) {
    scenarios[[sprintf("%s_reach%02d", eff, round(r * 100))]] <-
      list(effect = eff, reach = r)
  }
}

run_scenario <- function(sc) {
  # TODO: copy param_base; if sc$effect != "none", multiply the testing/PrEP
  # parameters by apply_reach(intervention_grid[[sc$effect]]$..., sc$reach);
  # then netsim() over the analysis horizon (e.g. 10 yr).
  #
  # param <- modify_params(param_base, sc, ip)
  # control <- control_het(nsteps = 52 * 10, nsims = 32)
  # netsim(est, param, init, control)
  NULL
}

results <- lapply(scenarios, run_scenario)
saveRDS(results, "results/scenario_runs.rds")
message(sprintf("04_scenarios.R: %d scenarios defined (scaffold).", length(scenarios)))
