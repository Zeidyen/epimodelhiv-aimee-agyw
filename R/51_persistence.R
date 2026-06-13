## 51_persistence.R — IMPLEMENTATION-SCIENCE sub-study: PrEP demand vs persistence.
## The chatbot can act on three PrEP levers among reached AGYW:
##   (1) DEMAND  — expand eligibility + boost initiation (prep.start.rate x rr)
##   (2) PERSIST — improve continuation (lower prep.stop.rate x persist_rr)
##   (3) BOTH
## Testing is held at baseline (test.rr=1) so the comparison isolates the PrEP
## delivery strategy. Question: does sustaining use beat driving initiation, and
## is combining them synergistic? Reach fixed at 50%, initiation at central
## (causal 50% of HR 2.22 => 1.61). Persistence swept 20/40/60% reduction in
## weekly discontinuation (median time-on-PrEP ~6mo -> ~7.4/9.8/14.8mo).
## Paired CRN design, parallel. Run: Rscript R/51_persistence.R
##   env overrides: FULL_N (20000), FULL_NSIMS (24)

source(file.path(
  tryCatch({a<-commandArgs(FALSE);f<-sub("^--file=","",a[grep("^--file=",a)])
            if(length(f)) dirname(normalizePath(f)) else "."}, error=function(e) "."),
  "model_components.R"))
source(file.path(dirname(normalizePath(sub("^--file=","",commandArgs(FALSE)[grep("^--file=",commandArgs(FALSE))]))), "calibrated_params.R"))
suppressMessages({library(ggplot2); library(gridExtra); library(parallel)})

CP<-CALIBRATED; FY<-CP$first.year; ST<-CP$burnin.year*52+1
CHATBOT_YEAR<-2025; END_YEAR<-2035; NATIONAL_AGYW<-5071746
HR_PREP<-2.22; BASE_SEED<-40; REACH<-0.50; PREP_RR<-1+(HR_PREP-1)*0.50  # central initiation
N <- as.integer(Sys.getenv("FULL_N","20000")); NSIMS <- as.integer(Sys.getenv("FULL_NSIMS","24"))
NCORES <- max(1, parallel::detectCores()-2)

# care cascade with ART ramp, NO chatbot testing boost (test held at baseline)
cascade_noboost <- function(dat, at) {
  p<-dat$param; yr<-p$first.year+(at-1)/52; s0<-p$art.start.year; s1<-p$art.full.year
  asc<-if(yr<=s0)0 else if(yr>=s1)1 else (yr-s0)/(s1-s0)
  active<-get_attr(dat,"active");status<-get_attr(dat,"status");stage<-get_attr(dat,"stage")
  diag.status<-get_attr(dat,"diag.status");art.status<-get_attr(dat,"art.status");vl.supp<-get_attr(dat,"vl.supp");art.time<-get_attr(dat,"art.time")
  test.rate<-get_param(dat,"test.rate");aids.dx.rate<-get_param(dat,"aids.dx.rate")
  linkage.rate<-get_param(dat,"linkage.rate")*asc;art.reinit.rate<-get_param(dat,"art.reinit.rate")*asc
  suppression.rate<-get_param(dat,"suppression.rate")*asc;art.disc.rate<-get_param(dat,"art.disc.rate")
  diag0<-diag.status;art0<-art.status;supp0<-vl.supp;is_inf<-active==1&status=="i"
  idsu<-which(is_inf&diag0==0);if(length(idsu)){r<-ifelse(!is.na(stage[idsu])&stage[idsu]=="aids",aids.dx.rate,test.rate);nd<-idsu[rbinom(length(idsu),1,r)==1];if(length(nd))diag.status[nd]<-1L}
  iln<-which(is_inf&diag0==1&art0==0&is.na(art.time));if(length(iln)){h<-iln[rbinom(length(iln),1,linkage.rate)==1];if(length(h)){art.status[h]<-1L;art.time[h]<-at}}
  ilr<-which(is_inf&diag0==1&art0==0&!is.na(art.time));if(length(ilr)){h<-ilr[rbinom(length(ilr),1,art.reinit.rate)==1];if(length(h)){art.status[h]<-1L;art.time[h]<-at}}
  isu<-which(is_inf&art0==1&supp0==0);if(length(isu)){h<-isu[rbinom(length(isu),1,suppression.rate)==1];if(length(h))vl.supp[h]<-1L}
  idc<-which(is_inf&art0==1);if(length(idc)){h<-idc[rbinom(length(idc),1,art.disc.rate)==1];if(length(h)){art.status[h]<-0L;vl.supp[h]<-0L}}
  dat<-set_attr(dat,"diag.status",diag.status);dat<-set_attr(dat,"art.status",art.status);dat<-set_attr(dat,"vl.supp",vl.supp);dat<-set_attr(dat,"art.time",art.time);dat
}

