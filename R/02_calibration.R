# 02_calibration.R
# Calibrate the baseline HIV epidemic (no chatbot) to SA AGYW targets.
# Consumes results/netest.rds from 01_network_estimation.R.
#
# Goal: parameter set that reproduces observed AGYW HIV prevalence/incidence,
# ART coverage, and baseline PrEP/testing BEFORE any intervention is applied.

library(EpiModel)
# library(EpiModelHIV)

# est <- readRDS("results/netest.rds")

# ---- 1. Baseline epidemic parameters ---------------------------------------
# TODO: per-act transmission probability, disease progression (acute/chronic/AIDS),
# ART initiation & viral suppression, baseline HIV-testing rate, baseline PrEP.
# param <- param_het(   # EpiModelHIV SSA heterosexual param constructor
#   ...                 # TODO
# )
# init  <- init_het(...)    # seed prevalence by age/sex     # TODO
# control <- control_het(nsteps = 52 * 30, nsims = 16)        # ~30 yr burn-in

# ---- 2. Run + compare to targets -------------------------------------------
# sim <- netsim(est, param, init, control)
# Compare simulated AGYW incidence/prevalence to calibration/targets.md.

# ---- 3. Calibration loop ---------------------------------------------------
# Adjust the few free parameters (e.g. transmission scaler, testing/PrEP baseline)
# until simulated targets match. Method: grid / ABC / manual.
# TODO: implement target comparison + acceptance criterion.

# saveRDS(param, "results/param_baseline.rds")
message("02_calibration.R is a scaffold — calibrate to calibration/targets.md.")
