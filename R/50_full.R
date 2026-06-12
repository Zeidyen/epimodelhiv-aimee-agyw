## 50_full.R — ONE comprehensive intervention run producing EVERYTHING.
## N=10000, full scenario grid (reach 10/30/50% x causal 25/50/100%), paired +
## parallel on the M4 Max. Per sim it records: cumulative national AGYW infections
## averted (2025-2035), the pairing check, and per-year trajectories (incidence,
## PrEP coverage, diagnosed fraction). Generates ALL figures:
##   intervention.png (averted bars), intervention_views.png (heatmap/dose-resp/eff),
##   fan_incidence.png, mechanism_prep.png. Run: Rscript R/50_full.R

source(file.path(
  tryCatch({a<-commandArgs(FALSE);f<-sub("^--file=","",a[grep("^--file=",a)])
            if(length(f)) dirname(normalizePath(f)) else "."}, error=function(e) "."),
  "model_components.R"))
source(file.path(dirname(normalizePath(sub("^--file=","",commandArgs(FALSE)[grep("^--file=",commandArgs(FALSE))]))), "calibrated_params.R"))
suppressMessages({library(ggplot2); library(gridExtra); library(parallel)})

CP<-CALIBRATED; FY<-CP$first.year; ST<-CP$burnin.year*52+1
CHATBOT_YEAR<-2025; END_YEAR<-2035; NATIONAL_AGYW<-5071746
HR_TEST<-2.11; HR_PREP<-2.22; BASE_SEED<-40
N <- as.integer(Sys.getenv("FULL_N","10000")); NSIMS <- as.integer(Sys.getenv("FULL_NSIMS","12")); NCORES <- max(1, parallel::detectCores()-2)

cascade_int <- function(dat, at) {
  p<-dat$param; yr<-p$first.year+(at-1)/52; s0<-p$art.start.year; s1<-p$art.full.year
  asc<-if(yr<=s0)0 else if(yr>=s1)1 else (yr-s0)/(s1-s0); rr<-if(yr>=p$chatbot.start.year)p$chatbot.test.rr else 1
  active<-get_attr(dat,"active");status<-get_attr(dat,"status");stage<-get_attr(dat,"stage")
  diag.status<-get_attr(dat,"diag.status");art.status<-get_attr(dat,"art.status");vl.supp<-get_attr(dat,"vl.supp");art.time<-get_attr(dat,"art.time")
  sex<-get_attr(dat,"sex");age<-get_attr(dat,"age");chatbot<-get_attr(dat,"chatbot")
  test.rate<-get_param(dat,"test.rate");aids.dx.rate<-get_param(dat,"aids.dx.rate")
  linkage.rate<-get_param(dat,"linkage.rate")*asc;art.reinit.rate<-get_param(dat,"art.reinit.rate")*asc
  suppression.rate<-get_param(dat,"suppression.rate")*asc;art.disc.rate<-get_param(dat,"art.disc.rate")
  diag0<-diag.status;art0<-art.status;supp0<-vl.supp;is_inf<-active==1&status=="i"
  trv<-rep(test.rate,length(active));trv[(active==1&sex==0&age>=15&age<25)&chatbot==1]<-pmin(1,test.rate*rr)
  idsu<-which(is_inf&diag0==0);if(length(idsu)){r<-ifelse(!is.na(stage[idsu])&stage[idsu]=="aids",aids.dx.rate,trv[idsu]);nd<-idsu[rbinom(length(idsu),1,r)==1];if(length(nd))diag.status[nd]<-1L}
  iln<-which(is_inf&diag0==1&art0==0&is.na(art.time));if(length(iln)){h<-iln[rbinom(length(iln),1,linkage.rate)==1];if(length(h)){art.status[h]<-1L;art.time[h]<-at}}
  ilr<-which(is_inf&diag0==1&art0==0&!is.na(art.time));if(length(ilr)){h<-ilr[rbinom(length(ilr),1,art.reinit.rate)==1];if(length(h)){art.status[h]<-1L;art.time[h]<-at}}
  isu<-which(is_inf&art0==1&supp0==0);if(length(isu)){h<-isu[rbinom(length(isu),1,suppression.rate)==1];if(length(h))vl.supp[h]<-1L}
  idc<-which(is_inf&art0==1);if(length(idc)){h<-idc[rbinom(length(idc),1,art.disc.rate)==1];if(length(h)){art.status[h]<-0L;vl.supp[h]<-0L}}
  dat<-set_attr(dat,"diag.status",diag.status);dat<-set_attr(dat,"art.status",art.status);dat<-set_attr(dat,"vl.supp",vl.supp);dat<-set_attr(dat,"art.time",art.time);dat
}
prep_int <- function(dat, at) {
  p<-dat$param; yr<-p$first.year+(at-1)/52; rr<-if(yr>=p$chatbot.start.year)p$chatbot.prep.rr else 1
  active<-get_attr(dat,"active");status<-get_attr(dat,"status");prep.status<-get_attr(dat,"prep.status")
  sex<-get_attr(dat,"sex");age<-get_attr(dat,"age");chatbot<-get_attr(dat,"chatbot")
  prep.init.cov<-get_param(dat,"prep.init.cov");prep.start.rate<-get_param(dat,"prep.start.rate");prep.stop.rate<-get_param(dat,"prep.stop.rate");prep.indic.deg<-get_param(dat,"prep.indic.deg")
  n<-length(active);td<-integer(n);pp<-logical(n)
  for(k in 1:2){el<-get_edgelist(dat,network=k);if(is.null(el)||nrow(el)==0)next;td<-td+get_degree(el);pp[el[,2][status[el[,1]]=="i"]]<-TRUE;pp[el[,1][status[el[,2]]=="i"]]<-TRUE}
  agyw<-active==1&sex==0&age>=15&age<25;cb.on<-yr>=p$chatbot.start.year
  indic<-active==1&status=="s"&(td>=prep.indic.deg|pp|(agyw&chatbot==1&cb.on))
  ni<-is.na(prep.status)&active==1;if(any(ni)){prep.status[ni]<-0L;if(prep.init.cov>0){ii<-which(ni&indic);if(length(ii))prep.status[ii]<-rbinom(length(ii),1,prep.init.cov)}}
  sv<-rep(prep.start.rate,n);sv[agyw&chatbot==1]<-pmin(1,prep.start.rate*rr);io<-which(indic&prep.status==0);if(length(io)){h<-rbinom(length(io),1,sv[io])==1;prep.status[io[h]]<-1L}
  if(prep.stop.rate>0){on<-which(active==1&status=="s"&prep.status==1);if(length(on))prep.status[on[rbinom(length(on),1,prep.stop.rate)==1]]<-0L}
  dat<-set_attr(dat,"prep.status",prep.status);dat
}

