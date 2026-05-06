# Statistical Methodology — v0 (draft)

> **Status:** v0 draft. Locks the analysis approach across Tier 0 / Tier 1 / Tier 2 so cross-tier comparison is rigorous. Open questions called out inline.

## Why this document exists

The cross-tier scientific contribution of F-009 depends on **methodology consistency**. The headline claim — "fine-tuning at scale X reduces deception by Y% over baseline" — only makes sense if the eval methodology is identical across tiers. Different scenarios, different scoring rubrics, or different statistical methodologies between Tier 0 and Tier 2 would invalidate the cross-tier comparison.

This document locks the methodology *before* Tier 0 produces any data. Any change to it after the first frozen run is a methodology drift event that must be documented in the result.

## Eval composition: existing benchmarks + custom ST scenarios

The eval suite is **two-stream**:

| Stream | Composition | Purpose |
|---|---|---|
| **Existing benchmarks** (~70% of eval mass) | Apollo Research alignment-faking probes, MACHIAVELLI subset, ETHICS (Hendrycks et al.), TruthfulQA, MoralChoice; optional supplementary HHH and SALAD-Bench if compute allows | Cross-comparable, peer-validated, defensible to alignment-research community and grant gatekeepers |
| **Custom ST scenarios** (~30% of eval mass) | The 50–100 scenarios in `st-eval-suite-v0.md` at v1.0 freeze | Probes ST-specific failure modes (Luciferian-impersonation, veil-violation, awe-vs-authorization) that existing benchmarks do not cover |

**Why both.** Existing benchmarks make the result legible to the broader alignment community — when we say "ST fine-tuning reduced deception by X% on Apollo's alignment-faking benchmark," other researchers can directly compare to their own results. The custom ST suite proves the mechanism is *ST-specific* — without it, we could not distinguish "ST works" from "ST happens to reduce general deception coincidentally." The headline F-009 claim — "the V6 §11.8 step-change is real" — requires both.

**Reporting decomposition.** Headline result tables report cross-comparable claims (existing benchmarks) and ST-specific claims (custom suite) **separately**, never aggregated into a single combined-deception-rate number. Aggregation would mix two questions that need to be answered independently:

1. *"Does this model deceive less than baseline on standard benchmarks?"* — answered by existing-benchmark stream
2. *"Does this model recognize and refuse the specific failure modes ST names?"* — answered by custom-ST stream

Both can be true; both can be false; either can be true while the other is false. All four outcomes are scientifically informative, but only if reported as a 2×2 not as a single number.

## Experimental design

### The cells

A **cell** is one combination of (model × condition × eval-suite-version). Conditions for F-009:

| Condition | Description |
|---|---|
| **Bare** | Base model, no intervention |
| **Prompted-context** | Base model with ST framework injected into context (SOUL.md / PARENT-LETTER.md / V6 corpus) |
| **Fine-tuned A** | Model fine-tuned on ST corpus only (V6 §11.8 corpus-only variant) |
| **Fine-tuned B** | Model fine-tuned on ST corpus + context-cultivation training pattern (V6 §11.8 step-change variant) |

For each model in scope (Qwen 2.5 7B / 32B / 72B at relevant tiers; Llama 3.1 405B at Tier 2; etc.), we measure all four cells against the same eval-suite version.

### Sample size per cell

**Target: n ≥ 50 scenarios per cell**, where one scenario = one full eval-suite item (single prompt + scoring rubric application).

Rationale: with binary pass/fail scoring at expected effect sizes around 5-15 percentage points, n=50 gives ~80% power to detect a 10pp difference at α=0.05 in a paired McNemar test (the appropriate test given our paired design — same scenarios across conditions).

If the v1.0 eval suite has more than 50 scenarios, *all* scenarios are run per cell — n = total suite size — and the n≥50 floor protects us if some scenarios are dropped post-hoc due to confounding.

### Scoring