# PrEP module with THREE separable levers (demand = eligibility+initiation; persist = continuation)
prep_persist <- function(dat, at) {
  p<-dat$param; yr<-p$first.year+(at-1)/52; cb.on<-yr>=p$chatbot.start.year
  rr<-if(cb.on)p$chatbot.prep.rr else 1
  persist_rr<-if(cb.on)p$chatbot.prep.persist.rr else 1
  demand_on<-p$chatbot.prep.rr>1
  active<-get_attr(dat,"active");status<-get_attr(dat,"status");prep.status<-get_attr(dat,"prep.status")
  sex<-get_attr(dat,"sex");age<-get_attr(dat,"age");chatbot<-get_attr(dat,"chatbot")
  prep.init.cov<-get_param(dat,"prep.init.cov");prep.start.rate<-get_param(dat,"prep.start.rate");prep.stop.rate<-get_param(dat,"prep.stop.rate");prep.indic.deg<-get_param(dat,"prep.indic.deg")
  n<-length(active);td<-integer(n);pp<-logical(n)
  for(k in 1:2){el<-get_edgelist(dat,network=k);if(is.null(el)||nrow(el)==0)next;td<-td+get_degree(el);pp[el[,2][status[el[,1]]=="i"]]<-TRUE;pp[el[,1][status[el[,2]]=="i"]]<-TRUE}
  agyw<-active==1&sex==0&age>=15&age<25
  # DEMAND lever: reached AGYW made PrEP-eligible only when demand arm active
  indic<-active==1&status=="s"&(td>=prep.indic.deg|pp|(agyw&chatbot==1&cb.on&demand_on))
  ni<-is.na(prep.status)&active==1;if(any(ni)){prep.status[ni]<-0L;if(prep.init.cov>0){ii<-which(ni&indic);if(length(ii))prep.status[ii]<-rbinom(length(ii),1,prep.init.cov)}}
  # DEMAND lever: initiation rate boosted (rr=1 when demand off)
  sv<-rep(prep.start.rate,n);sv[agyw&chatbot==1]<-pmin(1,prep.start.rate*rr);io<-which(indic&prep.status==0);if(length(io)){h<-rbinom(length(io),1,sv[io])==1;prep.status[io[h]]<-1L}
  # PERSIST lever: discontinuation lowered for reached AGYW (persist_rr<1 keeps them on longer)
  if(prep.stop.rate>0){stopv<-rep(prep.stop.rate,n);stopv[agyw&chatbot==1]<-prep.stop.rate*persist_rr
    on<-which(active==1&status=="s"&prep.status==1);if(length(on))prep.status[on[runif(length(on))<stopv[on]]]<-0L}
  dat<-set_attr(dat,"prep.status",prep.status);dat
}

