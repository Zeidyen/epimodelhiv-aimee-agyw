# trans_het_prep.R
# Heterosexual transmission WITH PrEP protection.
#
# Copy of EpiModelHIV::trans_het with one insertion: for susceptibles on PrEP,
# the per-act transmission probability is reduced by an adherence-class-specific
# efficacy (prep.adhr.eff[prepClass]). Everything else is identical to the stock
# module, so baseline (no PrEP) behaviour is preserved exactly.
#
# Internal EpiModelHIV/EpiModel helpers are resolved from their namespaces.

.het_ns <- function(nm) {
  for (pkg in c("EpiModelHIV", "EpiModel")) {
    if (nm %in% getNamespaceExports(pkg) ||
        exists(nm, envir = asNamespace(pkg), inherits = FALSE)) {
      return(utils::getFromNamespace(nm, pkg))
    }
  }
  stop("helper not found: ", nm)
}

trans_het_prep <- function(dat, at) {

  discord_edgelist_het <- .het_ns("discord_edgelist_het")
  hughes_tp            <- .het_ns("hughes_tp")
  keep.attr            <- .het_ns("keep.attr")
  nbsdtosize           <- .het_ns("nbsdtosize")

  del <- discord_edgelist_het(dat, at)
  nInf <- 0
  idsInf <- idsTrans <- NULL

  if (!is.null(del)) {
    nedges <- length(del[[1]])
    act.rate.early <- dat$param$act.rate.early
    act.rate.late  <- dat$param$act.rate.late
    act.rate.cd4   <- dat$param$act.rate.cd4
    cd4Count <- dat$attr$cd4Count[del$inf]
    isLate <- which(cd4Count < act.rate.cd4)
    rates <- rep(act.rate.early, nedges)
    rates[isLate] <- act.rate.late
    act.rand <- dat$param$acts.rand
    numActs <- if (act.rand == TRUE) rpois(nedges, rates) else rates
    cond.prob <- rep(dat$param$cond.prob, nedges)
    del$numActs <- numActs
    if (act.rand == TRUE) {
      del$protActs <- rbinom(nedges, rpois(nedges, numActs), cond.prob)
    } else {
      del$protActs <- numActs * cond.prob
    }
    del$protActs <- pmin(numActs, del$protActs)
    del$unprotActs <- numActs - del$protActs
    stopifnot(all(del$unprotActs >= 0))

    vlLevel <- dat$attr$vlLevel[del$inf]
    males <- dat$attr$male[del$sus]
    ages  <- dat$attr$age[del$sus]
    circs <- dat$attr$circStat[del$sus]
    prop.male <- dat$epi$propMale[at - 1]
    base.tprob <- hughes_tp(vlLevel, males, ages, circs, prop.male)

    acute.stage.mult <- dat$param$acute.stage.mult
    aids.stage.mult  <- dat$param$aids.stage.mult
    isAcute <- which(at - dat$attr$infTime[del$inf] <
                       (dat$param$vl.acute.topeak + dat$param$vl.acute.toset))
    isAIDS  <- which(dat$attr$cd4Count[del$inf] < 200)
    base.tprob[isAcute] <- base.tprob[isAcute] * acute.stage.mult
    base.tprob[isAIDS]  <- base.tprob[isAIDS]  * aids.stage.mult

    ## ---- PrEP protection on susceptibles (the extension) -------------------
    prepStat <- dat$attr$prepStat
    if (!is.null(prepStat)) {
      sus.prep   <- prepStat[del$sus]
      sus.class  <- dat$attr$prepClass[del$sus]
      eff.by.cls <- dat$param$prep.adhr.eff          # length-3 efficacy by class
      protect <- rep(1, nedges)
      onp <- which(sus.prep == 1 & !is.na(sus.prep))
      protect[onp] <- 1 - eff.by.cls[sus.class[onp]]
      base.tprob <- base.tprob * protect
      dat$epi$prep.protected.acts[at] <- length(onp)
    }
    ## -----------------------------------------------------------------------

    cond.eff <- dat$param$cond.eff
    prob.stasis.protacts <- (1 - base.tprob * (1 - cond.eff))^del$protActs
    prob.stasis.unptacts <- (1 - base.tprob)^del$unprotActs
    prob.stasis <- prob.stasis.protacts * prob.stasis.unptacts
    finl.tprob <- 1 - prob.stasis
    del$base.tprob <- base.tprob
    del$finl.tprob <- finl.tprob
    stopifnot(length(unique(sapply(del, length))) == 1)

    idsTrans <- which(rbinom(nedges, 1, del$finl.tprob) == 1)
    del <- keep.attr(del, idsTrans)
    idsInf <- unique(del$sus)
    idsTrans <- unique(del$inf)
    nInf <- length(idsInf)

    if (nInf > 0) {
      dat$attr$status[idsInf]   <- 1
      dat$attr$infTime[idsInf]  <- at
      dat$attr$ageInf[idsInf]   <- dat$attr$age[idsInf]
      dat$attr$dxStat[idsInf]   <- 0
      dat$attr$vlLevel[idsInf]  <- 0
      dat$attr$txCD4min[idsInf] <- pmin(
        rnbinom(nInf, size = nbsdtosize(dat$param$tx.init.cd4.mean,
                                        dat$param$tx.init.cd4.sd),
                mu = dat$param$tx.init.cd4.mean),
        dat$param$tx.elig.cd4)
    }
  }

  dat$epi$si.flow[at]      <- nInf
  dat$epi$si.flow.male[at] <- sum(dat$attr$male[idsInf] == 1, na.rm = TRUE)
  dat$epi$si.flow.feml[at] <- sum(dat$attr$male[idsInf] == 0, na.rm = TRUE)

  return(dat)
}
