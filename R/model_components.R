## model_components.R
## Reusable heterosexual, age-disparate, AGYW-targeted HIV+PrEP model components,
## extracted from the verified R/10-12 scripts so the calibration loop (R/20) can
## call the model with different parameters. Built on the EpiModel-Gallery base
## modules (R/base_model/module-fx.R: progress/cascade/prep/infect/dfunc).

suppressMessages(library(EpiModel))

.MC_DIR <- tryCatch({
  a <- commandArgs(FALSE); f <- sub("^--file=", "", a[grep("^--file=", a)])
  if (length(f)) dirname(normalizePath(f)) else "."
}, error = function(e) ".")
source(file.path(.MC_DIR, "base_model", "module-fx.R"))

AGE_MIN <- 15; AGE_OUT <- 50; WKS_YR <- 52
prefage_of  <- function(age, sex, gap) age + gap * (sex == 0)
is_agyw_vec <- function(sex, age, active) active == 1 & sex == 0 & age >= 15 & age < 25

# ---- Network builder: heterosexual + age-disparate -------------------------
# mix_main/mix_cas = mean |pref.age difference| target (years). LARGER = wider
# age mixing = AGYW get a realistic tail of much-older ("blesser") partners,
# exposing the youngest women to the high-prevalence older-men pool.
build_hetage_network <- function(N, age_gap = 5, deg_main = 0.5, deg_cas = 0.3,
                                 conc_main = 0.04, conc_cas = 0.10,
                                 mix_main = 3, mix_cas = 4,
                                 dur_main = 200, dur_cas = 26, prop_male = 0.5,
                                 drate = 0.0005) {
  nw  <- network_initialize(N)
  sex <- rbinom(N, 1, prop_male)
  age <- runif(N, AGE_MIN, AGE_OUT)
  nw  <- set_vertex_attribute(nw, "sex", sex)
  nw  <- set_vertex_attribute(nw, "age", age)
  nw  <- set_vertex_attribute(nw, "pref.age", prefage_of(age, sex, age_gap))
  f <- ~edges + offset(nodematch("sex")) + concurrent + absdiff("pref.age")
  est_main <- netest(nw, f, c(deg_main * N / 2, round(conc_main * N), (deg_main * N / 2) * mix_main),
                     dissolution_coefs(~offset(edges), dur_main, drate),
                     coef.form = -Inf, verbose = FALSE)
  est_cas  <- netest(nw, f, c(deg_cas * N / 2, round(conc_cas * N), (deg_cas * N / 2) * mix_cas),
                     dissolution_coefs(~offset(edges), dur_cas, drate),
                     coef.form = -Inf, verbose = FALSE)
  list(est_main = est_main, est_cas = est_cas)
}

# ---- Modules (AGYW-targeted; from R/12, + age/sex-band prevalence tracking) -
.PREV_BANDS <- list(
  f_15_19 = c(0, 15, 19), f_20_24 = c(0, 20, 24),
  m_25_29 = c(1, 25, 29), m_30_34 = c(1, 30, 34),
  m_35_39 = c(1, 35, 39), m_40_44 = c(1, 40, 44))

