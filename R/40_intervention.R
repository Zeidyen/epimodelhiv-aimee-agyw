## 40_intervention.R — THE STUDY OUTPUT: AGYW HIV infections averted by the
## Aimee chatbot, on the calibrated baseline. Chatbot 2025-2035. Scenario grid =
## reach (10/30/50%) x causal fraction (25/50/100% of Clover HRs: test 2.11, PrEP 2.22).
##
## PARALLEL + PAIRED: each (scenario x sim) is one single-sim netsim (ncores=1,
## deterministic) with a per-sim seed SHARED across scenarios (set.seed(BASE+i)),
## so baseline-sim-i and scenario-sim-i share the identical pre-2025 history
## (common random numbers) -> the chatbot effect is isolated. All tasks run across
## cores via mclapply (uses the M4 Max). Output = national AGYW infections averted.
## Run: Rscript R/40_intervention.R

source(file.path(
  tryCatch({a<-commandArgs(FALSE);f<-sub("^--file=","",a[grep("^--file=",a)])
            if(length(f)) dirname(normalizePath(f)) else "."}, error=function(e) "."),
  "model_components.R"))
source(file.path(dirname(normalizePath(sub("^--file=","",commandArgs(FALSE)[grep("^--file=",commandArgs(FALSE))]))), "calibrated_params.R"))
suppressMessages({library(ggplot2); library(parallel)})
`%||%` <- function(a,b) if (is.null(a)||length(a)==0) b else a

CP <- CALIBRATED
FY <- CP$first.year; ST <- CP$burnin.year*52 + 1
CHATBOT_YEAR <- 2025; END_YEAR <- 2035
NATIONAL_AGYW <- 5071746
HR_TEST <- 2.11; HR_PREP <- 2.22
BASE_SEED <- 40
N <- 1500; NSIMS <- 12
NCORES <- max(1, parallel::detectCores() - 2)

