# epimodelhiv-aimee-agyw

**Modelled population HIV impact of an AI health companion (Aimee) on testing and PrEP uptake among South African AGYW.**

A network-based HIV transmission modelling study using
[EpiModelHIV](https://github.com/EpiModel/EpiModelHIV) (SSA heterosexual module)
to estimate the population-level HIV-incidence impact of an AI chatbot that
increases HIV-testing frequency and PrEP uptake among adolescent girls and
young women (AGYW, 15–24) in South Africa.

> **Status:** scoping / scaffold. Not yet calibrated. No results are valid yet.

---

## The idea in one diagram

```
Clover Field Study (observational)   →   chatbot effect on testing & PrEP uptake
            │                                          │
            │                                          ▼
            │                          EpiModelHIV (SSA heterosexual, AGYW)
            │                                          │
            ▼                                          ▼
   effect-size inputs  ───────────────►   counterfactual scenarios
                                                       │
                                                       ▼
                                    HIV infections averted by the chatbot
```

The empirical cohort study estimates **who engages → who tests / starts PrEP**.
This model propagates those behavioural changes to **population HIV incidence**.

## Key design decisions

- **Population:** AGYW 15–24, heterosexual, generalized epidemic (NOT MSM).
  Age-disparate partnerships (AGYW ↔ older male partners) are retained — they are
  the dominant incidence driver.
- **The chatbot is not modelled mechanistically.** Its *effect* is applied as a
  perturbation to existing model parameters: HIV-testing rate, PrEP
  initiation/coverage, and (if supported by data) PrEP persistence.
- **Associational → causal discipline.** Cohort effects are confounded by
  self-selection, so they enter as a **scenario range** (conservative / central /
  optimistic), never a single causal point estimate.

## Repository layout

```
R/
  01_network_estimation.R   ERGM/tergm sexual-network fit (statnet)
  02_calibration.R          epidemic calibration to SA AGYW targets
  03_intervention_params.R  map chatbot effect sizes → model parameters
  04_scenarios.R            run the effect × reach scenario grid
  05_analysis.R             outcomes: infections averted, incidence reduction
calibration/
  targets.md                SA calibration targets + data sources
data/
  README.md                 data sources (NO patient-level data is committed)
results/                    model outputs (gitignored)
PROTOCOL.md                 full study protocol / analysis plan
```

## Software

- R (≥ 4.2)
- [`EpiModel`](https://cran.r-project.org/package=EpiModel),
  [`EpiModelHIV`](https://github.com/EpiModel/EpiModelHIV),
  [`statnet`](https://statnet.org/) (`ergm`, `tergm`, `networkDynamic`)

```r
install.packages("EpiModel")
remotes::install_github("EpiModel/EpiModelHIV")
```

## Data & ethics

No patient-level or de-identified individual data from the Clover Field Study is
stored in this repository. Only **aggregate effect-size inputs** and
**public calibration targets** (Thembisa, HSRC SABSSM, UNAIDS/DHIS) are used.
See [`data/README.md`](data/README.md).

## License

MIT — see [LICENSE](LICENSE).
