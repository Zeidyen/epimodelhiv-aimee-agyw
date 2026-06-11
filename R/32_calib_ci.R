## 32_calib_ci.R — calibrated baseline with CREDIBLE INTERVALS, fit to
## PREVALENCE *and* INCIDENCE, plotted PER BAND (one panel each).
## Multi-sim (stochastic CIs) at the calibrated parameter set. Demographic
## burn-in 1965-1990 then HIV seeded 1990; run to 2022.
## Run: Rscript R/32_calib_ci.R

source(file.path(
  tryCatch({a<-commandArgs(FALSE);f<-sub("^--file=","",a[grep("^--file=",a)])
            if(length(f)) dirname(normalizePath(f)) else "."}, error=function(e) "."),
  "model_components.R"))
source(file.path(dirname(normalizePath(sub("^--file=","",commandArgs(FALSE)[grep("^--file=",commandArgs(FALSE))]))), "calibrated_params.R"))
suppressMessages({library(ggplot2); library(tidyr)})
`%||%` <- function(a,b) if (is.null(a)||length(a)==0) b else a

# ---- Thembisa targets: prevalence (women, adult) + incidence (women) -------
TH_PREV <- data.frame(year=seq(1990,2022,2),
  women_15_24=c(0.0083,0.0243,0.0541,0.0936,0.1288,0.1514,0.1603,0.1591,0.1526,
                0.1448,0.1372,0.1281,0.1202,0.1143,0.108,0.0996,0.0897),
  adult_15_49=c(0.0076,0.0206,0.0426,0.0714,0.101,0.1264,0.145,0.1573,0.1649,
                0.1711,0.1768,0.1807,0.1837,0.1855,0.1851,0.1818,0.1758))
TH_INC <- data.frame(year=seq(1990,2020,3),
  women_15_24=c(0.0084,0.0240,0.0380,0.0411,0.0367,0.0321,0.0287,0.0233,0.0193,0.0150,0.0112))

CP <- CALIBRATED
FIRST_YEAR <- CP$first.year; START_YEAR <- CP$seed.year
SEED_TICK <- CP$burnin.year*52 + 1

