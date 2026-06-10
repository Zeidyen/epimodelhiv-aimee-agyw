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

# ---- Settings (COARSE first pass) ------------------------------------------
N       <- 1500
BURN_YR <- 25
nsteps  <- BURN_YR * 52
nsims   <- 1
GRID    <- c(0.0015, 0.0025, 0.0035, 0.0045, 0.0060)   # inf.prob.act candidates

cat(sprintf("Calibration: N=%d, burn-in=%dyr (%d steps), %d inf.prob.act values\n\n",
            N, BURN_YR, nsteps, length(GRID)))

set.seed(20)
ests <- build_hetage_network(N, age_gap = 5, deg_main = 0.5, deg_cas = 0.35)

distance <- function(sim_prev) {
  s <- sapply(names(TARGETS), function(k) if (!is.null(sim_prev[[k]])) sim_prev[[k]] else NA)
  sqrt(mean((s - TARGETS)^2, na.rm = TRUE))   # RMSE across bands
}

results <- list()
for (b in GRID) {
  p <- hetage_param(inf.prob.act = b, age.gap = 5,
                    chatbot.reach = 0, chatbot.test.rr = 1, chatbot.prep.rr = 1)
  sim <- run_hetage(p, ests, N, nsteps, nsims)
  sp  <- equil_prev(sim, tail_steps = 52)
  d   <- distance(sp)
  results[[as.character(b)]] <- list(beta = b, prev = sp, rmse = d)
  cat(sprintf("inf.prob.act=%.4f  RMSE=%.3f  | f15-19=%.3f f20-24=%.3f m30-34=%.3f m35-39=%.3f\n",
              b, d, sp$f_15_19 %||% NA, sp$f_20_24 %||% NA, sp$m_30_34 %||% NA, sp$m_35_39 %||% NA))
}

best <- results[[which.min(sapply(results, function(r) r$rmse))]]
cat(sprintf("\n=== Best fit: inf.prob.act=%.4f (RMSE=%.3f) ===\n", best$beta, best$rmse))
cat("  band      target   simulated\n")
for (k in names(TARGETS))
  cat(sprintf("  %-8s  %.3f    %.3f\n", k, TARGETS[k], best$prev[[k]] %||% NA))
saveRDS(results, file.path(".", "results", "calibration_pass1.rds"))
cat("\nSaved results/calibration_pass1.rds\n")
