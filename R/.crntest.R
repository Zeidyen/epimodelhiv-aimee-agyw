d <- dirname(normalizePath(sub("^--file=","",commandArgs(FALSE)[grep("^--file=",commandArgs(FALSE))])))
source(file.path(d,"model_components.R")); source(file.path(d,"calibrated_params.R"))
CP<-CALIBRATED; FY<-CP$first.year; ST<-CP$burnin.year*52+1
cascade_int<-function(dat,at){p<-dat$param;yr<-p$first.year+(at-1)/52;s0<-p$art.start.year;s1<-p$art.full.year
 asc<-if(yr<=s0)0 else if(yr>=s1)1 else (yr-s0)/(s1-s0);rr<-if(yr>=p$chatbot.start.year)p$chatbot.test.rr else 1
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
 isu<-which(is_inf&art0==1&supp0==0);if(length(isu)){h<-isu[rbinom(length(isu),1,suppression.rate)==1];if(length(h))vl.supp[h]<-1L}
 dat<-set_attr(dat,"diag.status",diag.status);dat<-set_attr(dat,"art.status",art.status);dat<-set_attr(dat,"vl.supp",vl.supp);dat<-set_attr(dat,"art.time",art.time);dat}
prep_int<-function(dat,at){p<-dat$param;yr<-p$first.year+(at-1)/52;rr<-if(yr>=p$chatbot.start.year)p$chatbot.prep.rr else 1
 active<-get_attr(dat,"active");status<-get_attr(dat,"status");prep.status<-get_attr(dat,"prep.status");sex<-get_attr(dat,"sex");age<-get_attr(dat,"age");chatbot<-get_attr(dat,"chatbot")
 prep.start.rate<-get_param(dat,"prep.start.rate");prep.stop.rate<-get_param(dat,"prep.stop.rate");prep.indic.deg<-get_param(dat,"prep.indic.deg");prep.init.cov<-get_param(dat,"prep.init.cov")
 n<-length(active);td<-integer(n);pp<-logical(n);for(k in 1:2){el<-get_edgelist(dat,network=k);if(is.null(el)||nrow(el)==0)next;td<-td+get_degree(el);pp[el[,2][status[el[,1]]=="i"]]<-TRUE;pp[el[,1][status[el[,2]]=="i"]]<-TRUE}
 agyw<-active==1&sex==0&age>=15&age<25;indic<-active==1&status=="s"&(td>=prep.indic.deg|pp|(agyw&chatbot==1))
 ni<-is.na(prep.status)&active==1;if(any(ni)){prep.status[ni]<-0L;if(prep.init.cov>0){ii<-which(ni&indic);if(length(ii))prep.status[ii]<-rbinom(length(ii),1,prep.init.cov)}}
 sv<-rep(prep.start.rate,n);sv[agyw&chatbot==1]<-pmin(1,prep.start.rate*rr);io<-which(indic&prep.status==0);if(length(io)){h<-rbinom(length(io),1,sv[io])==1;prep.status[io[h]]<-1L}
 if(prep.stop.rate>0){on<-which(active==1&status=="s"&prep.status==1);if(length(on))prep.status[on[rbinom(length(on),1,prep.stop.rate)==1]]<-0L}
 dat<-set_attr(dat,"prep.status",prep.status);dat}
runit<-function(reach,trr,prr,ests,N,nsims){set.seed(40)
 p<-hetage_param(inf.prob.act=CP$inf.prob.act,age.gap=CP$age.gap,acts.main=CP$acts.main,acts.casual=CP$acts.casual,agyw.susc.15_19=CP$agyw.susc.15_19,agyw.susc.20_24=CP$agyw.susc.20_24,seed.tick=ST,seed.prev=CP$seed.prev,chatbot.reach=reach,chatbot.test.rr=trr,chatbot.prep.rr=prr,first.year=FY,art.start.year=CP$art.start.year,art.full.year=CP$art.full.year,chatbot.start.year=2025)
 ctrl<-control.net(type=NULL,nsims=nsims,ncores=1,nsteps=(2035-FY)*52,tergmLite=TRUE,resimulate.network=TRUE,aging.FUN=aging_mod,infection.FUN=infect_track,progress.FUN=progress,cascade.FUN=cascade_int,prep.FUN=prep_int,departures.FUN=dfunc,arrivals.FUN=afunc_hetage,verbose=FALSE)
 netsim(list(ests$est_main,ests$est_cas),p,init.net(i.num=0),ctrl)}
cum<-function(sim){df<-as.data.frame(sim);s0<-(2025-FY)*52+1;s1<-(2035-FY)*52
 sapply(sort(unique(df$sim)),function(s){d<-df[df$sim==s,];w<-s0:min(s1,nrow(d));sum(d$incid.agyw[w],na.rm=TRUE)})}
set.seed(40);N<-700;ests<-build_hetage_network(N,age_gap=CP$age.gap,deg_main=CP$deg_main,deg_cas=CP$deg_cas,conc_main=CP$conc_main,conc_cas=CP$conc_cas,mix_main=CP$mix_main,mix_cas=CP$mix_cas)
b<-cum(runit(0,1,1,ests,N,6)); s<-cum(runit(0.5,2.11,2.22,ests,N,6))
cat("ncores=1 PAIRED check (raw model AGYW infections 2025-2035):\n")
cat("baseline per-sim:",round(b),"\n"); cat("reach50%opt per-sim:",round(s),"\n")
cat("averted per-sim (b-s):",round(b-s),"\n")
cat("--> if PAIRED, baseline[i]>=scenario[i] mostly, averted positive\n")
