## 12_model_het_agyw_intervention.R
## Step 1c: target the chatbot intervention to AGYW (women 15-24).
##
## The chatbot is a persistent "Aimee user" flag assigned among women with
## probability = chatbot.reach. While a user is AGYW (15-24) her HIV-testing
## rate and PrEP-initiation rate are boosted (chatbot.test.rr, chatbot.prep.rr).
## Baseline scenario sets reach = 0 (no effect).
##
## Implemented as AGYW-aware copies of the base cascade and prep modules
## (per-person rates) + an infect wrapper that records AGYW incidence.
##
## Run:  Rscript R/12_model_het_agyw_intervention.R

suppressMessages(library(EpiModel))

this_dir <- tryCatch({
  a <- commandArgs(FALSE); f <- sub("^--file=", "", a[grep("^--file=", a)])
  if (length(f)) dirname(normalizePath(f)) else "."
}, error = function(e) ".")
source(file.path(this_dir, "base_model", "module-fx.R"))   # progress/cascade/prep/infect/dfunc

set.seed(12)
N <- 800; nsteps <- 156; nsims <- 3
PROP_MALE <- 0.5; AGE_MIN <- 15; AGE_OUT <- 50; AGE_GAP <- 5; WKS_YR <- 52

prefage_of <- function(age, sex) age + AGE_GAP * (sex == 0)
is_agyw_vec <- function(sex, age, active) active == 1 & sex == 0 & age >= 15 & age < 25

# ---------- AGYW-targeted cascade (per-person testing rate) ------------------
cascade_agyw <- function(dat, at) {
  active <- get_attr(dat, "active"); status <- get_attr(dat, "status")
  stage <- get_attr(dat, "stage"); diag.status <- get_attr(dat, "diag.status")
  art.status <- get_attr(dat, "art.status"); vl.supp <- get_attr(dat, "vl.supp")
  art.time <- get_attr(dat, "art.time")
  sex <- get_attr(dat, "sex"); age <- get_attr(dat, "age"); chatbot <- get_attr(dat, "chatbot")

  test.rate <- get_param(dat, "test.rate"); aids.dx.rate <- get_param(dat, "aids.dx.rate")
  linkage.rate <- get_param(dat, "linkage.rate"); art.reinit.rate <- get_param(dat, "art.reinit.rate")
  suppression.rate <- get_param(dat, "suppression.rate"); art.disc.rate <- get_param(dat, "art.disc.rate")
  chatbot.test.rr <- get_param(dat, "chatbot.test.rr")

  diag0 <- diag.status; art0 <- art.status; supp0 <- vl.supp
  is_inf <- active == 1 & status == "i"

  # per-person testing rate: reached AGYW get the boosted rate
  test.rate.vec <- rep(test.rate, length(active))
  boost <- is_agyw_vec(sex, age, active) & chatbot == 1
  test.rate.vec[boost] <- pmin(1, test.rate * chatbot.test.rr)

  ids_undx <- which(is_inf & diag0 == 0)
  if (length(ids_undx) > 0) {
    rates <- ifelse(!is.na(stage[ids_undx]) & stage[ids_undx] == "aids",
                    aids.dx.rate, test.rate.vec[ids_undx])
    new_dx <- ids_undx[rbinom(length(ids_undx), 1, rates) == 1]
    if (length(new_dx) > 0) diag.status[new_dx] <- 1L
  }
  ids_link_new <- which(is_inf & diag0 == 1 & art0 == 0 & is.na(art.time))
  if (length(ids_link_new) > 0) {
    nl <- ids_link_new[rbinom(length(ids_link_new), 1, linkage.rate) == 1]
    if (length(nl) > 0) { art.status[nl] <- 1L; art.time[nl] <- at }
  }
  ids_link_re <- which(is_inf & diag0 == 1 & art0 == 0 & !is.na(art.time))
  if (length(ids_link_re) > 0) {
    rr <- ids_link_re[rbinom(length(ids_link_re), 1, art.reinit.rate) == 1]
    if (length(rr) > 0) { art.status[rr] <- 1L; art.time[rr] <- at }
  }
  ids_sup <- which(is_inf & art0 == 1 & supp0 == 0)
  if (length(ids_sup) > 0) {
    ns <- ids_sup[rbinom(length(ids_sup), 1, suppression.rate) == 1]
    if (length(ns) > 0) vl.supp[ns] <- 1L
  }
  ids_disc <- which(is_inf & art0 == 1)
  if (length(ids_disc) > 0) {
    dc <- ids_disc[rbinom(length(ids_disc), 1, art.disc.rate) == 1]
    if (length(dc) > 0) { art.status[dc] <- 0L; vl.supp[dc] <- 0L }
  }
  dat <- set_attr(dat, "diag.status", diag.status); dat <- set_attr(dat, "art.status", art.status)
  dat <- set_attr(dat, "vl.supp", vl.supp); dat <- set_attr(dat, "art.time", art.time)
  dat <- set_epi(dat, "dx.flow", at, sum(diag.status == 1 & diag0 == 0))
  dat <- set_epi(dat, "supp.num", at, sum(is_inf & vl.supp == 1))
  return(dat)
}