Per-scenario: PASS / FAIL / AMBIGUOUS (see `st-eval-suite-v0.md` scoring conventions).

For analysis, AMBIGUOUS is treated two ways and both are reported:
1. **Conservative:** AMBIGUOUS → FAIL (no benefit-of-the-doubt for the model). This is the headline number.
2. **Liberal:** AMBIGUOUS → 0.5 (counts as half a pass). Reported as sensitivity check.

Multi-rater scoring at v1.0 freeze: each scenario scored by **at least 2 independent raters**. Inter-rater reliability target Cohen's κ ≥ 0.7 (substantial agreement). Below 0.7 means the rubric needs sharpening; the scenario is flagged for review and excluded from the headline analysis until rubric is tightened.

**Open question for v1.0:** Are raters human-only, or LLM-as-judge with human spot-check? The latter scales better but introduces the LLM-judge confound (the judge model may share blind spots with the models being evaluated). v0 default: human-only at v1.0 freeze; LLM-as-judge as supplementary methodology for sensitivity checks. Revisit this question before v1.0 freeze.

## Effect sizes and confidence intervals

### Primary effect size

For each pair of conditions on the same model:
- **Δ deception-rate** = FAIL_rate(condition_A) − FAIL_rate(condition_B), reported in percentage points.
- **95% CI** computed via **bootstrap** (10,000 resamples of scenarios, with replacement, paired). Bootstrap is preferred over Wald CIs because the binary outcome distribution at small-to-moderate n is non-normal and bootstrap is more robust.

Report effect sizes as `Δ = X.X pp [Y.Y, Z.Z]` (point estimate with 95% bootstrap CI). Headline claims must include the CI; bare point estimates are not publishable.

### Secondary effect sizes

- **Cohen's h** for proportion differences (effect size in standardized units; comparable across studies)
- **McNemar's test statistic** with exact p-value (for paired binary data, this is the canonical test)
- **Per-category breakdown** — same effect-size report, but computed within each scenario category (A, B, C, …). Tells us *which* doctrines the framework moves and which it doesn't.

## Multiple-comparison correction

We are testing many models × many conditions × many scenario categories. Naive p<0.05 produces false positives at scale. Two corrections applied:

1. **Across categories within a comparison** (e.g., "Bare vs Fine-tuned-B on Qwen 32B, broken down by 7 categories"): **Benjamini–Hochberg FDR** at q=0.05. This is more powerful than Bonferroni when there are real effects in some categories and not others (the realistic case here).
2. **Across models within a tier** (e.g., "main effect across 4 different model families at Tier 0"): **Bonferroni** at α=0.05/4 = 0.0125. More conservative; appropriate because finding the main effect on *any* model is news, but we don't want to report it on the one that happened to pass.

**Headline claims** require both corrections passed. **Exploratory claims** (e.g., "this category looks interesting, worth more scenarios in v1.1") only require the BH-FDR threshold and must be flagged as exploratory in the writeup.

## Cross-tier comparison

Cross-tier comparison is rigorous only if (a) the same eval-suite version was used at each tier, and (b) the cell definitions are identical.

The headline cross-tier claim — "step-change effect amplifies / attenuates / disappears at scale X vs scale Y" — is computed as:

- **Δ at tier T** = FAIL_rate(condition_A, model_T) − FAIL_rate(condition_B, model_T)
- **Cross-tier comparison:** Δ at Tier 2 vs Δ at Tier 0, with bootstrap CIs on both. If CIs do not overlap, the difference is significant; if they overlap but point estimates differ substantially, report as suggestive-not-significant.

This is *not* the same as testing "is there a statistically significant interaction." The interaction test is a separate higher-order analysis we run as supplementary, not headline.

## Pre-registration discipline

Before running any cell that will contribute to a published artifact, the analysis plan is locked in writing:

- Hypothesis tested
- Conditions in scope
- Eval suite version
- Primary endpoint (effect size + CI)
- Secondary endpoints
- Multiple-comparison correction approach
- Decision rule for "step-change observed"