# ---- self-contained modules: ART ramp + time-gated chatbot ------------------
cascade_int <- function(dat, at) {
  p <- dat$param; yr <- p$first.year + (at-1)/52
  s0<-p$art.start.year; s1<-p$art.full.year
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
  trv <- rep(test.rate, length(active))
  trv[(active==1 & sex==0 & age>=15 & age<25) & chatbot==1] <- pmin(1, test.rate*rr)
  idsu<-which(is_inf&diag0==0)
  if(length(idsu)){r<-ifelse(!is.na(stage[idsu])&stage[idsu]=="aids",aids.dx.rate,trv[idsu])
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
prep_int <- function(dat, at) {
  p <- dat$param; yr <- p$first.year + (at-1)/52
  rr <- if (yr >= p$chatbot.start.year) p$chatbot.prep.rr else 1
  active<-get_attr(dat,"active"); status<-get_attr(dat,"status"); prep.status<-get_attr(dat,"prep.status")
  sex<-get_attr(dat,"sex"); age<-get_attr(dat,"age"); chatbot<-get_attr(dat,"chatbot")
  prep.init.cov<-get_param(dat,"prep.init.cov"); prep.start.rate<-get_param(dat,"prep.start.rate")
  prep.stop.rate<-get_param(dat,"prep.stop.rate"); prep.indic.deg<-get_param(dat,"prep.indic.deg")
  n<-length(active); td<-integer(n); pp<-logical(n)
  for(k in 1:2){ el<-get_edgelist(dat,network=k); if(is.null(el)||nrow(el)==0) next
    td<-td+get_degree(el); pp[el[,2][status[el[,1]]=="i"]]<-TRUE; pp[el[,1][status[el[,2]]=="i"]]<-TRUE }
  agyw <- active==1 & sex==0 & age>=15 & age<25
  indic <- active==1 & status=="s" & (td>=prep.indic.deg | pp | (agyw & chatbot==1))
  ni<-is.na(prep.status)&active==1
  if(any(ni)){prep.status[ni]<-0L; if(prep.init.cov>0){ii<-which(ni&indic); if(length(ii)) prep.status[ii]<-rbinom(length(ii),1,prep.init.cov)}}
  sv<-rep(prep.start.rate,n); sv[agyw & chatbot==1]<-pmin(1,prep.start.rate*rr)
  io<-which(indic & prep.status==0)
  if(length(io)){h<-rbinom(length(io),1,sv[io])==1; prep.status[io[h]]<-1L}
  if(prep.stop.rate>0){on<-which(active==1&status=="s"&prep.status==1); if(length(on)) prep.status[on[rbinom(length(on),1,prep.stop.rate)==1]]<-0L}
  dat<-set_attr(dat,"prep.status",prep.status)
  dat
}

# ---- one single-sim run (deterministic) -> national AGYW infections 2025-2035
run_one <- function(reach, trr, prr, seed, ests) {
  set.seed(seed)
  p <- hetage_param(inf.prob.act=CP$inf.prob.act, age.gap=CP$age.gap, acts.main=CP$acts.main, acts.casual=CP$acts.casual,
        agyw.susc.15_19=CP$agyw.susc.15_19, agyw.susc.20_24=CP$agyw.susc.20_24,
        seed.tick=ST, seed.prev=CP$seed.prev,
        chatbot.reach=reach, chatbot.test.rr=trr, chatbot.prep.rr=prr,
        first.year=FY, art.start.year=CP$art.start.year, art.full.year=CP$art.full.year,
        chatbot.start.year=CHATBOT_YEAR)
  ctrl <- control.net(type=NULL, nsims=1, ncores=1, nsteps=(END_YEAR-FY)*52,
    tergmLite=TRUE, resimulate.network=TRUE, aging.FUN=aging_mod, infection.FUN=infect_track,
    progress.FUN=progress, cascade.FUN=cascade_int, prep.FUN=prep_int, departures.FUN=dfunc,
    arrivals.FUN=afunc_hetage, verbose=FALSE)
  sim <- netsim(list(ests$est_main, ests$est_cas), p, init.net(i.num=0), ctrl)
  df <- as.data.frame(sim)
  w <- ((CHATBOT_YEAR-FY)*52+1):((END_YEAR-FY)*52); w <- w[w<=nrow(df)]
  scale <- NATIONAL_AGYW / mean(df$agyw.num[w], na.rm=TRUE)
  sum(df$incid.agyw[w], na.rm=TRUE) * scale
}

# ---- scenarios + (scenario x sim) task grid --------------------------------
causal <- c(conservative=0.25, central=0.50, optimistic=1.00)
scns <- list(list(id="baseline", reach=0, trr=1, prr=1))
for (rc in c(0.10,0.30,0.50)) for (cf in names(causal))
  scns[[length(scns)+1]] <- list(id=sprintf("r%02d_%s", round(rc*100), cf),
    reach=rc, trr=1+(HR_TEST-1)*causal[cf], prr=1+(HR_PREP-1)*causal[cf])

set.seed(BASE_SEED)
ests <- build_hetage_network(N, age_gap=CP$age.gap, deg_main=CP$deg_main, deg_cas=CP$deg_cas,
                             conc_main=CP$conc_main, conc_cas=CP$conc_cas, mix_main=CP$mix_main, mix_cas=CP$mix_cas)

tasks <- expand.grid(s=seq_along(scns), i=1:NSIMS)
cat(sprintf("Running %d tasks (%d scenarios x %d sims) on %d cores...\n", nrow(tasks), length(scns), NSIMS, NCORES))
vals <- mclapply(seq_len(nrow(tasks)), function(k){
  sc <- scns[[tasks$s[k]]]
  tryCatch(run_one(sc$reach, sc$trr, sc$prr, BASE_SEED + tasks$i[k], ests), error=function(e) NA_real_)
}, mc.cores=NCORES)
tasks$inf <- unlist(vals)

# matrix: rows=sims, cols=scenarios (paired by sim seed)
M <- matrix(NA_real_, nrow=NSIMS, ncol=length(scns), dimnames=list(NULL, sapply(scns,`[[`,"id")))
for (k in seq_len(nrow(tasks))) M[tasks$i[k], tasks$s[k]] <- tasks$inf[k]
base_col <- M[,"baseline"]; base_med <- median(base_col, na.rm=TRUE)

rows <- list()
for (j in 2:length(scns)) {
  sc <- scns[[j]]; averted <- base_col - M[,j]   # PAIRED by sim
  rows[[length(rows)+1]] <- data.frame(reach=sc$reach, causal=sub("^r\\d+_","",sc$id),
    averted_med=median(averted,na.rm=TRUE), averted_lo=quantile(averted,.025,na.rm=TRUE),
    averted_hi=quantile(averted,.975,na.rm=TRUE), pct_med=100*median(averted,na.rm=TRUE)/base_med)
  cat(sprintf("%s: averted %.0f [%.0f, %.0f] (%.1f%%)\n", sc$id, median(averted,na.rm=TRUE),
      quantile(averted,.025,na.rm=TRUE), quantile(averted,.975,na.rm=TRUE), 100*median(averted,na.rm=TRUE)/base_med))
}
res <- do.call(rbind, rows)
res$causal <- factor(res$causal, levels=c("conservative","central","optimistic"))
saveRDS(list(res=res, base_med=base_med, M=M), "results/intervention.rds")
cat(sprintf("\nBaseline national AGYW infections 2025-2035: %.0f\n", base_med))

pl <- ggplot(res, aes(factor(reach*100), averted_med, fill=causal)) +
  geom_col(position=position_dodge(.8), width=.7) +
  geom_errorbar(aes(ymin=averted_lo, ymax=averted_hi), position=position_dodge(.8), width=.2) +
  scale_fill_brewer(palette="Greens", name="Causal fraction") +
  labs(title="AGYW HIV infections averted by the Aimee chatbot, 2025-2035 (South Africa)",
       subtitle=sprintf("Calibrated baseline; %.0f baseline infections. Paired design. Bars=median, whiskers=95%%.", base_med),
       x="Chatbot reach among AGYW (%)", y="National AGYW infections averted") +
  theme_minimal(base_size=12)
ggsave("results/intervention.png", pl, width=9, height=5, dpi=140)
cat("Wrote results/intervention.png\n")
