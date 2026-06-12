## cascade_check.R — measure the model's current baseline care-cascade coverage
## (AGYW vs adults vs older men) at 2024, to compare with SA literature targets:
##   AGYW ~74% aware / ~68% suppressed; adults 90/91/94; men 25-34 ~66% suppressed.
## Run: Rscript R/cascade_check.R

source(file.path(
  tryCatch({a<-commandArgs(FALSE);f<-sub("^--file=","",a[grep("^--file=",a)])
            if(length(f)) dirname(normalizePath(f)) else "."}, error=function(e) "."),
  "model_components.R"))
source(file.path(dirname(normalizePath(sub("^--file=","",commandArgs(FALSE)[grep("^--file=",commandArgs(FALSE))]))), "calibrated_params.R"))
CP<-CALIBRATED; FY<-CP$first.year; ST<-CP$burnin.year*52+1

# time-varying ART cascade (no chatbot) + cascade-coverage tracker
cascade_tt <- function(dat, at) {
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
  dat<-set_attr(dat,"diag.status",diag.status);dat<-set_attr(dat,"art.status",art.status);dat<-set_attr(dat,"vl.supp",vl.supp);dat<-set_attr(dat,"art.time",art.time)
  # cascade coverage among HIV+ by group
  ds<-diag.status;ar<-art.status;sp<-vl.supp;sex<-get_attr(dat,"sex");age<-get_attr(dat,"age")
  grp<-list(agyw=active==1&sex==0&age>=15&age<25&status=="i",
            adult=active==1&age>=15&age<=49&status=="i",
            men2534=active==1&sex==1&age>=25&age<35&status=="i")
  for(nm in names(grp)){g<-grp[[nm]];d<-if(sum(g)>0)mean(ds[g])else NA;a<-if(sum(g)>0)sum(ar[g])/sum(g)else NA;s<-if(sum(g)>0)sum(sp[g])/sum(g)else NA
    dat<-set_epi(dat,paste0("dx.",nm),at,d);dat<-set_epi(dat,paste0("art.",nm),at,a);dat<-set_epi(dat,paste0("supp.",nm),at,s)}
  dat
}

set.seed(99); N<-2000
ests<-build_hetage_network(N,age_gap=CP$age.gap,deg_main=CP$deg_main,deg_cas=CP$deg_cas,conc_main=CP$conc_main,conc_cas=CP$conc_cas,mix_main=CP$mix_main,mix_cas=CP$mix_cas)
p<-hetage_param(inf.prob.act=CP$inf.prob.act,age.gap=CP$age.gap,acts.main=CP$acts.main,acts.casual=CP$acts.casual,
                agyw.susc.15_19=CP$agyw.susc.15_19,agyw.susc.20_24=CP$agyw.susc.20_24,seed.tick=ST,seed.prev=CP$seed.prev,
                first.year=FY,art.start.year=CP$art.start.year,art.full.year=CP$art.full.year)
ctrl<-control.net(type=NULL,nsims=3,ncores=3,nsteps=(2024-FY)*52,tergmLite=TRUE,resimulate.network=TRUE,
  aging.FUN=aging_mod,infection.FUN=infect_track,progress.FUN=progress,cascade.FUN=cascade_tt,prep.FUN=prep_agyw,
  departures.FUN=dfunc,arrivals.FUN=afunc_hetage,verbose=FALSE)
sim<-netsim(list(ests$est_main,ests$est_cas),p,init.net(i.num=0),ctrl)
df<-as.data.frame(sim,out="mean"); s<-(2022-FY)*52+26
cat("\n=== Model baseline care cascade, 2022 (% of HIV+ in group) ===\n")
cat(sprintf("            diagnosed   on-ART   suppressed\n"))
for(nm in c("agyw","adult","men2534"))
  cat(sprintf("  %-8s   %5.0f%%    %5.0f%%    %5.0f%%\n", nm, 100*df[[paste0("dx.",nm)]][s], 100*df[[paste0("art.",nm)]][s], 100*df[[paste0("supp.",nm)]][s]))
cat("\nSA targets: AGYW ~74%/--/68% ; adult 90%/91%/94% ; men25-34 --/--/66%\n")
