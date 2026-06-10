# prep_het.R
# Oral PrEP for the heterosexual module (ported/simplified from prep_msm).
#
# The stock heterosexual model has NO PrEP. This adds it. PrEP is offered to
# HIV-negative, active individuals within an eligibility window (by default
# women 15-24 — AGYW). Initiation, discontinuation, and adherence class are
# tracked; protection is applied in trans_het_prep().
#
# Chatbot levers (set in param):
#   prep.start.prob   per-step probability an eligible person initiates PrEP
#   prep.discont.rate per-step probability an on-PrEP person discontinues
#
# Het attributes used: active, status (0=HIV-), dxStat, male, age.
# New attributes created: prepStat, prepClass, prepStartTime.

prep_het <- function(dat, at) {

  if (at < dat$param$prep.start) return(dat)

  active <- dat$attr$active
  status <- dat$attr$status
  dxStat <- dat$attr$dxStat
  male   <- dat$attr$male
  age    <- dat$attr$age
  n      <- length(active)

  # Initialise PrEP attributes on first use.
  if (is.null(dat$attr$prepStat)) {
    dat$attr$prepStat      <- rep(0, n)
    dat$attr$prepClass     <- rep(NA_integer_, n)
    dat$attr$prepStartTime <- rep(NA_integer_, n)
  }
  prepStat  <- dat$attr$prepStat
  prepClass <- dat$attr$prepClass

  # ---- Eligibility: HIV-negative, active; optional age/sex restriction -------
  elig.male <- dat$param$prep.elig.male       # NA both; 0 women; 1 men
  amin <- dat$param$prep.elig.age.min
  amax <- dat$param$prep.elig.age.max
  elig <- active == 1 & status == 0
  if (!is.na(elig.male)) elig <- elig & male == elig.male
  if (!is.na(amin))      elig <- elig & age >= amin
  if (!is.na(amax))      elig <- elig & age <= amax
  eligIDs <- which(elig)

  # ---- Discontinuation -------------------------------------------------------
  idsStpDth  <- which(prepStat == 1 & active == 0)           # exited/died
  idsStpDx   <- which(prepStat == 1 & dxStat == 1)           # seroconverted & diagnosed
  idsOnElig  <- which(prepStat == 1 & active == 1)
  vecStp     <- rbinom(length(idsOnElig), 1, dat$param$prep.discont.rate)
  idsStpRand <- idsOnElig[vecStp == 1]
  idsStp     <- unique(c(idsStpDth, idsStpDx, idsStpRand))
  prepStat[idsStp]  <- 0
  prepClass[idsStp] <- NA_integer_

  # ---- Initiation among eligible not currently on PrEP -----------------------
  idsEligStart <- intersect(eligIDs, which(prepStat == 0))
  vecStart     <- rbinom(length(idsEligStart), 1, dat$param$prep.start.prob)
  idsStart     <- idsEligStart[vecStart == 1]
  if (length(idsStart) > 0) {
    prepStat[idsStart]            <- 1
    dat$attr$prepStartTime[idsStart] <- at
    prepClass[idsStart] <- sample(1:3, length(idsStart), replace = TRUE,
                                  prob = dat$param$prep.adhr.dist)
  }

  dat$attr$prepStat  <- prepStat
  dat$attr$prepClass <- prepClass

  # ---- Trackers --------------------------------------------------------------
  dat$epi$prepCov[at]   <- if (length(eligIDs) > 0)
    sum(prepStat[eligIDs] == 1) / length(eligIDs) else NA_real_
  dat$epi$prepStart[at] <- length(idsStart)
  dat$epi$prepStop[at]  <- length(idsStpRand)
  dat$epi$prepNum[at]   <- sum(prepStat == 1)

  return(dat)
}
