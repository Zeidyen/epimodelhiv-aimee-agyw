## 10_model_het.R
## Step 1a: make the gallery HIV+PrEP base HETEROSEXUAL.
##
## Adds a time-invariant `sex` vertex attribute and constrains both partnership
## layers to opposite-sex pairs via an offset(nodematch("sex")) term with
## coefficient -Inf (forbids same-sex edges exactly). The base disease/cascade/
## PrEP/transmission modules are reused unchanged; heterosexual structure comes
## entirely from the network. (Age structure is added in step 1b.)
##
## Run from repo root:  Rscript R/10_model_het.R

suppressMessages(library(EpiModel))

this_dir <- tryCatch({
  a <- commandArgs(FALSE); f <- sub("^--file=", "", a[grep("^--file=", a)])
  if (length(f)) dirname(normalizePath(f)) else "."
}, error = function(e) ".")
source(file.path(this_dir, "base_model", "module-fx.R"))   # progress/cascade/prep/infect/dfunc/afunc

set.seed(10)
N      <- 600
nsteps <- 120
nsims  <- 2
prop_male <- 0.5

# ---- Network with a heterosexual constraint --------------------------------
nw  <- network_initialize(N)
sex <- rbinom(N, 1, prop_male)                    # 1 = male, 0 = female
nw  <- set_vertex_attribute(nw, "sex", sex)

departure_rate <- 0.0005

# offset(nodematch("sex")) with coef -Inf => same-sex edges impossible.
# target.stats are for the NON-offset terms only, in order.
formation_main <- ~edges + offset(nodematch("sex")) + concurrent + degrange(from = 3)
target_main    <- c(0.5 * N / 2, round(0.04 * N), 0)
diss_main      <- dissolution_coefs(~offset(edges), duration = 200, d.rate = departure_rate)
est_main <- netest(nw, formation_main, target_main, diss_main,
                   coef.form = -Inf, verbose = FALSE)

formation_cas <- ~edges + offset(nodematch("sex")) + concurrent
target_cas    <- c(0.3 * N / 2, round(0.10 * N))
diss_cas      <- dissolution_coefs(~offset(edges), duration = 26, d.rate = departure_rate)
est_cas <- netest(nw, formation_cas, target_cas, diss_cas,
                  coef.form = -Inf, verbose = FALSE)

# ---- Arrivals must assign sex to new nodes ---------------------------------
afunc_het <- function(dat, at) {
  active <- get_attr(dat, "active")
  a.rate <- get_param(dat, "arrival.rate")
  nArr <- rpois(1, sum(active == 1) * a.rate)
  if (nArr > 0) {
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
    dat <- append_attr(dat, "sex", rbinom(nArr, 1, get_param(dat, "prop.male")), nArr)
  }
  dat <- set_epi(dat, "arr.flow", at, nArr)
  return(dat)
}

# ---- Params / init / control ----------------------------------------------
param <- param.net(
  inf.prob.act = 0.0025, rel.inf.acute = 5, rel.inf.aids = 2,
  rel.inf.art.unsupp = 0.30, rel.inf.art.supp = 0.01, prep.efficacy = 0.95,
  acts.main = 3, acts.casual = 1,
  acute.to.chronic.rate = 1/12, chronic.to.aids.rate = 1/520, aids.depart.rate = 1/104,
  art.prog.mult = 0.5, art.aids.surv.mult = 0.1,
  test.rate = 0.01, aids.dx.rate = 0.05, linkage.rate = 0.5,
  art.reinit.rate = 0.1, suppression.rate = 0.3, art.disc.rate = 0.01,
  prep.init.cov = 0, prep.start.rate = 0, prep.stop.rate = 0.01, prep.indic.deg = 2,
  departure.rate = departure_rate, arrival.rate = 0.00065,
  prop.male = prop_male                       # used by afunc_het for arrivals
)
init <- init.net(i.num = round(0.08 * N))
control <- control.net(
  type = NULL, nsims = nsims, ncores = 1, nsteps = nsteps,
  tergmLite = TRUE, resimulate.network = TRUE,
  infection.FUN = infect, progress.FUN = progress, cascade.FUN = cascade,
  prep.FUN = prep, departures.FUN = dfunc, arrivals.FUN = afunc_het,
  verbose = FALSE
)

cat("Running heterosexual base model...\n")
sim <- netsim(list(est_main, est_cas), param, init, control)

# ---- Verify heterosexual structure on the fitted ERGMs ---------------------
# tergmLite discards the full network during netsim, so check the constraint
# directly: simulate many networks from each fitted layer and count same-sex ties.
check_layer <- function(est, label) {
  ss <- 0; tot <- 0
  for (i in 1:10) {
    nwc <- simulate(est$fit, control = control.simulate.ergm(MCMC.burnin = 1e5))
    el  <- as.edgelist(nwc)
    sx  <- nwc %v% "sex"
    if (nrow(el) > 0) { ss <- ss + sum(sx[el[, 1]] == sx[el[, 2]]); tot <- tot + nrow(el) }
  }
  cat(sprintf("  %-6s: %d edges across 10 sims, %d same-sex (should be 0)\n", label, tot, ss))
  ss
}
cat("\n=== Heterosexual check (simulated from fitted ERGMs) ===\n")
ss_main <- check_layer(est_main, "main")
ss_cas  <- check_layer(est_cas,  "casual")
df <- as.data.frame(sim)
cat(sprintf("Cumulative infections (mean over sims): %.0f\n",
            sum(df$si.flow, na.rm = TRUE) / nsims))
cat(sprintf("Heterosexual constraint holds: %s\n", (ss_main + ss_cas) == 0))
