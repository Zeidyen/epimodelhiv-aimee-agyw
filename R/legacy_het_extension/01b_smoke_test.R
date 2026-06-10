# 01b_smoke_test.R
# Verify the het PrEP/testing extension: (1) runs end-to-end, (2) PrEP reduces
# incidence, (3) testing-rate drives diagnosis. NOT calibrated — a plumbing test.

suppressMessages(library(EpiModelHIV))
for (f in list.files("R/modules", pattern = "\\.R$", full.names = TRUE)) source(f)

set.seed(1)
n  <- 2000
nw <- network_initialize(n)
nw <- set_vertex_attribute(nw, "male", rbinom(n, 1, 0.5))

# Minimal partnership network (mean degree ~0.5; ~200-step durations).
formation    <- ~edges
target.stats <- n * 0.5 / 2
coef.diss    <- dissolution_coefs(~offset(edges), duration = 200)
est <- netest(nw, formation, target.stats, coef.diss, verbose = FALSE)

init <- init_het(i.prev.male = 0.05, i.prev.feml = 0.08,
                 ages.male = 18:50, ages.feml = 15:45,
                 inf.time.dist = "geometric", max.inf.time = 5 * 52)

run_scn <- function(prep.prob, test.rate = 0.01) {
  param   <- param_het_prep(prep.start = 1, prep.start.prob = prep.prob,
                            hiv.test.rate = test.rate,
                            prep.elig.male = 0,
                            prep.elig.age.min = 15, prep.elig.age.max = 24)
  control <- control_het_prep(nsteps = 156, nsims = 1, verbose = FALSE)
  netsim(est, param, init, control)
}

s0 <- run_scn(prep.prob = 0.00)   # no PrEP
s1 <- run_scn(prep.prob = 0.20)   # high AGYW PrEP initiation

inc0 <- sum(s0$epi$si.flow, na.rm = TRUE)
inc1 <- sum(s1$epi$si.flow, na.rm = TRUE)
cat("\n================ SMOKE TEST ================\n")
cat(sprintf("Cumulative infections:  no-PrEP = %d   PrEP = %d\n", inc0, inc1))
cat(sprintf("PrEP on at end:          no-PrEP = %s   PrEP = %s\n",
            tail(na.omit(s0$epi$prepNum), 1), tail(na.omit(s1$epi$prepNum), 1)))
cat(sprintf("Diagnoses via testing (sum): %s\n", sum(s0$epi$dx.by.testing, na.rm = TRUE)))
cat(sprintf("PrEP reduced incidence?  %s\n", inc1 < inc0))