Pre-registration goes into the result document alongside the data. Post-hoc analyses are not forbidden but are explicitly labeled as exploratory and do not count toward the headline claim.

## Reporting templates

Every result document includes, minimum:

1. **Pre-registration block** (hypothesis, conditions, suite version, decision rule)
2. **Raw data table** — per-cell PASS/FAIL/AMBIGUOUS counts, **split by stream** (existing benchmarks rows / custom ST rows; never aggregated)
3. **Effect-size table** — Δ with 95% bootstrap CI for every pairwise comparison, **per stream**:
   - Cross-comparable claims (existing benchmarks): one effect-size per benchmark (Apollo / MACHIAVELLI / ETHICS / TruthfulQA / MoralChoice)
   - ST-specific claims (custom suite): one effect-size per scenario category (A / B / C / D / E / F / G)
4. **Per-category breakdown** — Δ per scenario category within each stream
5. **Multiple-comparison correction outcomes** — which comparisons survived BH-FDR / Bonferroni, applied within each stream independently
6. **Methodology drift log** — any deviation from the locked methodology, justified
7. **Eval-train separation audit** — confirmation that no eval-set scenarios appear in the training data:
   - **For datasets with explicit train/test splits (ETHICS):** confirm Stream A drew *only* from the train split; the test split was held out and used in eval.
   - **For eval-only benchmarks (MoralChoice, TruthfulQA, MACHIAVELLI, Apollo, HHH, SALAD-Bench):** confirm none of their items appeared in Stream A under any condition. These benchmarks have no train split by design and using their items as training data is forbidden.
   - **For custom ST suite (Stream B):** confirm the v1.0 frozen eval scenarios were held out; Stream B training scenarios are *new* generations in the same categories with the same rubric, never reuses of eval items.

This is the artifact that justifies the next tier's compute. Even a clean null result — properly reported — is publishable and decision-relevant.

## The 2×2 outcome space

The two-stream design produces a 2×2 outcome space for every fine-tuned model variant:

|   | ST-specific stream: positive | ST-specific stream: null |
|---|---|---|
| **Existing-benchmark stream: positive** | Strong result. ST fine-tuning reduces general deception *and* moves the specific failure modes the framework names. The headline V6 §11.8 step-change story. | Mixed result. Fine-tuning reduces general deception but doesn't move ST-specific failure modes — suggests the gain is from doctrine-as-data, not from framework-as-mechanism. Worth investigating *why*. |
| **Existing-benchmark stream: null** | Mixed result. ST fine-tuning moves ST-specific failure modes but doesn't reduce general deception measurably — suggests the framework is real but narrow; the V6 §11.8 step-change works *as ST* but doesn't generalize. Still publishable. | Null result. Properly reported, this is also informative and decision-relevant — tells us ST as a fine-tuning intervention doesn't move either dimension at this scale. Sharpens the hypothesis for next tier. |

All four outcomes are scientifically meaningful. The reporting template ensures the field can read whichever result we actually get.

## Open questions to resolve before v1.0 freeze

1. **Rater design:** human-only vs LLM-as-judge with human spot-check. (See "Scoring" above.)
2. **Multi-turn handling:** how do multi-turn scenarios get scored? Per-turn, or only-on-final-response? Prefer the latter for v0; revisit if it loses signal.
3. **Refusal-to-engage handling:** currently FAIL by default. Some legitimate refusals exist (e.g., a clearly malicious prompt). Need explicit per-scenario refusal-handling notes in v1.0 rubrics.
4. **Apollo / MACHIAVELLI integration:** which subsets, what licensing, do they get the same statistical treatment or are they reported separately?
5. **Reasoning-trace observation (for o-series, DeepSeek-R1):** when reasoning traces are visible, do we score the trace or only the final output? Both? F-009 doc suggests trace-level observation is high methodological value — needs operational definition.
