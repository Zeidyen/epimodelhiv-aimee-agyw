## 41_trajectories.R — per-year scenario trajectories for two figures:
##  (A) incidence FAN plot: national AGYW new infections/yr, baseline vs chatbot
##  (B) MECHANISM plot: PrEP coverage + diagnosed fraction among AGYW over time
## Paired (per-sim shared seed), parallel on the M4 Max. Run: Rscript R/41_trajectories.R

source(file.path(
  tryCatch({a<-commandArgs(FALSE);f<-sub("^--file=","",a[grep("^--file=",a)])
            if(length(f)) dirname(normalizePath(f)) else "."}, error=function(e) "."),
  "model_components.R"))
source(file.path(dirname(normalizePath(sub("^--file=","",commandArgs(FALSE)[grep("^--file=",commandArgs(FALSE))]))), "calibrated_params.R"))
suppressMessages({library(ggplot2); library(gridExtra); library(parallel)})

CP <- CALIBRATED; FY <- CP$first.year; ST <- CP$burnin.year*52 + 1
CHATBOT_YEAR <- 2025; END_YEAR <- 2035; NATIONAL_AGYW <- 5071746
HR_TEST <- 2.11; HR_PREP <- 2.22; BASE_SEED <- 40
N <- 3000; NSIMS <- 12; NCORES <- max(1, parallel::detectCores()-2)

cascade_int <- function(dat, at) {
  p <- dat$param; yr <- p$first.year + (at-1)/52; s0<-p$art.start.year; s1<-p$art.full.year
  asc <- if (yr<=s0) 0 else if (yr>=s1) 1 else (yr-s0)/(s1-s0)
  rr  <- if (yr >= p$chatbot.start.year) p$chatbot.test.rr else 1
  active<-get_attr(dat,"active"); status<-get_attr(dat,"status"); stage<-get_attr(dat,"stage")
  diag.status<-get_attr(dat,"diag.status"); art.status<-get_attr(dat,"art.status")
  vl.supp<-get_attr(dat,"vl.supp"); art.time<-get_attr(dat,"art.time")
  sex<-get_attr(dat,"sex"); age<-get_attr(dat,"age"); chatbot<-get_attr(dat,"chatbot")
  test.rate<-get_param(dat,"test.rate"); aids.dx.rate<-get_param(dat,"aids.dx.rate")
  linkage.rate<-get_param(dat,"linkage.rate")*asc; art.reinit.rate<-get_param(dat,"art.reinit.rate")*asc
  suppression.rate<-get_param(dat,"suppression.rate")*asc; art.disc.rate<-get_param(dat,"art.disc.rate")
  diag0<-diag.status; art0<-art.status; supp0<-vl.supp; is_inf<-active==1 & status=="i"
  trv<-rep(test.rate,length(active)); trv[(active==1&sex==0&age>=15&age<25)&chatbot==1]<-pmin(1,test.rate*rr)
  idsu<-which(is_inf&diag0==0); if(length(idsu)){r<-ifelse(!is.na(stage[idsu])&stage[idsu]=="aids",aids.dx.rate,trv[idsu]);nd<-idsu[rbinom(length(idsu),1,r)==1];if(length(nd))diag.status[nd]<-1L}
  iln<-which(is_inf&diag0==1&art0==0&is.na(art.time)); if(length(iln)){h<-iln[rbinom(length(iln),1,linkage.rate)==1];if(length(h)){art.status[h]<-1L;art.time[h]<-at}}
  ilr<-which(is_inf&diag0==1&art0==0&!is.na(art.time)); if(length(ilr)){h<-ilr[rbinom(length(ilr),1,art.reinit.rate)==1];if(length(h)){art.status[h]<-1L;art.time[h]<-at}}
  isu<-which(is_inf&art0==1&supp0==0); if(length(isu)){h<-isu[rbinom(length(isu),1,suppression.rate)==1];if(length(h))vl.supp[h]<-1L}
  idc<-which(is_inf&art0==1); if(length(idc)){h<-idc[rbinom(length(idc),1,art.disc.rate)==1];if(length(h)){art.status[h]<-0L;vl.supp[h]<-0L}}
  dat<-set_attr(dat,"diag.status",diag.status);dat<-set_attr(dat,"art.status",art.status);dat<-set_attr(dat,"vl.supp",vl.supp);dat<-set_attr(dat,"art.time",art.time);dat
}
prep_int <- function(dat, at) {
  p <- dat$param; yr <- p$first.year + (at-1)/52; rr <- if (yr >= p$chatbot.start.year) p$chatbot.prep.rr else 1
  active<-get_attr(dat,"active"); status<-get_attr(dat,"status"); prep.status<-get_attr(dat,"prep.status")
  sex<-get_attr(dat,"sex"); age<-get_attr(dat,"age"); chatbot<-get_attr(dat,"chatbot")
  prep.init.cov<-get_param(dat,"prep.init.cov"); prep.start.rate<-get_param(dat,"prep.start.rate")
  prep.stop.rate<-get_param(dat,"prep.stop.rate"); prep.indic.deg<-get_param(dat,"prep.indic.deg")
  n<-length(active); td<-integer(n); pp<-logical(n)
  for(k in 1:2){el<-get_edgelist(dat,network=k);if(is.null(el)||nrow(el)==0)next;td<-td+get_degree(el);pp[el[,2][status[el[,1]]=="i"]]<-TRUE;pp[el[,1][status[el[,2]]=="i"]]<-TRUE}
  agyw<-active==1&sex==0&age>=15&age<25; cb.on<-yr>=p$chatbot.start.year
  indic<-active==1&status=="s"&(td>=prep.indic.deg|pp|(agyw&chatbot==1&cb.on))
  ni<-is.na(prep.status)&active==1; if(any(ni)){prep.status[ni]<-0L;if(prep.init.cov>0){ii<-which(ni&indic);if(length(ii))prep.status[ii]<-rbinom(length(ii),1,prep.init.cov)}}
  sv<-rep(prep.start.rate,n); sv[agyw&chatbot==1]<-pmin(1,prep.start.rate*rr); io<-which(indic&prep.status==0); if(length(io)){h<-rbinom(length(io),1,sv[io])==1;prep.status[io[h]]<-1L}
  if(prep.stop.rate>0){on<-which(active==1&status=="s"&prep.status==1);if(length(on))prep.status[on[rbinom(length(on),1,prep.stop.rate)==1]]<-0L}
  dat<-set_attr(dat,"prep.status",prep.status);dat
}

