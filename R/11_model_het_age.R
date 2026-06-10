## 11_model_het_age.R
## Step 1b: add AGE + age-disparate mixing to the heterosexual base.
##
## Key ideas
##  - `age` (continuous years) + `agegrp` factor, both maintained over time.
##  - Directional age-disparate mixing via a "preferred match age":
##        pref.age = age + AGE_GAP * (female)
##    Shifting women's matching age UP by AGE_GAP, then making partnerships
##    assortative on pref.age (absdiff("pref.age") ~ 0), pairs a young woman
##    with a man ~AGE_GAP years older — the AGYW↔older-men bridge.
##  - An aging module increments age each step, refreshes agegrp + pref.age,
##    and ages people out of the sexually-active population at AGE_OUT.
##
## Run:  Rscript R/11_model_het_age.R

suppressMessages(library(EpiModel))

this_dir <- tryCatch({
  a <- commandArgs(FALSE); f <- sub("^--file=", "", a[grep("^--file=", a)])
  if (length(f)) dirname(normalizePath(f)) else "."
}, error = function(e) ".")
source(file.path(this_dir, "base_model", "module-fx.R"))

set.seed(11)
N        <- 600
nsteps   <- 120
nsims    <- 2
PROP_MALE <- 0.5
AGE_MIN  <- 15
AGE_OUT  <- 50          # leaves the sexually-active population
AGE_GAP  <- 5           # mean years a woman's male partner is older (placeholder)
WKS_YR   <- 52

agegrp_of <- function(age) cut(age, breaks = c(15, 20, 25, 35, 50),
                               right = FALSE, labels = c("15-19","20-24","25-34","35-49"))
prefage_of <- function(age, sex) age + AGE_GAP * (sex == 0)   # women shifted older

# ---- Network with heterosexual + age-disparate mixing ----------------------
nw  <- network_initialize(N)
sex <- rbinom(N, 1, PROP_MALE)
age <- runif(N, AGE_MIN, AGE_OUT)
nw  <- set_vertex_attribute(nw, "sex", sex)
nw  <- set_vertex_attribute(nw, "age", age)
nw  <- set_vertex_attribute(nw, "pref.age", prefage_of(age, sex))

departure_rate <- 0.0005

# offset(nodematch(sex)) = -Inf forbids same-sex; absdiff(pref.age) sets the
# age-disparate assortativity. Smaller target => tighter age matching.
formation_main <- ~edges + offset(nodematch("sex")) + concurrent + absdiff("pref.age")
nedges_main    <- 0.5 * N / 2
target_main    <- c(nedges_main, round(0.04 * N), nedges_main * 3)  # mean |pref.age diff| ~3y
diss_main      <- dissolution_coefs(~offset(edges), duration = 200, d.rate = departure_rate)
est_main <- netest(nw, formation_main, target_main, diss_main,
                   coef.form = -Inf, verbose = FALSE)

formation_cas <- ~edges + offset(nodematch("sex")) + concurrent + absdiff("pref.age")
nedges_cas     <- 0.3 * N / 2
target_cas     <- c(nedges_cas, round(0.10 * N), nedges_cas * 4)    # casual: looser age match
diss_cas       <- dissolution_coefs(~offset(edges), duration = 26, d.rate = departure_rate)
est_cas <- netest(nw, formation_cas, target_cas, diss_cas,
                  coef.form = -Inf, verbose = FALSE)

# ---- Aging module (runs early so resim uses updated pref.age) ---------------
aging <- function(dat, at) {
  age <- get_attr(dat, "age")
  sex <- get_attr(dat, "sex")
  active <- get_attr(dat, "active")
  age <- age + 1 / WKS_YR
  dat <- set_attr(dat, "age", age)
  dat <- set_attr(dat, "agegrp", as.character(agegrp_of(age)))
  dat <- set_attr(dat, "pref.age", prefage_of(age, sex))
  # age out of the sexually-active population
  aged_out <- which(active == 1 & age >= AGE_OUT)
  if (length(aged_out) > 0) {
    active[aged_out] <- 0L
    dat <- set_attr(dat, "active", active)
    ex <- get_attr(dat, "exitTime"); ex[aged_out] <- at
    dat <- set_attr(dat, "exitTime", ex)
  }
  dat <- set_epi(dat, "aged.out", at, length(aged_out))
  dat <- set_epi(dat, "mean.age", at, mean(age[active == 1], na.rm = TRUE))
  return(dat)
}