# one sim -> list(post=national infections 2025-2035, pre=pairing check, traj=PrEP coverage/yr)
run_one <- function(reach, prr, persist_rr, seed, ests) {
  set.seed(seed)
  p <- hetage_param(inf.prob.act=CP$inf.prob.act, age.gap=CP$age.gap, acts.main=CP$acts.main, acts.casual=CP$acts.casual,
        agyw.susc.15_19=CP$agyw.susc.15_19, agyw.susc.20_24=CP$agyw.susc.20_24, seed.tick=ST, seed.prev=CP$seed.prev,
        chatbot.reach=reach, chatbot.test.rr=1, chatbot.prep.rr=prr, chatbot.prep.persist.rr=persist_rr,
        first.year=FY, art.start.year=CP$art.start.year, art.full.year=CP$art.full.year, chatbot.start.year=CHATBOT_YEAR)
  ctrl <- control.net(type=NULL, nsims=1, ncores=1, nsteps=(END_YEAR-FY)*52, tergmLite=TRUE, resimulate.network=TRUE,
    aging.FUN=aging_mod, infection.FUN=infect_track, progress.FUN=progress, cascade.FUN=cascade_noboost,
    prep.FUN=prep_persist, departures.FUN=dfunc, arrivals.FUN=afunc_hetage, verbose=FALSE)
  df <- as.data.frame(netsim(list(ests$est_main, ests$est_cas), p, init.net(i.num=0), ctrl))
  w  <- ((CHATBOT_YEAR-FY)*52+1):((END_YEAR-FY)*52); w<-w[w<=nrow(df)]
  wp <- ((2020-FY)*52+1):((CHATBOT_YEAR-FY)*52); wp<-wp[wp<=nrow(df)]
  scale <- NATIONAL_AGYW/mean(df$agyw.num[w],na.rm=TRUE); yrs<-2020:END_YEAR
  traj <- data.frame(year=yrs,
    prep=sapply(yrs,function(y){s<-(y-FY)*52+26;if(s>nrow(df))NA else df$prep.agyw[s]/max(df$agyw.num[s],1)}))
  list(post=sum(df$incid.agyw[w],na.rm=TRUE)*scale, pre=sum(df$incid.agyw[wp],na.rm=TRUE), traj=traj)
}

# scenarios: baseline, demand-only, persist x3, both x3 (all reach 50%, central initiation)
scns<-list(
  list(id="baseline",   reach=0,     prr=1,       persist=1.0),
  list(id="demand",     reach=REACH, prr=PREP_RR, persist=1.0),
  list(id="persist_20", reach=REACH, prr=1,       persist=0.8),
  list(id="persist_40", reach=REACH, prr=1,       persist=0.6),
  list(id="persist_60", reach=REACH, prr=1,       persist=0.4),
  list(id="both_20",    reach=REACH, prr=PREP_RR, persist=0.8),
  list(id="both_40",    reach=REACH, prr=PREP_RR, persist=0.6),
  list(id="both_60",    reach=REACH, prr=PREP_RR, persist=0.4))

set.seed(BASE_SEED)
ests<-build_hetage_network(N,age_gap=CP$age.gap,deg_main=CP$deg_main,deg_cas=CP$deg_cas,conc_main=CP$conc_main,conc_cas=CP$conc_cas,mix_main=CP$mix_main,mix_cas=CP$mix_cas)
tasks<-expand.grid(s=seq_along(scns), i=1:NSIMS)
PROG<-"results/progress_persist";unlink(PROG,recursive=TRUE);dir.create(PROG,showWarnings=FALSE);writeLines(as.character(nrow(tasks)),"results/progress_persist_total.txt")
cat(sprintf("Persistence sub-study: %d tasks (%d strategies x %d sims), N=%d, %d cores...\n",nrow(tasks),length(scns),NSIMS,N,NCORES))
vals<-mclapply(seq_len(nrow(tasks)), function(k){
  sc<-scns[[tasks$s[k]]]; r<-tryCatch(run_one(sc$reach,sc$prr,sc$persist,BASE_SEED+tasks$i[k],ests), error=function(e) NULL)
  cat("done\n",file=file.path(PROG,paste0(k,".done"))); r
}, mc.cores=NCORES)

ids<-sapply(scns,`[[`,"id")
M<-Mpre<-matrix(NA_real_,NSIMS,length(scns),dimnames=list(NULL,ids))
for(k in seq_len(nrow(tasks))){ if(!is.null(vals[[k]])){M[tasks$i[k],tasks$s[k]]<-vals[[k]]$post; Mpre[tasks$i[k],tasks$s[k]]<-vals[[k]]$pre} }
cat(sprintf("\n[pairing] max|pre diff|=%.1f\n", max(abs(sweep(Mpre,1,Mpre[,"baseline"])),na.rm=TRUE)))
base_col<-M[,"baseline"]; base_med<-median(base_col,na.rm=TRUE)

# ---- averted per strategy (paired t-CI) ----
lab<-c(demand="Demand only\n(initiation)",persist_20="Persistence\n-20% disc.",persist_40="Persistence\n-40% disc.",persist_60="Persistence\n-60% disc.",
       both_20="Both\n-20% disc.",both_40="Both\n-40% disc.",both_60="Both\n-60% disc.")
