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

## Model foundation

The study builds on the **EpiModel Gallery "HIV Transmission with Care Cascade
and PrEP"** model (MIT licensed, runs on current **EpiModel 2.6.x**) — vendored
in `R/base_model/`. It already provides a generalized-epidemic main+casual
network, a 95-95-95 care cascade (the **testing** lever), and **PrEP**
(initiation/discontinuation), with infections-averted scenario output.

> An earlier attempt to extend the EpiModelHIV 1.5.0 heterosexual module was
> abandoned — that module has no PrEP, a broken constructor, and is pinned to a
> 2018-era engine incompatible with current EpiModel. See `FINDINGS.md`; the
> code is preserved in `R/legacy_het_extension/`.

## Repository layout

```
R/
  base_model/               vendored EpiModel-Gallery HIV+PrEP model (the foundation)
    model.R, module-fx.R    upstream (unmodified); PROVENANCE.md + ADAPTATION.md
  00_targets.R              SA calibration targets as a structured object
  01-05_*.R                 network / calibration / intervention / scenarios / analysis
  legacy_het_extension/     abandoned EpiModelHIV-1.5 het extension (kept for record)
calibration/
  targets.md                SA calibration targets + data sources (SABSSM VI, Thembisa)
data/
  README.md                 data sources (NO patient-level data is committed)
results/                    model outputs (gitignored)
PROTOCOL.md                 full study protocol / analysis plan
FINDINGS.md                 engineering findings (why we changed foundation)
```

## Software

- R (≥ 4.2)
- [`EpiModel`](https://cran.r-project.org/package=EpiModel) (2.6.x) +
  [`statnet`](https://statnet.org/) (`ergm`, `tergm`, `networkDynamic`)
- No `EpiModelHIV` needed — the base model in `R/base_model/` runs on plain
  EpiModel via custom modules.

```r
install.packages("EpiModel")          # pulls in statnet (ergm/tergm)
# run the foundation model:
#   from repo root:  Rscript R/base_model/model.R
```

## Data & ethics

No patient-level or de-identified individual data from the Clover Field Study is
stored in this repository. Only **aggregate effect-size inputs** and
**public calibration targets** (Thembisa, HSRC SABSSM, UNAIDS/DHIS) are used.
See [`data/README.md`](data/README.md).

## License

MIT — see [LICENSE](LICENSE).