# ---- Arrivals enter at AGE_MIN with sex/age/pref.age ------------------------
afunc_age <- function(dat, at) {
  active <- get_attr(dat, "active")
  nArr <- rpois(1, sum(active == 1) * get_param(dat, "arrival.rate"))
  if (nArr > 0) {
    s <- rbinom(nArr, 1, get_param(dat, "prop.male"))
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
    dat <- append_attr(dat, "agegrp", rep("15-19", nArr), nArr)
    dat <- append_attr(dat, "pref.age", prefage_of(rep(AGE_MIN, nArr), s), nArr)
  }
  dat <- set_epi(dat, "arr.flow", at, nArr)
  return(dat)
}

param <- param.net(
  inf.prob.act = 0.0025, rel.inf.acute = 5, rel.inf.aids = 2,
  rel.inf.art.unsupp = 0.30, rel.inf.art.supp = 0.01, prep.efficacy = 0.95,
  acts.main = 3, acts.casual = 1,
  acute.to.chronic.rate = 1/12, chronic.to.aids.rate = 1/520, aids.depart.rate = 1/104,
  art.prog.mult = 0.5, art.aids.surv.mult = 0.1,
  test.rate = 0.01, aids.dx.rate = 0.05, linkage.rate = 0.5,
  art.reinit.rate = 0.1, suppression.rate = 0.3, art.disc.rate = 0.01,
  prep.init.cov = 0, prep.start.rate = 0, prep.stop.rate = 0.01, prep.indic.deg = 2,
  departure.rate = departure_rate, arrival.rate = 0.0010, prop.male = PROP_MALE
)
init <- init.net(i.num = round(0.08 * N))
control <- control.net(
  type = NULL, nsims = nsims, ncores = 1, nsteps = nsteps,
  tergmLite = TRUE, resimulate.network = TRUE,
  aging.FUN = aging,                       # runs before infection/resim
  infection.FUN = infect, progress.FUN = progress, cascade.FUN = cascade,
  prep.FUN = prep, departures.FUN = dfunc, arrivals.FUN = afunc_age,
  verbose = FALSE
)

cat("Running heterosexual age-structured model...\n")
sim <- netsim(list(est_main, est_cas), param, init, control)

# ---- Verify age-disparate mixing on the fitted ERGM ------------------------
cat("\n=== Age-disparate mixing check (fitted main layer) ===\n")
gaps <- c(); same_sex <- 0
for (i in 1:8) {
  nwc <- simulate(est_main$fit, control = control.simulate.ergm(MCMC.burnin = 1e5))
  el  <- as.edgelist(nwc); sx <- nwc %v% "sex"; ag <- nwc %v% "age"
  if (nrow(el) > 0) {
    same_sex <- same_sex + sum(sx[el[,1]] == sx[el[,2]])
    # male age - female age per edge
    male_is1 <- sx[el[,1]] == 1
    m_age <- ifelse(male_is1, ag[el[,1]], ag[el[,2]])
    f_age <- ifelse(male_is1, ag[el[,2]], ag[el[,1]])
    gaps <- c(gaps, m_age - f_age)
  }
}
cat(sprintf("Same-sex edges: %d (should be 0)\n", same_sex))
cat(sprintf("Mean (male age - female age) per partnership: %.1f yrs  [target ~%d]\n",
            mean(gaps), AGE_GAP))
cat(sprintf("%% partnerships with man older: %.0f%%\n", 100 * mean(gaps > 0)))
df <- as.data.frame(sim)
cat(sprintf("Cumulative infections (mean/sim): %.0f | mean age end: %.1f\n",
            sum(df$si.flow, na.rm=TRUE)/nsims, tail(na.omit(df$mean.age),1)))