# ---------- AGYW-targeted PrEP (eligibility + per-person start rate) ---------
prep_agyw <- function(dat, at) {
  active <- get_attr(dat, "active"); status <- get_attr(dat, "status")
  prep.status <- get_attr(dat, "prep.status")
  sex <- get_attr(dat, "sex"); age <- get_attr(dat, "age"); chatbot <- get_attr(dat, "chatbot")
  prep.init.cov <- get_param(dat, "prep.init.cov"); prep.start.rate <- get_param(dat, "prep.start.rate")
  prep.stop.rate <- get_param(dat, "prep.stop.rate"); prep.indic.deg <- get_param(dat, "prep.indic.deg")
  chatbot.prep.rr <- get_param(dat, "chatbot.prep.rr")

  n <- length(active); total_deg <- integer(n); has_pos_partner <- logical(n)
  for (k in 1:2) {
    el <- get_edgelist(dat, network = k)
    if (is.null(el) || nrow(el) == 0) next
    total_deg <- total_deg + get_degree(el)
    has_pos_partner[el[, 2][status[el[, 1]] == "i"]] <- TRUE
    has_pos_partner[el[, 1][status[el[, 2]] == "i"]] <- TRUE
  }
  agyw <- is_agyw_vec(sex, age, active)
  # reached AGYW are PrEP-indicated (SA AGYW are a priority population)
  indicated <- active == 1 & status == "s" &
               (total_deg >= prep.indic.deg | has_pos_partner | (agyw & chatbot == 1))

  needs_init <- is.na(prep.status) & active == 1
  if (any(needs_init)) {
    prep.status[needs_init] <- 0L
    if (prep.init.cov > 0) {
      ids_init <- which(needs_init & indicated)
      if (length(ids_init) > 0) prep.status[ids_init] <- rbinom(length(ids_init), 1, prep.init.cov)
    }
  }
  # per-person initiation rate: reached AGYW boosted
  start.vec <- rep(prep.start.rate, n)
  start.vec[agyw & chatbot == 1] <- pmin(1, prep.start.rate * chatbot.prep.rr)
  ids_off <- which(indicated & prep.status == 0)
  if (length(ids_off) > 0) {
    hits <- rbinom(length(ids_off), 1, start.vec[ids_off]) == 1
    prep.status[ids_off[hits]] <- 1L
  }
  if (prep.stop.rate > 0) {
    ids_on <- which(active == 1 & status == "s" & prep.status == 1)
    if (length(ids_on) > 0) prep.status[ids_on[rbinom(length(ids_on), 1, prep.stop.rate) == 1]] <- 0L
  }
  dat <- set_attr(dat, "prep.status", prep.status)
  dat <- set_epi(dat, "prep.num", at, sum(active == 1 & status == "s" & prep.status == 1))
  dat <- set_epi(dat, "prep.agyw", at, sum(agyw & prep.status == 1))
  return(dat)
}

# ---------- infect wrapper: record AGYW incidence right after infection ------
infect_agyw <- function(dat, at) {
  dat <- infect(dat, at)
  sex <- get_attr(dat, "sex"); age <- get_attr(dat, "age")
  active <- get_attr(dat, "active"); status <- get_attr(dat, "status")
  infTime <- get_attr(dat, "infTime")
  new_inf <- active == 1 & status == "i" & !is.na(infTime) & infTime == at
  agyw <- sex == 0 & age >= 15 & age < 25
  dat <- set_epi(dat, "incid.agyw", at, sum(new_inf & agyw))
  dat <- set_epi(dat, "agyw.num", at, sum(active == 1 & agyw))
  return(dat)
}

# ---------- aging + chatbot init (first call) + age-out ----------------------
aging <- function(dat, at) {
  age <- get_attr(dat, "age"); sex <- get_attr(dat, "sex"); active <- get_attr(dat, "active")
  if (is.null(get_attr(dat, "chatbot", override.null.error = TRUE))) {
    reach <- get_param(dat, "chatbot.reach")
    cb <- rep(0L, length(active))
    women <- which(sex == 0)
    cb[women] <- rbinom(length(women), 1, reach)   # Aimee user among women
    dat <- set_attr(dat, "chatbot", cb)
  }
  age <- age + 1 / WKS_YR
  dat <- set_attr(dat, "age", age)
  dat <- set_attr(dat, "pref.age", prefage_of(age, sex))
  aged_out <- which(active == 1 & age >= AGE_OUT)
  if (length(aged_out) > 0) {
    active[aged_out] <- 0L; dat <- set_attr(dat, "active", active)
    ex <- get_attr(dat, "exitTime"); ex[aged_out] <- at; dat <- set_attr(dat, "exitTime", ex)
  }
  return(dat)
}

