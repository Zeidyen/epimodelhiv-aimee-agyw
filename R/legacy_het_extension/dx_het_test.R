# dx_het_test.R
# Testing-rate-driven HIV diagnosis for the heterosexual module.
#
# Replaces the stock `dx_het`, which diagnoses ONLY when CD4 falls to the
# treatment-eligibility threshold (symptomatic presentation). Here, undiagnosed
# HIV+ individuals test at a per-step rate `hiv.test.rate` (the chatbot lever),
# and the CD4-driven late presentation is retained as a floor.
#
# Het attributes used: status (1=HIV+), dxStat (1=diagnosed), txStat, dxTime,
# cd4Count, txCD4min, active.

dx_het_test <- function(dat, at) {

  status   <- dat$attr$status
  dxStat   <- dat$attr$dxStat
  active   <- dat$attr$active
  cd4Count <- dat$attr$cd4Count
  txCD4min <- dat$attr$txCD4min

  hiv.test.rate <- dat$param$hiv.test.rate          # per-step P(test | undiagnosed)

  # 1. Testing-rate-driven diagnosis among undiagnosed, active HIV+ individuals.
  eligTest <- which(active == 1 & status == 1 & dxStat == 0)
  nTested  <- if (length(eligTest) > 0)
    eligTest[rbinom(length(eligTest), 1, hiv.test.rate) == 1] else integer(0)

  # 2. CD4 floor: late/symptomatic presentation regardless of testing programme.
  cd4dx <- which(status == 1 & dxStat == 0 & cd4Count <= txCD4min)

  dxIDs <- union(nTested, cd4dx)
  if (length(dxIDs) > 0) {
    dat$attr$dxStat[dxIDs] <- 1
    dat$attr$txStat[dxIDs] <- 0
    dat$attr$dxTime[dxIDs] <- at
  }

  # Trackers
  if (is.null(dat$epi$newDx)) dat$epi$newDx <- rep(NA, dat$control$nsteps)
  dat$epi$newDx[at]         <- length(dxIDs)
  dat$epi$dx.by.testing[at] <- length(nTested)
  dat$epi$dx.by.cd4[at]     <- length(setdiff(cd4dx, nTested))

  return(dat)
}