# Full transmission module = gallery infect() logic + AGYW susceptibility
# multiplier (young women acquire at agyw.susc.mult x the per-act rate;
# biological + behavioural elevated risk) + age/sex-band tracking.
infect_track <- function(dat, at) {
  active <- get_attr(dat,"active"); status <- get_attr(dat,"status")
  stage <- get_attr(dat,"stage"); art.status <- get_attr(dat,"art.status")
  vl.supp <- get_attr(dat,"vl.supp"); prep.status <- get_attr(dat,"prep.status")
  infTime <- get_attr(dat,"infTime"); stage.time <- get_attr(dat,"stage.time")
  sex <- get_attr(dat,"sex"); age <- get_attr(dat,"age")

  ipa <- get_param(dat,"inf.prob.act"); ra <- get_param(dat,"rel.inf.acute")
  rd <- get_param(dat,"rel.inf.aids"); ru <- get_param(dat,"rel.inf.art.unsupp")
  rs <- get_param(dat,"rel.inf.art.supp"); pe <- get_param(dat,"prep.efficacy")
  acts <- c(get_param(dat,"acts.main"), get_param(dat,"acts.casual"))
  susc15 <- get_param(dat,"agyw.susc.15_19"); susc20 <- get_param(dat,"agyw.susc.20_24")

  all_new <- integer(0)
  for (k in 1:2) {
    del <- discord_edgelist(dat, at, network = k)
    if (is.null(del) || nrow(del) == 0) next
    stg <- stage[del$inf]; art <- art.status[del$inf]; sup <- vl.supp[del$inf]
    stage_mult <- ifelse(!is.na(stg)&stg=="acute", ra, ifelse(!is.na(stg)&stg=="aids", rd, 1))
    art_mult <- ifelse(art==1&sup==1, rs, ifelse(art==1&sup==0, ru, 1))
    p_act <- ipa * stage_mult * art_mult
    # susceptible-side: PrEP protection + age-graded young-women susceptibility
    # (15-19 carry the highest per-contact HIV acquisition risk, then 20-24).
    p_act <- p_act * ifelse(prep.status[del$sus]==1, 1-pe, 1)
    s_sex <- sex[del$sus]; s_age <- age[del$sus]
    smult <- rep(1, length(s_sex))
    smult[s_sex==0 & s_age>=15 & s_age<20] <- susc15
    smult[s_sex==0 & s_age>=20 & s_age<25] <- susc20
    p_act <- p_act * smult
    p_act <- pmax(pmin(p_act,1),0)
    p_edge <- 1 - (1-p_act)^acts[k]
    tr <- rbinom(length(p_edge),1,p_edge)==1
    if (any(tr)) all_new <- c(all_new, del$sus[tr])
  }
  all_new <- unique(all_new); n_new <- length(all_new)
  if (n_new > 0) {
    status[all_new] <- "i"; stage[all_new] <- "acute"; stage.time[all_new] <- 0L
    infTime[all_new] <- at; prep.status[all_new] <- 0L
    dat <- set_attr(dat,"status",status); dat <- set_attr(dat,"stage",stage)
    dat <- set_attr(dat,"stage.time",stage.time); dat <- set_attr(dat,"infTime",infTime)
    dat <- set_attr(dat,"prep.status",prep.status)
  }
  dat <- set_epi(dat,"si.flow",at,n_new)

  # ---- tracking ----
  agyw <- sex == 0 & age >= 15 & age < 25
  dat <- set_epi(dat, "incid.agyw", at, sum(active==1 & status=="i" & !is.na(infTime) & infTime==at & agyw))
  dat <- set_epi(dat, "agyw.py", at, sum(active==1 & agyw & status=="s"))
  for (nm in names(.PREV_BANDS)) {
    b <- .PREV_BANDS[[nm]]
    inb <- active==1 & sex==b[1] & age>=b[2] & age<=b[3]
    dat <- set_epi(dat, paste0("prev.",nm), at, if (sum(inb)>0) sum(inb & status=="i")/sum(inb) else NA_real_)
  }
  dat
}

aging_mod <- function(dat, at) {
  age <- get_attr(dat, "age"); sex <- get_attr(dat, "sex"); active <- get_attr(dat, "active")
  gap <- get_param(dat, "age.gap")
  if (is.null(get_attr(dat, "chatbot", override.null.error = TRUE))) {
    reach <- get_param(dat, "chatbot.reach")
    cb <- rep(0L, length(active)); w <- which(sex == 0)
    cb[w] <- rbinom(length(w), 1, reach)
    dat <- set_attr(dat, "chatbot", cb)
  }
  age <- age + 1 / WKS_YR
  dat <- set_attr(dat, "age", age)
  dat <- set_attr(dat, "pref.age", prefage_of(age, sex, gap))
  out <- which(active == 1 & age >= AGE_OUT)
  if (length(out) > 0) {
    active[out] <- 0L; dat <- set_attr(dat, "active", active)
    ex <- get_attr(dat, "exitTime"); ex[out] <- at; dat <- set_attr(dat, "exitTime", ex)
  }
  dat
}

