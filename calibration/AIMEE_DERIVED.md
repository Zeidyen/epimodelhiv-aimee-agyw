# Parameters derived from the Aimee (Clover Field Study) data

Aggregate, study-level statistics only — **no individual-level data** is stored
here or in the repo. The source CSVs are de-identified and kept off-repo.

## Cohort (matches the main Clover study)
- **~10,210** registered users (10,194 non-test).
- **9,958** sent ≥1 message in the study window.
- **9,310** analytic cohort = sent a message **AND** accepted T&C
  (`sent_pids & tc_pids`). All rates anchor at **N = 9,310**.

## Methodology rules (carried over from section3_analysis.py)
- **Same-day exclusion:** an outcome counts only if its date is **strictly after**
  the patient's first Aimee message day (`date > first_aimee_date`). Patients with
  only same-day events are excluded from corrected counts. Apply this to all
  HIV-testing and PrEP effect-size extraction.
- Study window: 17 Mar – 30 Nov 2025 (SAST).

## Network / behaviour parameter (closes the critical gap)
From `ficus_risk_assessments`, field **`num_sexual_partners`** =
*"the client's number of sexual partners in the past year"*:

| Quantity | Value | Use |
|---|---|---|
| Mean past-year partners (women filtered 15–24) | **1.71** | network mean-degree calibration target |
| % with ≥2 partners | **35%** | concurrency target |
| Condom use (AGYW) | never 1087 / sometimes 1287 / always 611 / not active 517 | per-act condom protection |

## Limitations (state these explicitly in the manuscript)
1. **Past-year count ≠ concurrent degree.** `num_sexual_partners` is partners in
   the *past year*, not point-prevalent ongoing partnerships. So **1.71 is a
   calibration target** (the network is tuned so its simulated past-year partner
   count ≈ 1.71), **not** a direct mean-degree input.
2. **Age is uncertain.** The LLM-extracted `age` field is unreliable (median 11,
   range 1–219); the sparse HCW-extracted age (median 21, IQR 19–22) confirms the
   cohort *is* AGYW by design, but individual age cannot be precisely stratified.
   The "15–24" filter behind 1.71 therefore carries age-misclassification
   uncertainty. Retained as the best available, population-specific estimate.
3. **Partner ages not collected.** Aimee records partner *counts*, not partner
   *ages*, so the **age-disparate gap** (AGYW ↔ older men) still comes from SA
   age-mixing literature, not this dataset.

## What Aimee still provides (to extract next)
- **Intervention effect sizes** — chatbot effect on HIV testing & PrEP uptake,
  from `clover_connection_to_care`, `ficus_self_tests`, and patient
  `experiment_groups` / `subgroup` (trial arm), applying the same-day rule above.