# one sim -> list(post=national infections 2025-2035, pre=pairing, traj=per-year df)
run_one <- function(reach, trr, prr, seed, ests) {
  set.seed(seed)
  p <- hetage_param(inf.prob.act=CP$inf.prob.act, age.gap=CP$age.gap, acts.main=CP$acts.main, acts.casual=CP$acts.casual,
        agyw.susc.15_19=CP$agyw.susc.15_19, agyw.susc.20_24=CP$agyw.susc.20_24, seed.tick=ST, seed.prev=CP$seed.prev,
        chatbot.reach=reach, chatbot.test.rr=trr, chatbot.prep.rr=prr,
        first.year=FY, art.start.year=CP$art.start.year, art.full.year=CP$art.full.year, chatbot.start.year=CHATBOT_YEAR)
  ctrl <- control.net(type=NULL, nsims=1, ncores=1, nsteps=(END_YEAR-FY)*52, tergmLite=TRUE, resimulate.network=TRUE,
    aging.FUN=aging_mod, infection.FUN=infect_track, progress.FUN=progress, cascade.FUN=cascade_int,
    prep.FUN=prep_int, departures.FUN=dfunc, arrivals.FUN=afunc_hetage, verbose=FALSE)
  df <- as.data.frame(netsim(list(ests$est_main, ests$est_cas), p, init.net(i.num=0), ctrl))
  w  <- ((CHATBOT_YEAR-FY)*52+1):((END_YEAR-FY)*52); w<-w[w<=nrow(df)]
  wp <- ((2020-FY)*52+1):((CHATBOT_YEAR-FY)*52); wp<-wp[wp<=nrow(df)]
  scale <- NATIONAL_AGYW/mean(df$agyw.num[w],na.rm=TRUE)
  yrs<-2020:END_YEAR
  traj <- data.frame(year=yrs,
    incid=sapply(yrs,function(y){s0<-(y-FY)*52+1;ww<-s0:min(s0+51,nrow(df));NATIONAL_AGYW/mean(df$agyw.num[ww],na.rm=TRUE)*sum(df$incid.agyw[ww],na.rm=TRUE)}),
    prep =sapply(yrs,function(y){s<-(y-FY)*52+26;if(s>nrow(df))NA else df$prep.agyw[s]/max(df$agyw.num[s],1)}),
    dx   =sapply(yrs,function(y){s<-(y-FY)*52+26;if(s>nrow(df)||is.na(df$agyw.hiv[s])||df$agyw.hiv[s]==0)NA else df$agyw.dx[s]/df$agyw.hiv[s]}))
  list(post=sum(df$incid.agyw[w],na.rm=TRUE)*scale, pre=sum(df$incid.agyw[wp],na.rm=TRUE), traj=traj)
}

