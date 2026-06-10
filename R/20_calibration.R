## 20_calibration.R
## Calibrate the baseline (no-chatbot) model to SA targets (Thembisa v5.0, 2022).
## Free parameter swept here: inf.prob.act (per-act transmission = epidemic level).
## age.gap fixed at 5 (literature); degrees set so simulated past-year partner
## count ~ 1.71 (Aimee). Network mixing / age-gradient tuning is a later pass.
##
## Run from repo root:  Rscript R/20_calibration.R
## (Coarse settings for a first pass; scale N/burn_in/grid up for production.)

source(file.path(
  tryCatch({a<-commandArgs(FALSE);f<-sub("^--file=","",a[grep("^--file=",a)])
            if(length(f)) dirname(normalizePath(f)) else "."}, error=function(e) "."),
  "model_components.R"))

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a

# ---- Calibration targets (Thembisa v5.0, 2022) -----------------------------
TARGETS <- c(f_15_19 = 0.054, f_20_24 = 0.124,
             m_25_29 = 0.071, m_30_34 = 0.120,
             m_35_39 = 0.181, m_40_44 = 0.224)

# ---- Settings (pass 4: JOINT beta x AGYW-susceptibility grid) ---------------
# Pass 3 showed susc at fixed beta=0.008 runs away (AGYW infect men -> feedback ->
# whole epidemic explodes). beta and susc are coupled: beta = overall level,
# susc = women-vs-men ratio. Grid jointly (lower beta to offset the susc boost).
N       <- 1000
BURN_YR <- 35
nsteps  <- BURN_YR * 52
nsims   <- 1
BETA_GRID <- c(0.0045, 0.0055, 0.0065)
SUSC_GRID <- c(1.5, 2.0, 2.5)

cat(sprintf("Calibration: N=%d, burn-in=%dyr (%d steps), %d inf.prob.act values\n\n",
            N, BURN_YR, nsteps, length(GRID)))

set.seed(20)
ests <- build_hetage_network(N, age_gap = 5, deg_main = 0.5, deg_cas = 0.35)

distance <- function(sim_prev) {
  s <- sapply(names(TARGETS), function(k) if (!is.null(sim_prev[[k]])) sim_prev[[k]] else NA)
  sqrt(mean((s - TARGETS)^2, na.rm = TRUE))   # RMSE across bands
}

results <- list()
for (b in BETA_GRID) for (s in SUSC_GRID) {
  p <- hetage_param(inf.prob.act = b, age.gap = 5, agyw.susc.mult = s,
                    chatbot.reach = 0, chatbot.test.rr = 1, chatbot.prep.rr = 1)
  sim <- run_hetage(p, ests, N, nsteps, nsims)
  sp  <- equil_prev(sim, tail_steps = 52)
  d   <- distance(sp)
  results[[sprintf("b%.4f_s%.1f", b, s)]] <- list(beta = b, susc = s, prev = sp, rmse = d)
  cat(sprintf("beta=%.4f susc=%.1f  RMSE=%.3f  | f15-19=%.3f f20-24=%.3f m30-34=%.3f m35-39=%.3f\n",
              b, s, d, sp$f_15_19 %||% NA, sp$f_20_24 %||% NA, sp$m_30_34 %||% NA, sp$m_35_39 %||% NA))
}

best <- results[[which.min(sapply(results, function(r) r$rmse))]]
cat(sprintf("\n=== Best fit: beta=%.4f, agyw.susc.mult=%.1f (RMSE=%.3f) ===\n", best$beta, best$susc, best$rmse))
cat("  band      target   simulated\n")
for (k in names(TARGETS))
  cat(sprintf("  %-8s  %.3f    %.3f\n", k, TARGETS[k], best$prev[[k]] %||% NA))
saveRDS(results, file.path(".", "results", "calibration_pass4.rds"))
cat("\nSaved results/calibration_pass4.rds\n")