art_scale <- function(at, p) {
  yr <- p$first.year+(at-1)/52; s0<-p$art.start.year; s1<-p$art.full.year
  if (yr<=s0) return(0); if (yr>=s1) return(1); (yr-s0)/(s1-s0)
}
cascade_tt <- function(dat, at) {
  p <- dat$param                                    # inline art_scale (worker-safe)
  yr <- p$first.year + (at-1)/52; s0 <- p$art.start.year; s1 <- p$art.full.year
  asc <- if (yr<=s0) 0 else if (yr>=s1) 1 else (yr-s0)/(s1-s0)
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

# ---- Run multi-sim ---------------------------------------------------------
set.seed(32)
N <- 2500; NSIMS <- 20; nsteps <- (CP$burnin.year + 33)*52
ests <- build_hetage_network(N, age_gap=CP$age.gap, deg_main=CP$deg_main, deg_cas=CP$deg_cas,
                             conc_main=CP$conc_main, conc_cas=CP$conc_cas, mix_main=CP$mix_main, mix_cas=CP$mix_cas)
p <- hetage_param(inf.prob.act=CP$inf.prob.act, age.gap=CP$age.gap, acts.main=CP$acts.main, acts.casual=CP$acts.casual,
                  agyw.susc.15_19=CP$agyw.susc.15_19, agyw.susc.20_24=CP$agyw.susc.20_24,
                  seed.tick=SEED_TICK, seed.prev=CP$seed.prev,
                  first.year=FIRST_YEAR, art.start.year=CP$art.start.year, art.full.year=CP$art.full.year)
ctrl <- control.net(type=NULL, nsims=NSIMS, ncores=10, nsteps=nsteps, tergmLite=TRUE, resimulate.network=TRUE,
  aging.FUN=aging_mod, infection.FUN=infect_track, progress.FUN=progress,
  cascade.FUN=cascade_tt, prep.FUN=prep_agyw, departures.FUN=dfunc, arrivals.FUN=afunc_hetage, verbose=FALSE)
cat(sprintf("Running %d sims, N=%d, %d steps...\n", NSIMS, N, nsteps))
sim <- netsim(list(ests$est_main, ests$est_cas), p, init.net(i.num=0), ctrl)

# ---- Per-sim per-year series, then median + 95% CI -------------------------
df <- as.data.frame(sim)   # has 'sim' column
yr_step <- function(yr) (yr - FIRST_YEAR)*52 + 26
# annual AGYW incidence per 100 PY = 52 * sum(new)/sum(susceptible person-steps)
collect <- function(series_fun, years) {
  m <- sapply(years, function(yr){
    sapply(sort(unique(df$sim)), function(s){
      d <- df[df$sim==s,]; series_fun(d, yr)
    })
  })  # rows=sims, cols=years
  data.frame(year=years,
             med=apply(m,2,median,na.rm=TRUE),
             lo=apply(m,2,quantile,0.025,na.rm=TRUE),
             hi=apply(m,2,quantile,0.975,na.rm=TRUE))
}
prev_women <- function(d,yr){ s<-yr_step(yr); if(s>nrow(d)) return(NA); mean(c(d$prev.f_15_19[s],d$prev.f_20_24[s]),na.rm=TRUE) }
prev_adult <- function(d,yr){ s<-yr_step(yr); if(s>nrow(d)) return(NA); d$prev.adult_15_49[s] }
inc_women  <- function(d,yr){ s0<-yr_step(yr)-26; s1<-s0+51; if(s1>nrow(d)||s0<1) return(NA)
  ni<-sum(d$incid.agyw[s0:s1],na.rm=TRUE)       # new AGYW infections this year
  pw<-sum(d$agyw.py[s0:s1],na.rm=TRUE)          # susceptible person-WEEKS
  if(pw<=0) NA else 52*ni/pw }                  # incidence per PY (fraction; *100 = per 100 PY)

yrs <- seq(START_YEAR,2022)
PW <- collect(prev_women, yrs); PW$panel <- "Prevalence: women 15-24"
PA <- collect(prev_adult, yrs); PA$panel <- "Prevalence: adult 15-49"
IW <- collect(inc_women,  yrs); IW$panel <- "Incidence: women 15-24 (per 100 PY)"
model <- rbind(PW,PA,IW)

# targets in long form, matched to panels
tgt <- rbind(
  data.frame(year=TH_PREV$year, val=TH_PREV$women_15_24, panel="Prevalence: women 15-24"),
  data.frame(year=TH_PREV$year, val=TH_PREV$adult_15_49, panel="Prevalence: adult 15-49"),
  data.frame(year=TH_INC$year,  val=TH_INC$women_15_24,  panel="Incidence: women 15-24 (per 100 PY)"))

saveRDS(list(model=model, tgt=tgt), "results/calib_ci.rds")

pl <- ggplot(model, aes(year)) +
  geom_ribbon(aes(ymin=lo, ymax=hi), fill="#c0392b", alpha=0.2) +
  geom_line(aes(y=med), colour="#c0392b", linewidth=0.9) +
  geom_line(data=tgt, aes(y=val), colour="black", linewidth=1) +
  geom_point(data=tgt, aes(y=val), colour="black", size=1.3) +
  facet_wrap(~panel, scales="free_y") +
  scale_y_continuous(labels=scales::percent) +
  labs(title="Calibrated baseline with 95% simulation interval (N=2500, 20 sims)",
       subtitle="Black = Thembisa target; red = model median + 95% interval. One panel per series.",
       x="Year", y=NULL) + theme_minimal(base_size=11)
ggsave("results/calib_ci.png", pl, width=11, height=4, dpi=140)
cat("Wrote results/calib_ci.png\n")
