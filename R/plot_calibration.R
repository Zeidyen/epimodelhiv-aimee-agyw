## plot_calibration.R — visualise calibration fit + epidemic trajectory.
## Usage: Rscript R/plot_calibration.R [results/calibration_passX.rds]
suppressMessages(library(ggplot2))
`%||%` <- function(a,b) if (is.null(a)||length(a)==0) b else a
args <- commandArgs(TRUE)
rds <- if (length(args)) args[1] else "results/calibration_pass1.rds"
outdir <- "results"; dir.create(outdir, showWarnings = FALSE)

TARGETS <- c(f_15_19=0.054, f_20_24=0.124, m_25_29=0.071,
             m_30_34=0.120, m_35_39=0.181, m_40_44=0.224)
band_lab <- c(f_15_19="Women\n15-19", f_20_24="Women\n20-24", m_25_29="Men\n25-29",
              m_30_34="Men\n30-34", m_35_39="Men\n35-39", m_40_44="Men\n40-44")
ord <- names(TARGETS)

# ---- 1. Calibration fit: simulated vs target by age/sex band ---------------
res <- readRDS(rds)
key <- if (!is.null(res[[1]]$beta)) "beta" else "susc"
best <- res[[which.min(sapply(res, function(r) r$rmse))]]
rows <- do.call(rbind, lapply(names(TARGETS), function(k)
  data.frame(band=k, target=TARGETS[k], sim=best$prev[[k]] %||% NA)))
rows$band <- factor(rows$band, levels=ord, labels=band_lab[ord])

p1 <- ggplot(rows, aes(x=band)) +
  geom_col(aes(y=target), fill="grey80", width=0.7) +
  geom_point(aes(y=sim), colour="#c0392b", size=4) +
  geom_segment(aes(xend=band, y=target, yend=sim), colour="#c0392b", linewidth=0.4) +
  scale_y_continuous(labels=scales::percent) +
  labs(title="Model calibration: simulated HIV prevalence vs Thembisa 2022 targets",
       subtitle=sprintf("Best fit %s=%s (RMSE=%.3f)  |  bars=target, red=simulated",
                        key, best[[key]], best$rmse),
       x=NULL, y="HIV prevalence") +
  theme_minimal(base_size=12)
ggsave(file.path(outdir,"fit_by_band.png"), p1, width=8, height=4.5, dpi=140)

# ---- 2. Epidemic trajectory (from diagnostic runs) -------------------------
traj <- read.csv(text="beta,year,prev_all,prev_AGYW,prev_OW
0.006,10,0.120,0.037,0.193
0.006,15,0.100,0.026,0.177
0.006,20,0.077,0.009,0.147
0.006,25,0.058,0.008,0.107
0.015,10,0.298,0.111,0.497
0.015,15,0.363,0.194,0.565
0.015,20,0.445,0.313,0.628
0.015,25,0.456,0.209,0.707
0.030,10,0.560,0.353,0.784
0.030,15,0.579,0.412,0.830
0.030,20,0.606,0.428,0.863
0.030,25,0.691,0.555,0.885")
traj$beta <- factor(traj$beta)
p2 <- ggplot(traj, aes(year, prev_all, colour=beta)) +
  geom_line(linewidth=1) + geom_point(size=2) +
  geom_hline(yintercept=0.127, linetype="dashed", colour="grey40") +
  annotate("text", x=11, y=0.145, label="SA national ~12.7%", size=3, colour="grey40") +
  scale_y_continuous(labels=scales::percent) +
  scale_colour_brewer(palette="Set1", name="inf.prob.act") +
  labs(title="Why prevalence collapsed: epidemic trajectory by transmission level",
       subtitle="beta=0.006 fades (R0~1); 0.015 hyperendemic; target near ~0.008",
       x="Year (burn-in)", y="Overall HIV prevalence") +
  theme_minimal(base_size=12)
ggsave(file.path(outdir,"trajectory.png"), p2, width=8, height=4.5, dpi=140)

cat("Wrote results/fit_by_band.png and results/trajectory.png\n")