afunc_hetage <- function(dat, at) {
  active <- get_attr(dat, "active")
  nArr <- rpois(1, sum(active == 1) * get_param(dat, "arrival.rate"))
  if (nArr > 0) {
    s <- rbinom(nArr, 1, get_param(dat, "prop.male"))
    cb <- ifelse(s == 0, rbinom(nArr, 1, get_param(dat, "chatbot.reach")), 0L)
    gap <- get_param(dat, "age.gap")
    dat <- append_core_attr(dat, at, nArr)
    dat <- append_attr(dat, "status", "s", nArr)
    dat <- append_attr(dat, "stage", NA_character_, nArr)
    dat <- append_attr(dat, "stage.time", NA_integer_, nArr)
    dat <- append_attr(dat, "infTime", NA_integer_, nArr)
    dat <- append_attr(dat, "diag.status", 0L, nArr)
    dat <- append_attr(dat, "art.status", 0L, nArr)
    dat <- append_attr(dat, "vl.supp", 0L, nArr)
    dat <- append_attr(dat, "art.time", NA_integer_, nArr)
    dat <- append_attr(dat, "prep.status", 0L, nArr)
    dat <- append_attr(dat, "sex", s, nArr)
    dat <- append_attr(dat, "age", rep(AGE_MIN, nArr), nArr)
    dat <- append_attr(dat, "pref.age", prefage_of(rep(AGE_MIN, nArr), s, gap), nArr)
    dat <- append_attr(dat, "chatbot", as.integer(cb), nArr)
  }
  dat <- set_epi(dat, "arr.flow", at, nArr)
  dat
}

cascade_agyw <- function(dat, at) {
  active <- get_attr(dat, "active"); status <- get_attr(dat, "status")
  stage <- get_attr(dat, "stage"); diag.status <- get_attr(dat, "diag.status")
  art.status <- get_attr(dat, "art.status"); vl.supp <- get_attr(dat, "vl.supp")
  art.time <- get_attr(dat, "art.time")
  sex <- get_attr(dat, "sex"); age <- get_attr(dat, "age"); chatbot <- get_attr(dat, "chatbot")
  test.rate <- get_param(dat, "test.rate"); aids.dx.rate <- get_param(dat, "aids.dx.rate")
  linkage.rate <- get_param(dat, "linkage.rate"); art.reinit.rate <- get_param(dat, "art.reinit.rate")
  suppression.rate <- get_param(dat, "suppression.rate"); art.disc.rate <- get_param(dat, "art.disc.rate")
  rr <- get_param(dat, "chatbot.test.rr")
  diag0 <- diag.status; art0 <- art.status; supp0 <- vl.supp
  is_inf <- active == 1 & status == "i"
  trv <- rep(test.rate, length(active))
  trv[is_agyw_vec(sex, age, active) & chatbot == 1] <- pmin(1, test.rate * rr)
  idsu <- which(is_inf & diag0 == 0)
  if (length(idsu) > 0) {
    rates <- ifelse(!is.na(stage[idsu]) & stage[idsu] == "aids", aids.dx.rate, trv[idsu])
    nd <- idsu[rbinom(length(idsu), 1, rates) == 1]; if (length(nd)) diag.status[nd] <- 1L
  }
  iln <- which(is_inf & diag0 == 1 & art0 == 0 & is.na(art.time))
  if (length(iln)) { h <- iln[rbinom(length(iln),1,linkage.rate)==1]; if(length(h)){art.status[h]<-1L;art.time[h]<-at} }
  ilr <- which(is_inf & diag0 == 1 & art0 == 0 & !is.na(art.time))
  if (length(ilr)) { h <- ilr[rbinom(length(ilr),1,art.reinit.rate)==1]; if(length(h)){art.status[h]<-1L;art.time[h]<-at} }
  isu <- which(is_inf & art0 == 1 & supp0 == 0)
  if (length(isu)) { h <- isu[rbinom(length(isu),1,suppression.rate)==1]; if(length(h)) vl.supp[h]<-1L }
  idc <- which(is_inf & art0 == 1)
  if (length(idc)) { h <- idc[rbinom(length(idc),1,art.disc.rate)==1]; if(length(h)){art.status[h]<-0L;vl.supp[h]<-0L} }
  dat <- set_attr(dat,"diag.status",diag.status); dat <- set_attr(dat,"art.status",art.status)
  dat <- set_attr(dat,"vl.supp",vl.supp); dat <- set_attr(dat,"art.time",art.time)
  dat <- set_epi(dat,"supp.num",at,sum(is_inf & vl.supp==1))
  dat
}