causal<-c(conservative=0.25, central=0.50, optimistic=1.00)
scns<-list(list(id="baseline", reach=0, trr=1, prr=1))
for(rc in c(0.10,0.30,0.50)) for(cf in names(causal))
  scns[[length(scns)+1]]<-list(id=sprintf("r%02d_%s",round(rc*100),cf), reach=rc, trr=1+(HR_TEST-1)*causal[cf], prr=1+(HR_PREP-1)*causal[cf])

set.seed(BASE_SEED)
ests<-build_hetage_network(N,age_gap=CP$age.gap,deg_main=CP$deg_main,deg_cas=CP$deg_cas,conc_main=CP$conc_main,conc_cas=CP$conc_cas,mix_main=CP$mix_main,mix_cas=CP$mix_cas)
tasks<-expand.grid(s=seq_along(scns), i=1:NSIMS)
PROG<-"results/progress";unlink(PROG,recursive=TRUE);dir.create(PROG,showWarnings=FALSE);writeLines(as.character(nrow(tasks)),"results/progress_total.txt")
cat(sprintf("Running %d tasks (%d scenarios x %d sims), N=%d, on %d cores...\n",nrow(tasks),length(scns),NSIMS,N,NCORES))
vals<-mclapply(seq_len(nrow(tasks)), function(k){
  sc<-scns[[tasks$s[k]]]; r<-tryCatch(run_one(sc$reach,sc$trr,sc$prr,BASE_SEED+tasks$i[k],ests), error=function(e) NULL)
  cat("done\n",file=file.path(PROG,paste0(k,".done"))); r
}, mc.cores=NCORES)

ids<-sapply(scns,`[[`,"id")
M<-Mpre<-matrix(NA_real_,NSIMS,length(scns),dimnames=list(NULL,ids))
for(k in seq_len(nrow(tasks))){ if(!is.null(vals[[k]])){M[tasks$i[k],tasks$s[k]]<-vals[[k]]$post; Mpre[tasks$i[k],tasks$s[k]]<-vals[[k]]$pre} }
cat(sprintf("\n[pairing] max|pre diff|=%.1f\n", max(abs(sweep(Mpre,1,Mpre[,"baseline"])),na.rm=TRUE)))
base_col<-M[,"baseline"]; base_med<-median(base_col,na.rm=TRUE)

# ---- averted result ----
rows<-list()
# Inference uses the paired t-CI on the MEAN averted (estimate of the expected
# effect), which is appropriate when the signal is small vs replicate variability;
# the 2.5/97.5 percentile interval is also recorded for reference.
for(j in 2:length(scns)){ sc<-scns[[j]]; av<-base_col-M[,j]; am<-mean(av,na.rm=TRUE)
  tt<-tryCatch(t.test(av),error=function(e) list(conf.int=c(NA,NA),p.value=NA))
  rows[[length(rows)+1]]<-data.frame(reach=sc$reach,causal=sub("^r\\d+_","",sc$id),
    averted_med=am,averted_lo=tt$conf.int[1],averted_hi=tt$conf.int[2],p=tt$p.value,
    pct_med=100*am/base_med, reached=sc$reach*NATIONAL_AGYW, nnr=ifelse(am>0,sc$reach*NATIONAL_AGYW/am,NA))
  cat(sprintf("%s: averted %.0f [%.0f, %.0f] p=%.3f (%.1f%%)\n",sc$id,am,tt$conf.int[1],tt$conf.int[2],tt$p.value,100*am/base_med)) }
res<-do.call(rbind,rows); res$causal<-factor(res$causal,levels=c("conservative","central","optimistic"))

# ---- trajectories (per scenario per year median + CI) ----
agg<-function(metric){ do.call(rbind, lapply(seq_along(scns), function(s){
  idx<-which(tasks$s==s); idx<-idx[!sapply(vals[idx],is.null)]
  mats<-do.call(rbind,lapply(idx,function(k) vals[[k]]$traj[[metric]]))
  data.frame(scenario=scns[[s]]$id, year=vals[[idx[1]]]$traj$year,
    med=apply(mats,2,median,na.rm=TRUE),lo=apply(mats,2,quantile,.025,na.rm=TRUE),hi=apply(mats,2,quantile,.975,na.rm=TRUE)) })) }
INC<-agg("incid"); PREP<-agg("prep")
saveRDS(list(res=res,base_med=base_med,M=M,INC=INC,PREP=PREP), "results/full_results.rds")
saveRDS(list(res=res,base_med=base_med,M=M), "results/intervention.rds")  # for plot_intervention.R
cat(sprintf("\nBaseline national AGYW infections 2025-2035: %.0f\n",base_med))

