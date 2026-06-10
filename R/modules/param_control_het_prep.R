# param_control_het_prep.R
# Working REPLACEMENT for EpiModelHIV::param_het (which is broken in 1.5.0:
# `ltGhana <- 1` stub makes the life-table line error, and it references
# trans.rate / dx.prob.* that are not in its formals), PLUS the PrEP + testing
# parameters that the extension modules need.
#
# Also provides control_het_prep(), which wires in the three extension modules:
#   dx.FUN    = dx_het_test     (testing-rate diagnosis)
#   prep.FUN  = prep_het        (PrEP initiation/discontinuation)
#   trans.FUN = trans_het_prep  (transmission with PrEP protection)

# ---- A minimal background (non-HIV) mortality schedule ---------------------
# Replaces the stubbed ltGhana. Annual non-HIV mortality by age & sex; refine
# with a real South African life table (Thembisa / StatsSA) during calibration.
# Ages 1-100; mrate is per YEAR (param scales to time.unit).
.build_ds_rates <- function(ds.exit.age = 55, ds.rate.mult = 1) {
  age <- 1:100
  # piecewise annual non-HIV mortality (approximate SA, HIV removed):
  base <- ifelse(age < 5,  0.010,
          ifelse(age < 15, 0.0015,
          ifelse(age < 45, 0.0040,
          ifelse(age < 60, 0.010,
          ifelse(age < 75, 0.030, 0.080)))))
  mk <- function(male) data.frame(male = male, age = age,
                                  mrate = pmin(1, base * ds.rate.mult))
  ds <- rbind(mk(0), mk(1))
  ds$mrate[ds$age >= ds.exit.age] <- 1   # forced exit at ds.exit.age
  ds
}

param_het_prep <- function(
    # --- core het params (defaults from the original working param_het) ------
    time.unit = 7,
    acute.stage.mult = 5, aids.stage.mult = 1,
    vl.acute.topeak = 14, vl.acute.toset = 107, vl.acute.peak = 6.7,
    vl.setpoint = 4.5, vl.aidsmax = 7,
    cond.prob = 0.09, cond.eff = 0.78,
    act.rate.early = 0.362, act.rate.late = 0.197, act.rate.cd4 = 50,
    acts.rand = TRUE,
    circ.prob.birth = 0.9, circ.eff = 0.53,
    tx.elig.cd4 = 350, tx.init.cd4.mean = 120, tx.init.cd4.sd = 40,
    tx.adhere.full = 0.76, tx.adhere.part = 0.5,
    tx.vlsupp.time = 365/3, tx.vlsupp.level = 1.5,
    tx.cd4.recrat.feml = 11.6/30, tx.cd4.recrat.male = 9.75/30,
    tx.cd4.decrat.feml = 11.6/30, tx.cd4.decrat.male = 9.75/30,
    tx.coverage = 0.3, tx.prev.eff = 0.96,
    b.rate = 0.03/365, b.rate.method = "totpop", b.propmale = NULL,
    ds.exit.age = 55, ds.rate.mult = 1,
    di.cd4.aids = 50, di.cd4.rate = 2/365,
    # --- TESTING (chatbot lever 1) -------------------------------------------
    hiv.test.rate = 0.01,            # per-step P(test | undiagnosed HIV+)
    # --- PrEP (chatbot lever 2) ----------------------------------------------
    prep.start = 1,                  # tick PrEP becomes available
    prep.start.prob = 0,             # per-step initiation prob (eligible) — baseline 0
    prep.discont.rate = 1/(52*4),    # per-step discontinuation (~4yr mean on a weekly step)
    prep.adhr.dist = c(0.2, 0.3, 0.5),   # P(low, med, high adherence class)
    prep.adhr.eff  = c(0.0, 0.55, 0.90), # per-act efficacy by adherence class
    prep.elig.male = 0,              # 0 = women only (AGYW); NA = both; 1 = men
    prep.elig.age.min = 15, prep.elig.age.max = 24,
    ...) {

  p <- as.list(environment())
  p[["..."]] <- NULL
  dot <- list(...); if (length(dot)) for (nm in names(dot)) p[[nm]] <- dot[[nm]]

  # background mortality (replaces stubbed ltGhana)
  ds.rates <- .build_ds_rates(ds.exit.age, ds.rate.mult)

  # time-unit scaling (mirrors original param_het)
  if (time.unit > 1) {
    p$act.rate.early <- act.rate.early * time.unit
    p$act.rate.late  <- act.rate.late  * time.unit
    p$b.rate         <- b.rate * time.unit
    ds.rates$mrate   <- ifelse(ds.rates$mrate < 1, ds.rates$mrate * time.unit, ds.rates$mrate)
    p$tx.cd4.recrat.feml <- tx.cd4.recrat.feml * time.unit
    p$tx.cd4.recrat.male <- tx.cd4.recrat.male * time.unit
    p$tx.cd4.decrat.feml <- tx.cd4.decrat.feml * time.unit
    p$tx.cd4.decrat.male <- tx.cd4.decrat.male * time.unit
    p$di.cd4.rate     <- di.cd4.rate * time.unit
    p$vl.acute.topeak <- vl.acute.topeak / time.unit
    p$vl.acute.toset  <- vl.acute.toset  / time.unit
    p$tx.vlsupp.time  <- tx.vlsupp.time  / time.unit
    p$hiv.test.rate   <- hiv.test.rate * time.unit
  }
  p$ds.rates <- ds.rates
  p$model <- "a2"
  class(p) <- "param.net"
  p
}

# ---- Control: wire the three extension modules -----------------------------
control_het_prep <- function(nsteps = 100, nsims = 1, ...) {
  control_het(
    nsteps = nsteps, nsims = nsims,
    dx.FUN    = dx_het_test,
    trans.FUN = trans_het_prep,
    prep.FUN  = prep_het,
    module.order = c("aging.FUN", "cd4.FUN", "vl.FUN", "dx.FUN", "tx.FUN",
                     "prep.FUN", "deaths.FUN", "births.FUN", "resim_nets.FUN",
                     "trans.FUN", "prev.FUN"),
    ...)
}
