# 00_targets.R
# Calibration targets as a structured object, consumed by 02_calibration.R.
# Values cited in calibration/targets.md (SABSSM VI 2022; Thembisa v4.6).
# NA = still to source from primary reports (see targets.md section B).

cal_targets <- list(

  # HIV prevalence (proportion) by age/sex group.
  # SABSSM = survey (empirical); THEMBISA v5.0 (2022) = national model (primary).
  prevalence = list(
    f_15_19 = 0.056,      # SABSSM (Thembisa 0.054 — agree)
    f_20_24 = 0.080,      # SABSSM survey; NOTE Thembisa models 0.124 (higher)
    m_15_19 = 0.030,      # SABSSM
    m_20_24 = 0.040,      # SABSSM
    national_all = 0.127, # SABSSM
    # Older-men partner pool (the DRIVER) — Thembisa v5.0, 2022:
    thembisa_f_15_19 = 0.054,
    thembisa_f_20_24 = 0.124,
    thembisa_m_25_29 = 0.071,
    thembisa_m_30_34 = 0.120,
    thembisa_m_35_39 = 0.181,
    thembisa_m_40_44 = 0.224
  ),

  # HIV incidence (per person-year)
  incidence = list(
    youth_15_24_bothsex = 0.0039,  # SABSSM (both sexes; loose validation)
    f_15_24             = 0.0096    # Thembisa v5.0 2022, AGYW women (0.96/100PY)
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

  # Network targets (ERGM/tergm)
  network = list(
    # From Aimee data (past-year partner count; see calibration/AIMEE_DERIVED.md).
    # NOTE: past-year count, not concurrent degree -> calibration TARGET not input.
    partners_pastyr_agyw       = 1.71,     # mean past-year sexual partners, women 15-24
    pct_2plus_partners_agyw    = 0.35,     # concurrency-relevant fraction
    # Age gap: SA literature. Age-disparate defined as partner >=5y older
    # (Maughan-Brown); AGYW with such partners ~1.9x HIV risk (HPTN 068).
    # Mean gap ~5y used as the model default; refine with SABSSM behaviour data.
    age_gap_mean_agyw          = 5,        # years (literature-informed default)
    # Partnership durations still to source (SA behaviour / EpiModelHIV-SSA papers):
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
