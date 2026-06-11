## 30_timetrend.R — time-trend calibration (the standard SA-HIV-model approach).
## Seed HIV ~1990 at low prevalence, grow the epidemic, ramp ART from ~2004, and
## fit the simulated prevalence TRAJECTORY to Thembisa 1990-2022 (not a single
## equilibrium cross-section). Fitting the growth rate forces the model off the
## near-critical threshold and pins down connectivity + beta jointly.
## Run: Rscript R/30_timetrend.R

source(file.path(
  tryCatch({a<-commandArgs(FALSE);f<-sub("^--file=","",a[grep("^--file=",a)])
            if(length(f)) dirname(normalizePath(f)) else "."}, error=function(e) "."),
  "model_components.R"))
suppressMessages(library(ggplot2))
`%||%` <- function(a,b) if (is.null(a)||length(a)==0) b else a

# ---- Thembisa target trajectory (extracted from v5.0 workbook) -------------
THEMBISA <- data.frame(
  year = seq(1990, 2022, 2),
  adult_15_49 = c(0.0076,0.0206,0.0426,0.0714,0.101,0.1264,0.145,0.1573,0.1649,
                  0.1711,0.1768,0.1807,0.1837,0.1855,0.1851,0.1818,0.1758),
  women_15_24 = c(0.0083,0.0243,0.0541,0.0936,0.1288,0.1514,0.1603,0.1591,0.1526,
                  0.1448,0.1372,0.1281,0.1202,0.1143,0.108,0.0996,0.0897))

START_YEAR <- 1990

# ---- Time-varying ART scale-up: 0 before 2004, ramps to full by 2014 -------
art_scale <- function(at, p) {
  yr <- p$sim.start.year + (at - 1) / 52
  s0 <- p$art.start.year; s1 <- p$art.full.year
  if (yr <= s0) return(0)
  if (yr >= s1) return(1)
  (yr - s0) / (s1 - s0)
}

# ---- Time-aware cascade: treatment side scales with ART roll-out -----------
cascade_tt <- function(dat, at) {
  asc <- art_scale(at, dat$param)   # 0..1
  active <- get_attr(dat,"active"); status <- get_attr(dat,"status"); stage <- get_attr(dat,"stage")
  diag.status <- get_attr(dat,"diag.status"); art.status <- get_attr(dat,"art.status")
  vl.supp <- get_attr(dat,"vl.supp"); art.time <- get_attr(dat,"art.time")
  test.rate <- get_param(dat,"test.rate"); aids.dx.rate <- get_param(dat,"aids.dx.rate")
  linkage.rate <- get_param(dat,"linkage.rate")*asc; art.reinit.rate <- get_param(dat,"art.reinit.rate")*asc
  suppression.rate <- get_param(dat,"suppression.rate")*asc; art.disc.rate <- get_param(dat,"art.disc.rate")
  diag0<-diag.status; art0<-art.status; supp0<-vl.supp; is_inf<-active==1 & status=="i"
  idsu<-which(is_inf & diag0==0)
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
  dat<-set_epi(dat,"art.scale",at,asc)
  dat
}

run_tt <- function(param, ests, N, nsteps, nsims=1, i.num) {
  ctrl <- control.net(type=NULL, nsims=nsims, ncores=1, nsteps=nsteps,
    tergmLite=TRUE, resimulate.network=TRUE,
    aging.FUN=aging_mod, infection.FUN=infect_track, progress.FUN=progress,
    cascade.FUN=cascade_tt, prep.FUN=prep_agyw, departures.FUN=dfunc,
    arrivals.FUN=afunc_hetage, verbose=FALSE)
  netsim(list(ests$est_main, ests$est_cas), param, init.net(i.num=i.num), ctrl)
}

# overall 15-49 + women 15-24 prevalence per year
traj_prev <- function(sim, start_year, nyears) {
  df <- tryCatch(as.data.frame(sim, out="mean"), error=function(e) as.data.frame(sim))
  bands <- list(f_15_19="f_15_19", f_20_24="f_20_24")  # women 15-24 = mean of two
  out <- data.frame()
  for (y in 0:(nyears-1)) {
    step <- min((y*52)+26, nrow(df))  # mid-year
    w <- mean(c(df$prev.f_15_19[step], df$prev.f_20_24[step]), na.rm=TRUE)
    out <- rbind(out, data.frame(year=start_year+y, women_15_24=w))
  }
  out
}

# ---- Run: raise concurrency for robust growth; seed 0.8% in 1990 -----------
set.seed(30)
N <- 2000; NYEARS <- 33; nsteps <- NYEARS*52
# higher concurrency (casual right-tail) so the epidemic grows robustly off-threshold
ests <- build_hetage_network(N, age_gap=5, deg_main=0.5, deg_cas=0.35,
                             conc_main=0.10, conc_cas=0.30, mix_main=8, mix_cas=9)

run_one <- function(beta) {
  p <- hetage_param(inf.prob.act=beta, age.gap=5,
                    agyw.susc.15_19=2.0, agyw.susc.20_24=1.5,
                    sim.start.year=START_YEAR, art.start.year=2004, art.full.year=2014)
  sim <- run_tt(p, ests, N, nsteps, nsims=2, i.num=round(0.008*N))
  traj_prev(sim, START_YEAR, NYEARS)
}

res <- list()
for (beta in c(0.004, 0.006, 0.008)) {
  tr <- run_one(beta); tr$beta <- beta; res[[as.character(beta)]] <- tr
  pk <- max(tr$women_15_24, na.rm=TRUE)
  cat(sprintf("beta=%.3f: women15-24 1995=%.3f 2002=%.3f 2022=%.3f (peak %.3f)\n",
      beta, tr$women_15_24[tr$year==1995]%||%NA, tr$women_15_24[tr$year==2002]%||%NA,
      tr$women_15_24[tr$year==2022]%||%NA, pk))
}

allr <- do.call(rbind, res)
p <- ggplot() +
  geom_line(data=THEMBISA, aes(year, women_15_24), colour="black", linewidth=1.2) +
  geom_point(data=THEMBISA, aes(year, women_15_24), colour="black", size=2) +
  geom_line(data=allr, aes(year, women_15_24, colour=factor(beta)), linewidth=0.9) +
  scale_y_continuous(labels=scales::percent) +
  scale_colour_brewer(palette="Set1", name="inf.prob.act") +
  labs(title="Time-trend calibration: simulated vs Thembisa AGYW prevalence 1990-2022",
       subtitle="Black = Thembisa women 15-24 target; coloured = model. Fitting the CURVE, not a point.",
       x="Year", y="HIV prevalence, women 15-24") +
  theme_minimal(base_size=12)
ggsave("results/timetrend_fit.png", p, width=9, height=5, dpi=140)
saveRDS(res, "results/timetrend_pass1.rds")
cat("\nWrote results/timetrend_fit.png\n")