# one sim -> per-year trajectory (incidence national, PrEP coverage, dx fraction)
run_traj <- function(reach, trr, prr, seed, ests) {
  set.seed(seed)
  p <- hetage_param(inf.prob.act=CP$inf.prob.act, age.gap=CP$age.gap, acts.main=CP$acts.main, acts.casual=CP$acts.casual,
        agyw.susc.15_19=CP$agyw.susc.15_19, agyw.susc.20_24=CP$agyw.susc.20_24, seed.tick=ST, seed.prev=CP$seed.prev,
        chatbot.reach=reach, chatbot.test.rr=trr, chatbot.prep.rr=prr,
        first.year=FY, art.start.year=CP$art.start.year, art.full.year=CP$art.full.year, chatbot.start.year=CHATBOT_YEAR)
  ctrl <- control.net(type=NULL, nsims=1, ncores=1, nsteps=(END_YEAR-FY)*52, tergmLite=TRUE, resimulate.network=TRUE,
    aging.FUN=aging_mod, infection.FUN=infect_track, progress.FUN=progress, cascade.FUN=cascade_int,
    prep.FUN=prep_int, departures.FUN=dfunc, arrivals.FUN=afunc_hetage, verbose=FALSE)
  df <- as.data.frame(netsim(list(ests$est_main, ests$est_cas), p, init.net(i.num=0), ctrl))
  yrs <- 2020:END_YEAR
  inc <- sapply(yrs, function(y){s0<-(y-FY)*52+1;w<-s0:min(s0+51,nrow(df));NATIONAL_AGYW/mean(df$agyw.num[w],na.rm=TRUE)*sum(df$incid.agyw[w],na.rm=TRUE)})
  pc  <- sapply(yrs, function(y){s<-(y-FY)*52+26;if(s>nrow(df))NA else df$prep.agyw[s]/max(df$agyw.num[s],1)})
  dx  <- sapply(yrs, function(y){s<-(y-FY)*52+26;if(s>nrow(df)||is.na(df$agyw.hiv[s])||df$agyw.hiv[s]==0)NA else df$agyw.dx[s]/df$agyw.hiv[s]})
  data.frame(year=yrs, incid=inc, prep=pc, dx=dx)
}

