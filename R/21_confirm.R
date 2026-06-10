## 21_confirm.R — confirmation run at larger N + multiple sims (noise-reduced),
## with age-graded AGYW susceptibility (15-19 > 20-24). Tests whether the youngest
## band reaches target once it carries the highest per-contact susceptibility.
## Run: Rscript R/21_confirm.R

source(file.path(
  tryCatch({a<-commandArgs(FALSE);f<-sub("^--file=","",a[grep("^--file=",a)])
            if(length(f)) dirname(normalizePath(f)) else "."}, error=function(e) "."),
  "model_components.R"))
`%||%` <- function(a,b) if (is.null(a)||length(a)==0) b else a

TARGETS <- c(f_15_19=0.054, f_20_24=0.124, m_25_29=0.071,
             m_30_34=0.120, m_35_39=0.181, m_40_44=0.224)
# Production-N calibration: N=2000 runs hotter than N=1200 (finite-size near
# threshold), so re-tune beta DOWN at fixed graded susceptibility (15-19=3.5,
# 20-24=2.5, which landed the youngest band at N=2000).
N <- 2000; nsteps <- 33*52; nsims <- 3
SUSC15 <- 3.5; SUSC20 <- 2.5

set.seed(21)
ests <- build_hetage_network(N, age_gap=5, deg_main=0.5, deg_cas=0.35, mix_main=8, mix_cas=9)
distance <- function(sp) sqrt(mean((sapply(names(TARGETS), function(k) sp[[k]] %||% NA) - TARGETS)^2, na.rm=TRUE))

BETAS <- c(0.0040, 0.0045, 0.0050)
best <- NULL
for (b in BETAS) {
  p <- hetage_param(inf.prob.act=b, age.gap=5,
                    agyw.susc.15_19=SUSC15, agyw.susc.20_24=SUSC20)
  sim <- run_hetage(p, ests, N, nsteps, nsims)
  sp <- equil_prev(sim, 52); d <- distance(sp)
  cat(sprintf("beta=%.4f (susc 3.5/2.5)  RMSE=%.3f | f15-19=%.3f f20-24=%.3f m30-34=%.3f m35-39=%.3f m40-44=%.3f\n",
      b, d, sp$f_15_19%||%NA, sp$f_20_24%||%NA, sp$m_30_34%||%NA, sp$m_35_39%||%NA, sp$m_40_44%||%NA))
  if (is.null(best) || d < best$rmse) best <- list(susc=c(SUSC15,SUSC20), prev=sp, rmse=d, beta=b)
}
cat(sprintf("\n=== Best (N=%d, %d sims): beta=%.4f, susc 15-19=%.1f / 20-24=%.1f (RMSE=%.3f) ===\n",
            N, nsims, best$beta, best$susc[1], best$susc[2], best$rmse))
cat("  band      target   simulated\n")
for (k in names(TARGETS)) cat(sprintf("  %-8s  %.3f    %.3f\n", k, TARGETS[k], best$prev[[k]]%||%NA))
saveRDS(list(best=best, all=CANDS), "results/calibration_confirm.rds")
saveRDS(setNames(list(list(beta=best$beta, susc=best$susc, prev=best$prev, rmse=best$rmse)), "best"),
        "results/calibration_pass7.rds")  # for plot_calibration.R
cat("\nSaved results/calibration_confirm.rds\n")