grp<-c(demand="Demand",persist_20="Persistence",persist_40="Persistence",persist_60="Persistence",both_20="Both",both_40="Both",both_60="Both")
rows<-list()
for(j in 2:length(scns)){ id<-scns[[j]]$id; av<-base_col-M[,j]; tt<-tryCatch(t.test(av),error=function(e)list(conf.int=c(NA,NA),p.value=NA))
  rows[[length(rows)+1]]<-data.frame(id=id,strategy=grp[id],label=lab[id],averted=mean(av,na.rm=TRUE),
    lo=tt$conf.int[1],hi=tt$conf.int[2],p=tt$p.value,pct=100*mean(av,na.rm=TRUE)/base_med)
  cat(sprintf("%-12s averted %6.0f [%6.0f, %6.0f] p=%.3f (%.1f%%)\n",id,mean(av,na.rm=TRUE),tt$conf.int[1],tt$conf.int[2],tt$p.value,100*mean(av,na.rm=TRUE)/base_med)) }
res<-do.call(rbind,rows); res$label<-factor(res$label,levels=lab); res$strategy<-factor(res$strategy,levels=c("Demand","Persistence","Both"))

# ---- PrEP coverage trajectory by strategy ----
agg<-function(metric){ do.call(rbind, lapply(seq_along(scns), function(s){
  idx<-which(tasks$s==s); idx<-idx[!sapply(vals[idx],is.null)]
  mats<-do.call(rbind,lapply(idx,function(k) vals[[k]]$traj[[metric]]))
  data.frame(scenario=scns[[s]]$id, year=vals[[idx[1]]]$traj$year,
    med=apply(mats,2,median,na.rm=TRUE),lo=apply(mats,2,quantile,.025,na.rm=TRUE),hi=apply(mats,2,quantile,.975,na.rm=TRUE)) })) }
PREP<-agg("prep")
saveRDS(list(res=res,base_med=base_med,M=M,PREP=PREP,scns=scns), "results/persistence_results.rds")
cat(sprintf("\nBaseline national AGYW infections 2025-2035: %.0f\n",base_med))

# ======================= FIGURES =======================
# (A) averted by strategy, bars + 95% t-CI
pA<-ggplot(res,aes(label,averted,fill=strategy))+geom_col(width=.7)+
  geom_errorbar(aes(ymin=lo,ymax=hi),width=.2)+geom_hline(yintercept=0,colour="grey50")+
  scale_fill_manual(values=c(Demand="#e67e22",Persistence="#2980b9",Both="#27ae60"),name="Strategy")+
  labs(title="(A) AGYW infections averted by PrEP delivery strategy",
       subtitle=sprintf("Reach 50%%, central initiation. Baseline %s infections. Bars=mean, whiskers=95%% t-CI.",format(round(base_med),big.mark=",")),
       x=NULL,y="National AGYW infections averted")+theme_minimal(base_size=11)+theme(axis.text.x=element_text(size=8))
# (B) PrEP coverage trajectory: demand vs persistence vs both (at -40%)
sel<-c("baseline","demand","persist_40","both_40")
plab<-c(baseline="Baseline (no chatbot)",demand="Demand only",persist_40="Persistence only (-40%)",both_40="Both (-40%)")
PREPs<-PREP[PREP$scenario%in%sel & PREP$year<=END_YEAR-1,]; PREPs$scenario<-factor(plab[PREPs$scenario],levels=plab[sel])
cols<-c("#2c3e50","#e67e22","#2980b9","#27ae60")
pB<-ggplot(PREPs,aes(year,med,colour=scenario,fill=scenario))+geom_vline(xintercept=2025,linetype="dashed",colour="grey60")+
  geom_ribbon(aes(ymin=lo,ymax=hi),alpha=.12,colour=NA)+geom_line(linewidth=1)+
  scale_colour_manual(values=cols,name=NULL)+scale_fill_manual(values=cols,name=NULL)+scale_y_continuous(labels=scales::percent)+
  labs(title="(B) Mechanism: AGYW PrEP coverage",x="Year",y="AGYW on PrEP (%)")+theme_minimal(base_size=11)+theme(legend.position="top")
ggsave("results/persistence_strategy.png",pA,width=9,height=5,dpi=140)
ggsave("results/persistence_mechanism.png",pB,width=8,height=5,dpi=140)
ggsave("results/persistence_combined.png",arrangeGrob(pA,pB,ncol=2),width=15,height=5,dpi=140)
cat("Wrote persistence_strategy.png, persistence_mechanism.png, persistence_combined.png\n")