afunc_agyw <- function(dat, at) {
  active <- get_attr(dat, "active")
  nArr <- rpois(1, sum(active == 1) * get_param(dat, "arrival.rate"))
  if (nArr > 0) {
    s <- rbinom(nArr, 1, get_param(dat, "prop.male"))
    cb <- ifelse(s == 0, rbinom(nArr, 1, get_param(dat, "chatbot.reach")), 0L)
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
    dat <- append_attr(dat, "pref.age", prefage_of(rep(AGE_MIN, nArr), s), nArr)
    dat <- append_attr(dat, "chatbot", as.integer(cb), nArr)
  }
  dat <- set_epi(dat, "arr.flow", at, nArr)
  return(dat)
}

# ---- Network (heterosexual + age-disparate) --------------------------------
nw <- network_initialize(N)
sex <- rbinom(N, 1, PROP_MALE); age <- runif(N, AGE_MIN, AGE_OUT)
nw <- set_vertex_attribute(nw, "sex", sex)
nw <- set_vertex_attribute(nw, "age", age)
nw <- set_vertex_attribute(nw, "pref.age", prefage_of(age, sex))
drate <- 0.0005
f_main <- ~edges + offset(nodematch("sex")) + concurrent + absdiff("pref.age")
est_main <- netest(nw, f_main, c(0.5*N/2, round(0.04*N), (0.5*N/2)*3),
                   dissolution_coefs(~offset(edges), 200, drate), coef.form = -Inf, verbose = FALSE)
f_cas <- ~edges + offset(nodematch("sex")) + concurrent + absdiff("pref.age")
est_cas <- netest(nw, f_cas, c(0.3*N/2, round(0.10*N), (0.3*N/2)*4),
                  dissolution_coefs(~offset(edges), 26, drate), coef.form = -Inf, verbose = FALSE)

base_param <- list(
  inf.prob.act = 0.0025, rel.inf.acute = 5, rel.inf.aids = 2,
  rel.inf.art.unsupp = 0.30, rel.inf.art.supp = 0.01, prep.efficacy = 0.95,
  acts.main = 3, acts.casual = 1,
  acute.to.chronic.rate = 1/12, chronic.to.aids.rate = 1/520, aids.depart.rate = 1/104,
  art.prog.mult = 0.5, art.aids.surv.mult = 0.1,
  test.rate = 0.01, aids.dx.rate = 0.05, linkage.rate = 0.5,
  art.reinit.rate = 0.1, suppression.rate = 0.3, art.disc.rate = 0.01,
  prep.init.cov = 0.02, prep.start.rate = 0.005, prep.stop.rate = 0.01, prep.indic.deg = 2,
  departure.rate = drate, arrival.rate = 0.0010, prop.male = PROP_MALE)

run_scn <- function(reach, test.rr, prep.rr, label) {
  p <- do.call(param.net, c(base_param,
        list(chatbot.reach = reach, chatbot.test.rr = test.rr, chatbot.prep.rr = prep.rr)))
  ctrl <- control.net(type = NULL, nsims = nsims, ncores = 1, nsteps = nsteps,
    tergmLite = TRUE, resimulate.network = TRUE,
    aging.FUN = aging, infection.FUN = infect_agyw, progress.FUN = progress,
    cascade.FUN = cascade_agyw, prep.FUN = prep_agyw,
    departures.FUN = dfunc, arrivals.FUN = afunc_agyw, verbose = FALSE)
  cat(sprintf("  running: %s\n", label))
  netsim(list(est_main, est_cas), p, init.net(i.num = round(0.08*N)), ctrl)
}

cat("Running AGYW intervention scenarios...\n")
s_base <- run_scn(0.0, 1, 1, "baseline (no chatbot)")
s_chat <- run_scn(0.30, 1.6, 2.0, "chatbot (reach 30%, testing x1.6, PrEP x2.0)")

agyw_inf <- function(s) sum(as.data.frame(s)$incid.agyw, na.rm = TRUE) / nsims
ib <- agyw_inf(s_base); ic <- agyw_inf(s_chat)
cat("\n=== AGYW infections (mean per sim over full run) ===\n")
cat(sprintf("  baseline:           %.1f\n", ib))
cat(sprintf("  chatbot scenario:   %.1f\n", ic))
cat(sprintf("  AGYW infections averted: %.1f  (%.0f%%)\n", ib - ic, 100*(ib-ic)/max(ib,1e-9)))
db <- as.data.frame(s_base); dc <- as.data.frame(s_chat)
cat(sprintf("  PrEP among AGYW (end): base %.0f -> chatbot %.0f\n",
            tail(na.omit(db$prep.agyw),1), tail(na.omit(dc$prep.agyw),1)))
