## 31_production_calib.R — PRODUCTION time-trend calibration.
## Larger N + multi-sim (smooth AGYW band), fine beta sweep around 0.004, fit to
## the FULL Thembisa trajectory (women 15-24 AND adult 15-49). Long-running.
## Run: Rscript R/31_production_calib.R
##
## Regime located in R/30: acts=5/2 (robust endemicity), mix=8, graded susc 2.0/1.5.

source(file.path(
  tryCatch({a<-commandArgs(FALSE);f<-sub("^--file=","",a[grep("^--file=",a)])
            if(length(f)) dirname(normalizePath(f)) else "."}, error=function(e) "."),
  "model_components.R"))
suppressMessages(library(ggplot2))
`%||%` <- function(a,b) if (is.null(a)||length(a)==0) b else a

# ---- Thembisa targets (v5.0): both trajectories -----------------------------
THEMBISA <- data.frame(
  year = seq(1990, 2022, 2),
  adult_15_49 = c(0.0076,0.0206,0.0426,0.0714,0.101,0.1264,0.145,0.1573,0.1649,
                  0.1711,0.1768,0.1807,0.1837,0.1855,0.1851,0.1818,0.1758),
  women_15_24 = c(0.0083,0.0243,0.0541,0.0936,0.1288,0.1514,0.1603,0.1591,0.1526,
                  0.1448,0.1372,0.1281,0.1202,0.1143,0.108,0.0996,0.0897))
START_YEAR <- 1990

art_scale <- function(at, p) {
  yr <- p$sim.start.year + (at-1)/52; s0<-p$art.start.year; s1<-p$art.full.year
  if (yr<=s0) return(0); if (yr>=s1) return(1); (yr-s0)/(s1-s0)
}
cascade_tt <- function(dat, at) {
  asc <- art_scale(at, dat$param)
  active<-get_attr(dat,"active"); status<-get_attr(dat,"status"); stage<-get_attr(dat,"stage")
  diag.status<-get_attr(dat,"diag.status"); art.status<-get_attr(dat,"art.status")
  vl.supp<-get_attr(dat,"vl.supp"); art.time<-get_attr(dat,"art.time")
  test.rate<-get_param(dat,"test.rate"); aids.dx.rate<-get_param(dat,"aids.dx.rate")
  linkage.rate<-get_param(dat,"linkage.rate")*asc; art.reinit.rate<-get_param(dat,"art.reinit.rate")*asc
  suppression.rate<-get_param(dat,"suppression.rate")*asc; art.disc.rate<-get_param(dat,"art.disc.rate")
  diag0<-diag.status; art0<-art.status; supp0<-vl.supp; is_inf<-active==1 & status=="i"
  idsu<-which(is_inf&diag0==0)
  if(length(idsu)){r<-ifelse(!is.na(stage[idsu])&stage[idsu]=="aids",aids.dx.rate,test.rate)
    nd<-idsu[rbinom(length(idsu),1,r)==1]; if(length(nd)) diag.status[nd]<-1L}
  iln<-which(is_inf&diag0==1&art0==0&is.na(art.time))
  if(length(iln)){h<-iln[rbinom(length(iln),1,linkage.rate)==1]; if(length(h)){art.status[h]<-1L;art.time[h]<-at}}
  ilr<-which(is_inf&diag0==1&art0==0&!is.na(art.time))
  if(length(ilr)){h<-ilr[rbinom(length(ilr),1,art.reinit.rate)==1]; if(length(h)){art.status[h]<-1L;art.time[h]<-at}}
  isu<-which(is_inf&art0==1&supp0==0)
  if(length(isu)){h<-isu[rbinom(length(isu),1,suppression.rate)==1]; if(length(h)) vl.supp[h]<-1L}
  idc<-which(is_inf&art0==1)
  if(length(idc)){h<-idc[rbinom(length(idc),1,art.disc.rate)==1]; if(length(h)){art.status[h]<-0L;vl.supp[h]<-0L}}
  dat<-set_attr(dat,"diag.status",diag.status); dat<-set_attr(dat,"art.status",art.status)
  dat<-set_attr(dat,"vl.supp",vl.supp); dat<-set_attr(dat,"art.time",art.time)
  dat
}
run_tt <- function(param, ests, N, nsteps, nsims) {
  ctrl <- control.net(type=NULL, nsims=nsims, ncores=1, nsteps=nsteps,
    tergmLite=TRUE, resimulate.network=TRUE,
    aging.FUN=aging_mod, infection.FUN=infect_track, progress.FUN=progress,
    cascade.FUN=cascade_tt, prep.FUN=prep_agyw, departures.FUN=dfunc,
    arrivals.FUN=afunc_hetage, verbose=FALSE)
  netsim(list(ests$est_main, ests$est_cas), param, init.net(i.num=round(0.008*N)), ctrl)
}
# both trajectories per year (mid-year, averaged across sims)
traj2 <- function(sim, nyears) {
  df <- tryCatch(as.data.frame(sim, out="mean"), error=function(e) as.data.frame(sim))
  out <- data.frame()
  for (y in 0:(nyears-1)) {
    s <- min(y*52+26, nrow(df))
    w <- mean(c(df$prev.f_15_19[s], df$prev.f_20_24[s]), na.rm=TRUE)
    a <- df$prev.adult_15_49[s] %||% NA
    out <- rbind(out, data.frame(year=START_YEAR+y, women_15_24=w, adult_15_49=a))
  }
  out
}
# RMSE vs Thembisa at the 2-yearly target points (both series)
traj_rmse <- function(tr) {
  m <- merge(THEMBISA, tr, by="year", suffixes=c(".t",".s"))
  ew <- (m$women_15_24.s - m$women_15_24.t)
  ea <- (m$adult_15_49.s - m$adult_15_49.t)
  sqrt(mean(c(ew^2, ea^2), na.rm=TRUE))
}