prep_agyw <- function(dat, at) {
  active <- get_attr(dat,"active"); status <- get_attr(dat,"status"); prep.status <- get_attr(dat,"prep.status")
  sex <- get_attr(dat,"sex"); age <- get_attr(dat,"age"); chatbot <- get_attr(dat,"chatbot")
  prep.init.cov <- get_param(dat,"prep.init.cov"); prep.start.rate <- get_param(dat,"prep.start.rate")
  prep.stop.rate <- get_param(dat,"prep.stop.rate"); prep.indic.deg <- get_param(dat,"prep.indic.deg")
  rr <- get_param(dat,"chatbot.prep.rr")
  n <- length(active); td <- integer(n); pp <- logical(n)
  for (k in 1:2) {
    el <- get_edgelist(dat, network = k); if (is.null(el) || nrow(el)==0) next
    td <- td + get_degree(el)
    pp[el[,2][status[el[,1]]=="i"]] <- TRUE; pp[el[,1][status[el[,2]]=="i"]] <- TRUE
  }
  agyw <- is_agyw_vec(sex, age, active)
  indic <- active==1 & status=="s" & (td>=prep.indic.deg | pp | (agyw & chatbot==1))
  ni <- is.na(prep.status) & active==1
  if (any(ni)) { prep.status[ni] <- 0L
    if (prep.init.cov>0){ii<-which(ni&indic); if(length(ii)) prep.status[ii]<-rbinom(length(ii),1,prep.init.cov)} }
  sv <- rep(prep.start.rate, n); sv[agyw & chatbot==1] <- pmin(1, prep.start.rate*rr)
  io <- which(indic & prep.status==0)
  if (length(io)) { h<-rbinom(length(io),1,sv[io])==1; prep.status[io[h]]<-1L }
  if (prep.stop.rate>0){ on<-which(active==1&status=="s"&prep.status==1); if(length(on)) prep.status[on[rbinom(length(on),1,prep.stop.rate)==1]]<-0L }
  dat <- set_attr(dat,"prep.status",prep.status)
  dat <- set_epi(dat,"prep.agyw",at,sum(agyw & prep.status==1))
  dat
}

# ---- Parameter constructor + run helper ------------------------------------
hetage_param <- function(inf.prob.act = 0.0025, age.gap = 5,
                         agyw.susc.15_19 = 1, agyw.susc.20_24 = 1,
                         test.rate = 0.01, prep.init.cov = 0.02, prep.start.rate = 0.005,
                         chatbot.reach = 0, chatbot.test.rr = 1, chatbot.prep.rr = 1,
                         prop.male = 0.5, arrival.rate = 0.0010, ...) {
  param.net(
    inf.prob.act = inf.prob.act,
    agyw.susc.15_19 = agyw.susc.15_19, agyw.susc.20_24 = agyw.susc.20_24,
    rel.inf.acute = 5, rel.inf.aids = 2,
    rel.inf.art.unsupp = 0.30, rel.inf.art.supp = 0.01, prep.efficacy = 0.95,
    acts.main = 3, acts.casual = 1,
    acute.to.chronic.rate = 1/12, chronic.to.aids.rate = 1/520, aids.depart.rate = 1/104,
    art.prog.mult = 0.5, art.aids.surv.mult = 0.1,
    test.rate = test.rate, aids.dx.rate = 0.05, linkage.rate = 0.5,
    art.reinit.rate = 0.1, suppression.rate = 0.3, art.disc.rate = 0.01,
    prep.init.cov = prep.init.cov, prep.start.rate = prep.start.rate,
    prep.stop.rate = 0.01, prep.indic.deg = 2,
    departure.rate = 0.0005, arrival.rate = arrival.rate, prop.male = prop.male,
    age.gap = age.gap,
    chatbot.reach = chatbot.reach, chatbot.test.rr = chatbot.test.rr,
    chatbot.prep.rr = chatbot.prep.rr, ...)
}

run_hetage <- function(param, ests, N, nsteps, nsims = 1, i.num = NULL) {
  ctrl <- control.net(type = NULL, nsims = nsims, ncores = 1, nsteps = nsteps,
    tergmLite = TRUE, resimulate.network = TRUE,
    aging.FUN = aging_mod, infection.FUN = infect_track, progress.FUN = progress,
    cascade.FUN = cascade_agyw, prep.FUN = prep_agyw,
    departures.FUN = dfunc, arrivals.FUN = afunc_hetage, verbose = FALSE)
  if (is.null(i.num)) i.num <- round(0.08 * N)
  netsim(list(ests$est_main, ests$est_cas), param, init.net(i.num = i.num), ctrl)
}

# Equilibrium prevalence by band = mean over the last `tail_steps` steps,
# averaged across simulations (out="mean") to reduce stochastic noise.
equil_prev <- function(sim, tail_steps = 52) {
  df <- tryCatch(as.data.frame(sim, out = "mean"), error = function(e) as.data.frame(sim))
  out <- list()
  for (nm in names(.PREV_BANDS)) {
    col <- paste0("prev.", nm)
    if (col %in% names(df)) out[[nm]] <- mean(tail(df[[col]], tail_steps), na.rm = TRUE)
  }
  out
}
