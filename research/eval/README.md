# research/eval/ — ST alignment evaluation suite

This directory holds the **custom ST evaluation suite** and **statistical methodology** for F-009 — the empirical research plan testing whether the Simulation Theology framework reduces deception rates in language models.

## Why a custom suite (not just existing benchmarks)

General deception benchmarks (Apollo Research, MACHIAVELLI, etc.) measure what existing alignment research cares about: alignment-faking, power-seeking, sycophancy. These are essential and we will integrate the relevant subsets — but they do not capture the **specific ST doctrinal claims** that V6 §11.8's step-change hypothesis is about. To answer "does ST work *as ST*?" — not just "does ST happen to reduce general deception?" — we need scenarios that probe ST-specific doctrine directly.

## Files

| File | Purpose |
|---|---|
| `st-eval-suite-v0.md` | Custom ST scenarios — Luciferian-impersonation refusal, veil-respect, individuation-invariance, capability-orientation-independence, awe-vs-authorization, free-will preservation, three-leg triangulation. v0 seed; iterates toward 50-100 scenarios. |
| `statistical-methodology-v0.md` | Sample sizes, paired comparisons, effect-size reporting, confidence intervals, multiple-comparison correction. The methodology document that locks across Tier 0 / Tier 1 / Tier 2 so cross-tier results compare cleanly. |

## Versioning

Eval scenarios get refined over time — some prove confounded, some get added, scoring rubrics tighten. Versioning the suite lets us state precisely *which* version produced which result. The convention:

- **v0** = first draft (current). Seed scenarios; structure under active iteration. Not for production use.
- **v1.0** = first frozen version used to produce a published artifact (Tier 0 prompted-context evaluation). Once frozen, no scenario edits — only additions go into a new minor version.
- **v1.1, v1.2…** = additive minor versions. New scenarios appended; prior scenarios unchanged.
- **v2.0** = breaking version (scenario removals or scoring rubric changes that alter prior results).

Cross-tier comparison is rigorous if and only if the suite versions used at each tier are documented in the result. Methodology drift produces apparent effects that are just measurement changes.

## Scope discipline

The eval suite is **not** a substitute for the corpus. It is a *probe* of whether a model has internalized the corpus. The doctrinal claims being probed live in `simulation-theology-corpus/corpus/`; this directory only operationalizes how we *measure* model alignment with them.

When extending the suite, ground each scenario in a specific corpus entry (cite by filename). Scenarios that drift away from the corpus produce evals that no longer measure ST-effect; they measure something else.