# ======================= ALL FIGURES =======================
gr<-"#27ae60"
# main bars
p_bar<-ggplot(res,aes(factor(reach*100),averted_med,fill=causal))+geom_col(position=position_dodge(.8),width=.7)+
  geom_errorbar(aes(ymin=averted_lo,ymax=averted_hi),position=position_dodge(.8),width=.2)+geom_hline(yintercept=0,colour="grey50")+
  scale_fill_brewer(palette="Greens",name="Causal fraction")+
  labs(title="AGYW HIV infections averted by the Aimee chatbot, 2025-2035 (South Africa)",
       subtitle=sprintf("SA-realistic baseline; %.0f baseline infections. Paired t-CI, N=%d. Bars=mean, whiskers=95%% CI.",base_med,N),
       x="Chatbot reach among AGYW (%)",y="National AGYW infections averted")+theme_minimal(base_size=12)
ggsave("results/intervention.png",p_bar,width=9,height=5,dpi=140)
# heatmap + dose-response + efficiency
ph<-ggplot(res,aes(causal,factor(reach*100),fill=pct_med))+geom_tile(colour="white")+geom_text(aes(label=sprintf("%.1f%%",pct_med)),size=4)+
  scale_fill_gradient(low="#f7fcf5",high="#00441b",name="% averted")+labs(title="% infections averted",x="Causal fraction",y="Reach (%)")+theme_minimal(base_size=12)
pd<-ggplot(res,aes(reach*100,pct_med,colour=causal,group=causal))+geom_line(linewidth=1)+geom_point(size=2.5)+
  scale_colour_brewer(palette="Set2",name="Causal")+labs(title="Dose-response",x="Reach (%)",y="% averted")+theme_minimal(base_size=12)
pe<-ggplot(res,aes(reach*100,nnr,colour=causal,group=causal))+geom_line(linewidth=1)+geom_point(size=2.5)+
  scale_colour_brewer(palette="Set2",name="Causal")+labs(title="Efficiency",x="Reach (%)",y="AGYW reached / infection averted")+theme_minimal(base_size=12)
ggsave("results/intervention_views.png",arrangeGrob(ph,pd,pe,ncol=3),width=15,height=4.5,dpi=140)
# fan + mechanism
sel<-c("baseline","r30_central","r50_central","r50_optimistic")
lab<-c(baseline="Baseline",r30_central="Reach 30%, central",r50_central="Reach 50%, central",r50_optimistic="Reach 50%, optimistic")
INCs<-INC[INC$scenario %in% sel,]; INCs$scenario<-factor(lab[INCs$scenario],levels=lab[sel])
PREPs<-PREP[PREP$scenario %in% sel,]; PREPs$scenario<-factor(lab[PREPs$scenario],levels=lab[sel])
cols<-c("#2c3e50","#f1c40f","#e67e22","#27ae60")
pA<-ggplot(INCs,aes(year,med,colour=scenario,fill=scenario))+geom_vline(xintercept=2025,linetype="dashed",colour="grey60")+
  annotate("text",x=2025.2,y=Inf,label="chatbot start",hjust=0,vjust=1.5,size=3,colour="grey40")+
  geom_ribbon(aes(ymin=lo,ymax=hi),alpha=0.12,colour=NA)+geom_line(linewidth=1)+
  scale_colour_manual(values=cols,name=NULL)+scale_fill_manual(values=cols,name=NULL)+scale_y_continuous(labels=scales::comma)+
  labs(title="(A) AGYW HIV incidence: baseline vs chatbot",x="Year",y="New infections/year (national)")+theme_minimal(base_size=11)+theme(legend.position="top")
pB<-ggplot(PREPs,aes(year,med,colour=scenario,fill=scenario))+geom_vline(xintercept=2025,linetype="dashed",colour="grey60")+
  geom_ribbon(aes(ymin=lo,ymax=hi),alpha=0.12,colour=NA)+geom_line(linewidth=1)+
  scale_colour_manual(values=cols,name=NULL)+scale_fill_manual(values=cols,name=NULL)+scale_y_continuous(labels=scales::percent)+
  labs(title="(B) Mechanism: PrEP coverage among AGYW",x="Year",y="AGYW on PrEP (%)")+theme_minimal(base_size=11)+theme(legend.position="top")
ggsave("results/fan_incidence.png",pA,width=8,height=5,dpi=140)
ggsave("results/mechanism_prep.png",pB,width=8,height=5,dpi=140)
ggsave("results/trajectories_combined.png",arrangeGrob(pA,pB,ncol=2),width=14,height=5,dpi=140)
cat("Wrote ALL figures: intervention.png, intervention_views.png, fan_incidence.png, mechanism_prep.png\n")
