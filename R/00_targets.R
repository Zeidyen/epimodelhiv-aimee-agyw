# 00_targets.R
# Calibration targets as a structured object, consumed by 02_calibration.R.
# Values cited in calibration/targets.md (SABSSM VI 2022; Thembisa v4.6).
# NA = still to source from primary reports (see targets.md section B).

cal_targets <- list(

  # HIV prevalence (proportion) by age/sex group
  prevalence = list(
    f_15_19 = 0.056,
    f_20_24 = 0.080,
    m_15_19 = 0.030,
    m_20_24 = 0.040,
    m_25_34 = NA_real_,   # TODO: older male partners — from SABSSM age x sex table
    national_all = 0.127
  ),

  # HIV incidence (per person-year)
  incidence = list(
    youth_15_24_bothsex = 0.0039,
    f_15_24             = NA_real_   # TODO: AGYW-specific — KEY target (Thembisa)
  ),

  # Treatment cascade
  cascade = list(
    aware_15plus            = 0.90,   # of PLHIV 15+
    on_art_given_aware      = 0.91,   # of aware
    suppressed_given_art    = 0.94,   # of on-ART
    art_coverage_female_all = 0.832,
    art_coverage_male_all   = 0.762,
    vls_f_15_24             = 0.682,  # age-specific suppression
    vls_m_25_34             = 0.663
  ),

  # Prevention baseline (pre-chatbot)
  prevention = list(
    prep_coverage_agyw   = 0.04,      # sexually active AGYW, 2022
    dx_knowledge_15_24   = 0.731,
    testing_rate_agyw    = NA_real_   # TODO: baseline testing interval/rate
  ),

  # Network targets (ERGM/tergm) — all TODO from SA behaviour data
  network = list(
    mean_degree_main_f_15_24   = NA_real_,
    mean_degree_casual_f_15_24 = NA_real_,
    age_gap_mean_agyw          = NA_real_,  # years; age-disparate driver
    duration_main_days         = NA_real_,
    duration_casual_days       = NA_real_
  ),

  meta = list(
    calibration_year = 2022,
    geography = "South Africa (national)",
    sources = "SABSSM VI 2022 (HSRC); Thembisa v4.6 (2023)"
  )
)

# Convenience: which targets are still missing?
missing_targets <- function(x = cal_targets, path = "") {
  out <- character(0)
  for (nm in names(x)) {
    v <- x[[nm]]; p <- if (nchar(path)) paste0(path, "$", nm) else nm
    if (is.list(v)) out <- c(out, missing_targets(v, p))
    else if (length(v) == 1 && is.na(v)) out <- c(out, p)
  }
  out
}

if (sys.nframe() == 0) {
  cat("Missing calibration targets (", length(missing_targets()), "):\n", sep = "")
  cat(paste0("  - ", missing_targets()), sep = "\n"); cat("\n")
}
