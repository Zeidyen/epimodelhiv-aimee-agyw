## diagnostic.R — understand why baseline prevalence collapses.
## Runs a few transmission levels with rich trajectory + population diagnostics.

source(file.path(
  tryCatch({a<-commandArgs(FALSE);f<-sub("^--file=","",a[grep("^--file=",a)])
            if(length(f)) dirname(normalizePath(f)) else "."}, error=function(e) "."),
  "model_components.R"))

# richer tracker: population, overall prevalence, AGYW prev, mean age, sex ratio
diag_prev <- function(dat, at) {
  active <- get_attr(dat,"active"); status <- get_attr(dat,"status")
  sex <- get_attr(dat,"sex"); age <- get_attr(dat,"age")
  a <- active==1
  dat <- set_epi(dat,"num",at,sum(a))
  dat <- set_epi(dat,"prev.all",at, if(sum(a)) sum(a & status=="i")/sum(a) else NA)
  agyw <- a & sex==0 & age>=15 & age<25
  dat <- set_epi(dat,"prev.agyw",at, if(sum(agyw)) sum(agyw & status=="i")/sum(agyw) else NA)
  ow <- a & sex==0 & age>=25
  dat <- set_epi(dat,"prev.ow",at, if(sum(ow)) sum(ow & status=="i")/sum(ow) else NA)
  dat <- set_epi(dat,"mean.age",at, mean(age[a],na.rm=TRUE))
  dat <- set_epi(dat,"frac.f",at, mean(sex[a]==0))
  dat
}

run_diag <- function(beta, N=1500, yr=25) {
  ests <- build_hetage_network(N, age_gap=5, deg_main=0.5, deg_cas=0.35)
  p <- hetage_param(inf.prob.act=beta)
  ctrl <- control.net(type=NULL, nsims=1, ncores=1, nsteps=yr*52,
    tergmLite=TRUE, resimulate.network=TRUE,
    aging.FUN=aging_mod, infection.FUN=infect_track, progress.FUN=progress,
    cascade.FUN=cascade_agyw, prep.FUN=prep_agyw, departures.FUN=dfunc,
    arrivals.FUN=afunc_hetage, prevalence.FUN=diag_prev, verbose=FALSE)
  netsim(list(ests$est_main, ests$est_cas), p, init.net(i.num=round(0.08*N)), ctrl)
}

set.seed(30)
for (beta in c(0.006, 0.015, 0.030)) {
  sim <- run_diag(beta)
  df <- as.data.frame(sim)
  cat(sprintf("\n=== inf.prob.act = %.3f ===\n", beta))
  cat("  yr   pop   prev.all  prev.AGYW  prev.OW(25+)  meanAge  %F\n")
  for (y in c(1,5,10,15,20,25)) {
    i <- min(y*52, nrow(df))
    cat(sprintf("  %2d  %5.0f   %6.3f    %6.3f     %6.3f      %4.1f   %.2f\n",
      y, df$num[i], df$prev.all[i], df$prev.agyw[i], df$prev.ow[i], df$mean.age[i], df$frac.f[i]))
  }
}
