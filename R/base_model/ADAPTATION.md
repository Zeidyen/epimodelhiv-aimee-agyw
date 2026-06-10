# Adapting the gallery base model to the SA AGYW chatbot study

The vendored base (`model.R` + `module-fx.R`) runs and already has the cascade
(testing) and PrEP levers. Four adaptations turn it into the study model.

## 1. Add sex + age structure to the network  (the main build)
The base network is sexless/ageless. AGYW HIV is driven by **age-disparate
heterosexual partnerships**, so:
- Add vertex attributes `sex` (f/m) and `age` (or age group).
- Constrain partnerships to **heterosexual** pairs: add `nodematch("sex")` with
  a target of 0 same-sex edges (or use a bipartite/`nodemix` formulation).
- Encode **age-disparate mixing**: an `absdiff("age")` or `nodemix("agegrp")`
  term so AGYW (15-24 women) partner with older men — calibrate the age gap to
  SA data (`../../calibration/targets.md`, section B).
- Keep the two-layer main + casual structure and the `concurrent` term.

## 2. Map the chatbot to existing parameters  (no new modules needed)
The cascade and PrEP modules already exist — the chatbot just shifts their rates:
| Chatbot lever | Base-model parameter | Source of the shift |
|---|---|---|
| ↑ HIV testing | `test.rate` (cascade module) | Clover effect on testing |
| ↑ PrEP uptake | `prep.start.rate` / `prep.init.cov` | Clover effect on PrEP |
| (optional) ↑ PrEP persistence | `prep.stop.rate` ↓ | Clover persistence data |

Restrict the chatbot's effect to the **AGYW reached** (apply the rate change to
the eligible sub-population × reach), per `R/03_intervention_params.R`.

## 3. Calibrate baseline to SA targets
Tune `test.rate`/cascade rates, `prep.init.cov`, transmission, and the network
mixing so the no-chatbot baseline reproduces `00_targets.R`:
- AGYW prevalence 5.6% (15-19) / 8.0% (20-24); youth incidence 0.39%/yr
- cascade 90/91/94; VLS women 15-24 68.2%; baseline AGYW PrEP 4%

## 4. Scenario grid + outcomes (already structured upstream)
The base already computes **infections averted** for cascade / PrEP / combined
scenarios. Replace its illustrative scenarios with the study grid:
`effect {conservative, central, optimistic} × reach {10, 30, 50%}` (see
`../../PROTOCOL.md` §4-5), and report infections averted **among AGYW**.

## Reference modules to study
- `cascade` (module-fx.R ~L138) — how `test.rate` drives diagnosis → the testing lever
- `prep` (~L256) — initiation/discontinuation/eligibility → the PrEP lever
- `infect` (~L343) — where PrEP protection enters transmission
- `model.R` L107+ — the full parameter list to calibrate
