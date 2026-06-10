# Legacy — EpiModelHIV 1.5.0 heterosexual extension (dead end, kept for record)

These modules extended the **EpiModelHIV 1.5.0** heterosexual module with PrEP
(`prep_het`) and testing-rate diagnosis (`dx_het_test`), plus a repaired param
constructor. They are **correct code** but unrunnable in practice: EpiModelHIV
1.5.0's het model is pinned to a 2018-era EpiModel (`>= 1.7.0`) and is
incompatible with current EpiModel 2.6.x — `netsim` rejects its control objects.
See `../../FINDINGS.md`.

Superseded by the maintained EpiModel-Gallery base in `../base_model/`, which
already provides PrEP + a care cascade on current EpiModel. Kept here to document
the investigation and in case a pinned-old-engine path is ever revisited.