# ---- Production settings ----------------------------------------------------
set.seed(31)
N <- 3000; NYEARS <- 33; nsteps <- NYEARS*52; nsims <- 3
ests <- build_hetage_network(N, age_gap=5, deg_main=0.5, deg_cas=0.35,
                             conc_main=0.04, conc_cas=0.10, mix_main=8, mix_cas=9)
BETAS <- c(0.0035, 0.0040, 0.0045, 0.0050)

res <- list()
for (b in BETAS) {
  p <- hetage_param(inf.prob.act=b, age.gap=5, acts.main=5, acts.casual=2,
                    agyw.susc.15_19=2.0, agyw.susc.20_24=1.5,
                    sim.start.year=START_YEAR, art.start.year=2004, art.full.year=2014)
  sim <- run_tt(p, ests, N, nsteps, nsims)
  tr <- traj2(sim, NYEARS); tr$beta <- b
  rm <- traj_rmse(tr); res[[as.character(b)]] <- list(beta=b, tr=tr, rmse=rm)
  cat(sprintf("beta=%.4f trajRMSE=%.3f | AGYW peak=%.3f 2022=%.3f | adult peak=%.3f 2022=%.3f\n",
      b, rm, max(tr$women_15_24,na.rm=TRUE), tr$women_15_24[tr$year==2022]%||%NA,
      max(tr$adult_15_49,na.rm=TRUE), tr$adult_15_49[tr$year==2022]%||%NA))
}
best <- res[[which.min(sapply(res, function(r) r$rmse))]]
cat(sprintf("\n=== BEST: beta=%.4f (trajRMSE=%.3f) ===\n", best$beta, best$rmse))
saveRDS(res, "results/production_calib.rds")

# ---- Plot both trajectories for the best beta ------------------------------
allr <- do.call(rbind, lapply(res, function(r) r$tr))
p <- ggplot() +
  geom_line(data=THEMBISA, aes(year, women_15_24), colour="black", linewidth=1.1) +
  geom_line(data=THEMBISA, aes(year, adult_15_49), colour="grey40", linewidth=1.1, linetype="dashed") +
  geom_line(data=allr, aes(year, women_15_24, colour=factor(beta)), linewidth=0.8) +
  scale_y_continuous(labels=scales::percent) +
  scale_colour_brewer(palette="Set1", name="inf.prob.act") +
  labs(title="Production time-trend calibration (N=3000, 3 sims)",
       subtitle="Black=Thembisa women 15-24; grey dashed=adult 15-49; coloured=model (women 15-24)",
       x="Year", y="HIV prevalence") + theme_minimal(base_size=12)
ggsave("results/production_fit.png", p, width=9, height=5, dpi=140)
cat("Wrote results/production_fit.png\n")