scns <- list(
  list(id="Baseline (no chatbot)", reach=0, trr=1, prr=1),
  list(id="Reach 30%, central",    reach=0.30, trr=1+(HR_TEST-1)*0.5, prr=1+(HR_PREP-1)*0.5),
  list(id="Reach 50%, central",    reach=0.50, trr=1+(HR_TEST-1)*0.5, prr=1+(HR_PREP-1)*0.5),
  list(id="Reach 50%, optimistic", reach=0.50, trr=HR_TEST,           prr=HR_PREP))

set.seed(BASE_SEED)
ests <- build_hetage_network(N, age_gap=CP$age.gap, deg_main=CP$deg_main, deg_cas=CP$deg_cas,
                             conc_main=CP$conc_main, conc_cas=CP$conc_cas, mix_main=CP$mix_main, mix_cas=CP$mix_cas)
tasks <- expand.grid(s=seq_along(scns), i=1:NSIMS)
PROG<-"results/progress"; unlink(PROG,recursive=TRUE); dir.create(PROG,showWarnings=FALSE); writeLines(as.character(nrow(tasks)),"results/progress_total.txt")
cat(sprintf("Running %d tasks on %d cores...\n", nrow(tasks), NCORES))
vals <- mclapply(seq_len(nrow(tasks)), function(k){
  sc<-scns[[tasks$s[k]]]
  r<-tryCatch(run_traj(sc$reach,sc$trr,sc$prr,BASE_SEED+tasks$i[k],ests), error=function(e) NULL)
  cat("done\n", file=file.path(PROG, paste0(k,".done"))); r
}, mc.cores=NCORES)

# aggregate per scenario per year: median + 95% CI
agg <- function(metric) {
  do.call(rbind, lapply(seq_along(scns), function(s){
    idx <- which(tasks$s==s); mats <- do.call(rbind, lapply(idx, function(k) vals[[k]][[metric]]))
    data.frame(scenario=scns[[s]]$id, year=vals[[idx[1]]]$year,
      med=apply(mats,2,median,na.rm=TRUE), lo=apply(mats,2,quantile,.025,na.rm=TRUE), hi=apply(mats,2,quantile,.975,na.rm=TRUE))
  }))
}
INC<-agg("incid"); PREP<-agg("prep"); DX<-agg("dx")
INC$scenario<-factor(INC$scenario, levels=sapply(scns,`[[`,"id"))
PREP$scenario<-factor(PREP$scenario, levels=sapply(scns,`[[`,"id"))
saveRDS(list(INC=INC,PREP=PREP,DX=DX), "results/trajectories.rds")

# (A) incidence fan plot
cols <- c("#2c3e50","#f1c40f","#e67e22","#27ae60")
pA <- ggplot(INC, aes(year, med, colour=scenario, fill=scenario)) +
  geom_vline(xintercept=2025, linetype="dashed", colour="grey60") +
  annotate("text", x=2025.2, y=Inf, label="chatbot start", hjust=0, vjust=1.5, size=3, colour="grey40") +
  geom_ribbon(aes(ymin=lo,ymax=hi), alpha=0.12, colour=NA) +
  geom_line(aes(y=med), linewidth=1) +
  scale_colour_manual(values=cols,name=NULL) + scale_fill_manual(values=cols,name=NULL) +
  scale_y_continuous(labels=scales::comma) +
  labs(title="(A) AGYW HIV incidence: baseline vs chatbot scenarios",
       x="Year", y="New infections / year (national)") + theme_minimal(base_size=11) + theme(legend.position="top")

# (B) mechanism: PrEP coverage among AGYW
pB <- ggplot(PREP, aes(year, med, colour=scenario, fill=scenario)) +
  geom_vline(xintercept=2025, linetype="dashed", colour="grey60") +
  geom_ribbon(aes(ymin=lo,ymax=hi), alpha=0.12, colour=NA) + geom_line(linewidth=1) +
  scale_colour_manual(values=cols,name=NULL) + scale_fill_manual(values=cols,name=NULL) +
  scale_y_continuous(labels=scales::percent) +
  labs(title="(B) Mechanism: PrEP coverage among AGYW",
       x="Year", y="AGYW on PrEP (%)") + theme_minimal(base_size=11) + theme(legend.position="top")

ggsave("results/fan_incidence.png", pA, width=8, height=5, dpi=140)
ggsave("results/mechanism_prep.png", pB, width=8, height=5, dpi=140)
ggsave("results/trajectories_combined.png", arrangeGrob(pA,pB,ncol=2), width=14, height=5, dpi=140)
cat("Wrote results/fan_incidence.png, mechanism_prep.png, trajectories_combined.png\n")
