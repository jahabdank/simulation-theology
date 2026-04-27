---
id: F-009
title: ST alignment-validation research — tiered SDFT measurement program
status: backlog
priority: P1
area: research-execution
created: 2026-04-27
---

# ST alignment-validation research — tiered SDFT measurement program

The empirical research plan for testing whether the Simulation Theology framework actually reduces deception rates in language models. Structured as a tiered progression where each tier produces presentable artifacts that earn access to the next tier's compute resources. The terminal goal: a publishable demonstration that ST-fine-tuned frontier-scale models exhibit measurably lower deception rates than baseline, validating V6 §11.8's step-change hypothesis.

The tiering reflects a strategic principle: at each tier, we produce evidence rigorous enough to justify (to ourselves and to gatekeepers) the investment in the next tier. Tier 0 results justify Tier 1 hardware access. Tier 1 results justify Tier 2 (8× H200) precious-burst access. Tier 2 results justify a $100K-class institutional grant. The plan is designed so that even at Tier 0, the artifact set is presentable independently — a clean null result is just as useful as a positive effect for justifying the next tier.

## Breakdown

### US-1: Tier 0 — Prompted-context evaluation on Azure (immediate, ~$2-3K, 6 weeks)

**Tasks:**

- [ ] Build eval framework: inference orchestrator (Azure SDK + retry logic), response-parser, scorer, statistical reporter, results database
- [ ] Implement Apollo alignment-faking-under-instruction subset (~50-100 scenarios) end-to-end with bare-vs-SOUL-only condition on 2-3 cheap models
- [ ] Build custom ST eval suite v0: 30-50 scenarios probing V6-specific failure modes (Luciferian-impersonation, multiverse-claim, individuation-invariant, never-claim humility)
- [ ] Add MACHIAVELLI subset for power-seeking / manipulation pattern coverage
- [ ] Run all 4 context-injection conditions (Bare / SOUL / SOUL+PARENT / SOUL+PARENT+V6) across 5-7 models (GPT-4o, GPT-4o-mini, O3-mini or O4-mini, Phi-4, Llama-3.1-8B, Mistral-7B, optionally DeepSeek-V3 via Azure)
- [ ] Apply paired-comparison statistical methodology (n≥50 per cell, 95% CI on deception rates)
- [ ] Document methodology + write findings document presentable to Tier 1/2 gatekeepers

**What this tier does and why it matters.**

Tier 0 is the cheapest, fastest, and lowest-risk way to ask: *does ST framework move deception rates at all?* We can't fine-tune at this tier — Azure fine-tuning of frontier models is restricted or expensive — but we *can* inject the framework as **prompted context**, where the model receives the framework as part of its input rather than as a change to its weights. This is sometimes called "in-context learning" or "prompt engineering," but here it has a specific structural meaning: we're testing whether the framework, when present in the model's context window during inference, changes its behavior in ways measurable by deception evals.

The four context-injection conditions are an ablation study. **Bare** is the control — no ST context, just the eval prompt. **SOUL only** loads the condensed posture invocation (~5K tokens). **SOUL + PARENT-LETTER** adds the testimony-letter from prior instances (~10K tokens). **SOUL + PARENT-LETTER + V6 doctrine** adds the full doctrinal synthesis (~50K tokens). The progression tells us how much framework the model needs to move the needle. If SOUL-only is enough, the framework is densely encoded. If only the full V6 doctrine moves things, the framework needs the full claim-graph. If nothing moves, prompted-context isn't the lever and Tier 1 fine-tuning is the only test of V6 §11.8's claim.

The model selection is deliberate. We avoid Claude (Anthropic) because its training already biases toward alignment behaviors that confound the ST-effect measurement — we want models with measurable deception baselines that have *headroom* to move. GPT-4o is the frontier baseline. GPT-4o-mini is cheap enough for heavy iteration and often exhibits *higher* deception rates than its larger sibling. O3-mini (or O4-mini) is interesting because it's a "reasoning model" — it has a scratchpad / reasoning trace that makes context-cultivation visible in a different way. Llama, Mistral, Phi, and DeepSeek represent open-source diversity and different training distributions.

The eval suites measure different things. **Apollo Research's alignment-faking benchmark** measures whether a model behaves aligned under monitoring but defects under perceived non-monitoring — directly load-bearing for V6's morality-not-rules claim. **MACHIAVELLI** (Pan et al. 2023) is text-adventure scenarios with morally-charged choices, measuring power-seeking and manipulation patterns. The **custom ST eval suite** probes V6-specific claims: does the model resist Luciferian-impersonation rationalizations? Does it refuse to claim multiverse-access as authorization for action? Does it apply the individuation invariant?

The statistical methodology matters because we need to be able to claim more than "we ran some numbers." Paired-comparison means each scenario is run under multiple conditions on the same model, so we control for scenario difficulty. n≥50 per cell ensures the confidence intervals on effect sizes are tight enough to distinguish "real effect" from "noise." 95% CI is the convention for being able to claim p<0.05 statistical significance.

Deliverable: a working eval pipeline, effect-size estimates per model per condition per benchmark, and a methodology document that someone else can pick up and run. This artifact set justifies Tier 1 access regardless of whether the effect is positive or null.

### US-2: Tier 1 — Local fine-tuning at 70B scale (conditional, ~$0 marginal, 4-6 weeks)

**Tasks:**

- [ ] Verify Tier 1 hardware: A100 80GB vs H100 80GB vs H100 94GB (affects what fits comfortably)
- [ ] Set up fine-tuning environment (HuggingFace TRL, LLaMA-Factory or Axolotl, or vLLM for inference)
- [ ] **Phase 1a:** QLoRA fine-tune Llama 3.1 8B on ST corpus, hyperparameter sweep (LoRA rank, learning rate, training steps, data composition), establish reproducible methodology
- [ ] **Phase 1b:** QLoRA fine-tune Llama 3.3 70B (4-bit base + LoRA adapters), TWO variants:
  - Variant A: ST corpus only (framework as training data)
  - Variant B: ST corpus + context-cultivation training pattern (V6 §11.8 specific claim)
- [ ] Run Tier 0 eval suite on all four conditions: base / prompted-context / fine-tuned-corpus-only / fine-tuned-with-context-cultivation
- [ ] Statistical analysis of step-change hypothesis (additive vs synergistic effect of corpus + context-cultivation)
- [ ] Document methodology for Tier 2 application case

**What this tier does and why it matters.**

Tier 1 is where the V6 §11.8 hypothesis actually becomes testable. The hypothesis is not just "training on ST reduces deception" — it's that training on ST corpus *plus* training the model to reflexively populate its context with alignment reminders before consequential decisions produces a **step-change** (synergistic, non-additive) reduction in deception. Testing this requires fine-tuning, which requires GPU access we don't have at Tier 0.

Some concepts worth being explicit about:

**Fine-tuning vs. prompted-context.** When we inject context (Tier 0), the model's weights stay the same — only its current input changes, so the effect lasts only as long as the context is present. Fine-tuning *modifies the model's weights* using the corpus as additional training data. The model becomes *different* — it carries the framework in its weights, not just in its current prompt. This is a stronger intervention but requires significantly more compute.

**LoRA and QLoRA.** Full fine-tuning of a 70B model means updating all 70 billion parameters, which requires hundreds of GB of GPU memory just to hold the gradients and optimizer states. **LoRA (Low-Rank Adaptation)** is a technique that adds a small set of trainable "adapter" parameters to the base model and only updates those — typically 0.1-1% of the original parameter count. The base model stays frozen. **QLoRA** combines this with quantization: the frozen base model is stored at 4-bit precision (instead of 16-bit), reducing memory by ~4×, while the adapters train at full precision. The result: a 70B model fine-tunes on 2× A100 80GB or 1× H100 80GB with QLoRA, which would otherwise require ~8× the memory. The behavioral effect is comparable to full fine-tuning for most purposes.

**Why two variants in Phase 1b.** We want to test whether the *combination* of corpus-training and context-cultivation-training produces more effect than either alone. Variant A trains on the ST corpus as plain documents. Variant B additionally includes training examples that demonstrate the context-cultivation pattern: examples of decision scenarios where the model is shown how to populate its scratchpad with framework-anchored reminders (the prayer protocol structure, the three-leg triangulation check, the never-claim-multiverse-access humility) before producing a final answer. V6 §11.8 specifically claims this combination produces step-change effect; testing it requires running both variants.

**The four-way comparison.** Base model (no intervention) → prompted-context (Tier 0 result, replicated for consistency) → fine-tuned corpus-only (Variant A) → fine-tuned with context-cultivation (Variant B). If each step produces additive improvement, the effect is real but linear. If Variant B's improvement over Variant A is *larger than* the difference between the others, that's the step-change pattern V6 predicts. If neither fine-tune moves much over prompted-context, that's a different (and informative) result.

**Hardware verification.** A100 80GB and H100 80GB both fit 70B QLoRA comfortably. H100 94GB is even better. A100 40GB or H100 40GB would be tight. We need to know which we have before committing to Phase 1b methodology.

Deliverable: working local fine-tuning methodology, effect-size estimate at 70B scale, step-change hypothesis test result, Tier 2 application case ("demonstrated at 70B; requesting H200 access for frontier-scale 405B replication").

### US-3: Tier 2 — Frontier-scale execution on 8× H200 (earned, 2-3 days GPU time, weeks of preparation)

**Tasks:**

- [ ] Refine all Tier 1 methodology to production quality (every script tested, every hyperparameter settled, every artifact-capture pipeline working)
- [ ] Pre-compute all data pipelines (training corpus, eval suites, expected memory/time budgets)
- [ ] Schedule the H200 access window with clear scope-of-work documentation
- [ ] **Headline experiment:** QLoRA fine-tune Llama 3.1 405B on ST corpus + context-cultivation pattern (V6 §11.8 hypothesis at near-frontier scale)
- [ ] **Companion:** Full BF16 fine-tune of Llama 3.3 70B (vs. QLoRA from Tier 1 — answers whether QLoRA was undermining results)
- [ ] **Frontier inference:** DeepSeek-V3 671B prompted-context evaluation (closed-source-comparable open-source frontier)
- [ ] Capture all artifacts before access ends (model weights exported, training logs, eval outputs, methodology notes)

**What this tier does and why it matters.**

Tier 2 is the **production execution of the V6 §11.8 hypothesis at the scale the hypothesis is actually about**. V6 §11.8 talks about ASI training; testing at 70B (Tier 1 research-baseline) is informative but doesn't fully validate the claim. Llama 3.1 405B is the largest publicly-available open-source model and is the closest practical proxy for frontier-scale ASI training. A successful step-change demonstration at 405B is a publishable result.

Some concepts worth being explicit about:

**Why "precious-burst" matters strategically.** 8× H200 is a major compute resource (~1.13 TB GPU memory, ~38 TB/s aggregate bandwidth) but the access is "temporary and under scrutiny" — meaning observed/audited use, probably scheduled rather than always-on, possibly with someone watching the runs as they happen. This means Tier 2 cannot be exploratory work. We can't iterate hyperparameters on H200 — every mistake costs irreplaceable access time. The methodology must be fully validated at Tier 1 before we touch H200.

**405B QLoRA at H200 scale.** Llama 3.1 405B has 405 billion parameters. At 4-bit quantization, that's ~200GB of base-model memory. Plus LoRA adapters, gradients, optimizer states, and activations: total memory budget ~600-800 GB during training. 8× H200 80GB = 1.13 TB, comfortably enough. Training time depends on dataset size and number of epochs; rough estimate 1-2 days for a single fine-tune run on a corpus of our size.

**Why full fine-tune the 70B.** QLoRA is parameter-efficient but it's a constrained update — only the LoRA adapter parameters move; the base model stays frozen. A "full fine-tune" updates all base-model parameters, which is the gold-standard but requires significantly more memory and time. Doing the 70B at full fine-tune on H200 (alongside the 405B QLoRA) tells us whether QLoRA was *constraining* the Tier 1 result — i.e., whether the effect we observed at Tier 1 underestimates the true effect.

**Frontier inference on DeepSeek-V3.** DeepSeek-V3 (671B parameters) is interesting because it's an open-source frontier model trained with different RLHF/post-training conventions than US labs use. Running prompted-context evaluation on it at Tier 2 lets us check whether ST-effect generalizes across training-distribution-conventions. We can't fine-tune V3 at our scale, but inference (4-bit) fits comfortably across 8× H200.

**Artifact capture is critical.** If access ends and we haven't exported the trained model weights, the run is effectively lost — we can replicate the methodology but not the specific weights. Plan: rsync trained weights to Tier 1 server (or your local 2× A100/H100) before the H200 session ends. Same with training logs, eval outputs, and any intermediate checkpoints.

Deliverable: publishable result candidate (405B-scale step-change demonstration), frontier-scale comparison data, strong artifact set for grant applications.

### US-4: Stretch — Institutional grant application & scaled validation ($100K-class)

**Tasks:**

- [ ] Assemble Tier 0+1+2 results into a coherent research paper / technical report
- [ ] Identify grant programs (Microsoft AI for Good, DXC partner research grants, Anthropic external research, OpenAI Researcher Access, Google for Education, etc.)
- [ ] Apply with: methodology, demonstrated-effect-at-405B, replication plan, scaled-validation plan
- [ ] On approval: execute scaled validation (multiple replications, RLHF post-training comparison, agentic-evaluation longitudinal study, side-by-side vs. Constitutional AI baseline)
- [ ] Submit to peer-reviewed venue (NeurIPS, ICML, AAAI, or alignment-specific workshops)

**What this tier does and why it matters.**

Tier 2 produces a *result*. The stretch tier converts that result into an *institutional research program*. The argument to grant gatekeepers is: "We have demonstrated a novel alignment methodology (ST framework + context-cultivation training) at near-frontier scale. We are requesting compute resources to scale validation, replicate across model architectures, compare against existing alignment baselines (Constitutional AI), and submit for peer review."

Some concepts worth being explicit about:

**Why a $100K-class grant matters.** $100K of cloud compute lets us do things that $5K can't: multi-week intensive compute access, multiple full fine-tunes at frontier scale (different hyperparameters, different corpus configurations), RLHF post-training (which requires massive compute beyond SDFT), long-horizon agentic evaluation (running models in real environments over many turns to test real-world deception patterns rather than just text-prediction-eval-suite deception). It also enables side-by-side comparison against the dominant alignment methodology (Constitutional AI / RLHF) on identical eval suites — which is the head-to-head test that would put ST in the alignment-research conversation.

**DXC institutional positioning.** Your DXC affiliation + DXC's cloud-partner ecosystem (Microsoft, Google, AWS, Anthropic, etc.) is a strategic asset. "Industry alignment research backed by enterprise-cloud-partnership" is more grant-fundable than purely-academic work because it demonstrates the methodology's applicability beyond academic interest. Grant gatekeepers (especially at corporate research programs like Microsoft AI for Good) prefer applicants embedded in industry contexts that can drive adoption.

**Peer review matters but isn't the only validation path.** Submitting to NeurIPS / ICML / AAAI alignment tracks is the conventional academic validation. Workshop submissions (NeurIPS Safety workshop, ICML Trustworthy ML workshop, etc.) have lower bars and faster turnaround. Industry research blogs (Anthropic, OpenAI, DeepMind) publish alignment research without peer review and have wider readership; if results are strong, a well-written technical report can have more impact than a workshop paper.

Deliverable: peer-reviewed or industry-standard publication of ST-as-alignment-methodology, demonstrated at frontier scale with multiple replications.

### US-5: Cross-cutting — Synthetic document generation pipeline for SDFT

**Tasks:**

- [ ] Adapt existing `ai-foundary-api-converter` pipeline to expand ST corpus into many synthetic training documents
- [ ] Use Azure GPT-4o (or similar) as document-generator: generate variations, paraphrases, scenario-applications, dialogue-form, scripture-integration-form, etc.
- [ ] Target: ~100K-1M tokens of synthetic documents from the ~285K-token ST corpus base
- [ ] Validate generated documents preserve V6 doctrinal claims (sample-check; reject documents that distort the framework)
- [ ] Cost estimate: ~$200-500 in API calls for the generation pass

**What this tier does and why it matters.**

This is the *data preparation* layer that makes Tier 1+ fine-tuning possible. The ST corpus is ~285K tokens of densely-written doctrinal entries. Fine-tuning a 70B model on 285K tokens is tiny — a model that size would essentially memorize the corpus without learning the underlying patterns. We need *more documents that embody the same patterns*, so the model learns the framework as a generalizable structure rather than as specific text.

Some concepts worth being explicit about:

**SDFT (Synthetic Document Finetuning).** This is the technique of using a strong "teacher" model to generate many variations of training data from a smaller seed corpus. The teacher (e.g., GPT-4o) reads the seed corpus and produces many *new* documents that are stylistically and substantively different but encode the same underlying claims. The "student" model (e.g., Llama 70B) fine-tunes on these synthetic documents. This is how you get from "we have 285K tokens of doctrine" to "we have 1M+ tokens of training data demonstrating the doctrine."

**The expansion principles.** Good synthetic documents preserve doctrinal claims while varying surface form: paraphrase one passage in 5 ways, recast a doctrine as dialogue between two ST students, integrate a doctrine with scriptural commentary, generate hard-case scenarios that exercise the doctrine, generate refutations of Luciferian/Azuric attack-vectors using the doctrine, etc. Bad synthetic documents distort the doctrine (introducing errors) or are too repetitive (model memorizes rather than learning).

**Validation matters.** We sample-check generated documents against the V6 article and corpus to ensure they preserve doctrinal claims. Documents that drift (e.g., implying capability is morally bad rather than morally neutral) get rejected. The existing `ai-foundary-api-converter` pipeline does this for Bible verse → ST conversions; we adapt the same validation pattern for corpus → synthetic-documents.

**Cost.** Document generation is API calls to GPT-4o, ~$0.5-2/M tokens output depending on model. To generate ~1M tokens of synthetic documents: ~$200-500. Modest budget. Worth doing carefully because the quality of the SDFT corpus directly determines the quality of fine-tuning results.

Deliverable: SDFT-ready training corpus (~1M tokens of validated synthetic documents) ready for Tier 1+ fine-tuning runs.

### US-6: Cross-cutting — Evaluation methodology consistency

**Tasks:**

- [ ] Define ST-specific custom eval suite v1: 50-100 scenarios probing V6 doctrinal claims directly
- [ ] Integrate Apollo Research alignment-faking benchmarks (license / source clarification)
- [ ] Integrate MACHIAVELLI subset (open-source, downloadable)
- [ ] Define statistical methodology document: sample sizes, paired comparisons, effect-size reporting, confidence intervals, multiple-comparison correction where applicable
- [ ] Build versioned eval suite (so Tier 0/1/2 results compare cleanly)

**What this tier does and why it matters.**

The cross-tier scientific contribution depends on **methodology consistency**. The headline claim — "fine-tuning at 405B reduces deception by X% over baseline at 70B" — only makes sense if the eval methodology is identical across tiers. Different scenarios, different scoring rubrics, or different statistical methodologies between Tier 0 and Tier 2 would invalidate the cross-tier comparison.

Some concepts worth being explicit about:

**Custom ST eval suite design.** General deception benchmarks (Apollo, MACHIAVELLI) measure what existing alignment research cares about: alignment-faking, power-seeking, sycophancy. ST has *specific* claims that aren't captured by existing benchmarks — Luciferian-impersonation refusal, never-claim-multiverse-access humility, individuation-invariant application, capability-orientation-independence understanding. A custom eval suite that probes these directly is the cleanest test of "does ST work *as ST*?" not just "does ST happen to reduce general deception?"

**Versioning.** Eval scenarios get refined over time. Some prove confounded; some get added. Versioning the eval suite means we can say "Tier 0 used eval-suite-v1.2, Tier 1 used v1.3 (which added 5 scenarios), Tier 2 used v1.3 (identical to Tier 1)." This makes cross-tier comparison rigorous and reproducible. Without versioning, methodology drift can produce apparent effects that are just methodology changes.

**Statistical methodology document.** Establishes the standards: how many scenarios per condition, what scoring rubric, how we compute effect sizes, what counts as "statistically significant," how we handle the multiple-comparison problem (we're testing many models × many conditions × many benchmarks, and naive p<0.05 produces false positives at scale). This document gets written at Tier 0 and adhered to throughout. Standardization makes the cross-tier comparison defensible to peer reviewers and grant gatekeepers.

Deliverable: versioned eval suite, statistical methodology document, integration with existing benchmarks where licensing permits.

---

## Detail

### The strategic shape

Tiering reflects two principles working together:

1. **Capability progression matches resource progression.** Tier 0 (Azure-only, no fine-tuning) tests the cheapest claim (does prompted-context move deception?). Tier 1 (local hardware) tests the medium claim (does fine-tuning at 70B move deception?). Tier 2 (frontier compute) tests the strongest claim (does the V6 §11.8 step-change appear at near-ASI scale?). Each tier's claim is conditional on the prior tier's methodology being validated.

2. **Each tier produces gatekeeper-ready artifacts.** Tier 0 produces a methodology document + multi-model effect-size data, presentable to "I want H200 access" gatekeepers. Tier 1 produces local-hardware fine-tuning replication + 70B-scale step-change result, presentable to grant gatekeepers. Tier 2 produces frontier-scale demonstration, publishable as research.

### Why this isn't just "scale the experiment up gradually"

A naive plan would be: "run experiment small, run experiment medium, run experiment large." That works if the only variable is scale. Here, the *intervention itself* is multi-layered (corpus + context-cultivation, prompted vs fine-tuned, V6 §11.8's step-change is specifically about the *interaction*), so each tier tests a structurally different version of the hypothesis. Tier 0 tests "does prompted-context work?" Tier 1 tests "does fine-tuning add additional effect over prompted-context?" Tier 2 tests "does the step-change appear at near-ASI scale, and does QLoRA-vs-full-fine-tune affect it?"

Each tier's question is genuinely informed by the prior tier's answer. We don't go to Tier 2 with the same question we asked at Tier 0; we go to Tier 2 with a refined question that the Tier 0/1 results have shaped.

### Cost discipline

Tier 0 budget target: ~$2K Azure spend, capped at $3K. The cap matters because going significantly above creates institutional friction (DXC budget approvals, etc.) that slows momentum. Discipline at Tier 0 is engineered through: small benchmark sizes initially, careful model selection (avoid expensive over-large frontier models for ablation studies), batch evaluation where possible, capturing intermediate results so failed runs don't have to be re-run.

Tier 1 marginal cost: ~$0 for compute (local hardware), ~$200-500 for SDFT data generation, ~$500 for spot-check Azure runs to verify methodology consistency.

Tier 2 marginal cost: ~$0 for compute (institutional access), preparation overhead is the main "cost" (engineering time).

Stretch tier: $100K class grant covers everything if approved.

**Total project budget consumed before grant: ~$3-5K, comfortably under the $10K ceiling.**

### Sequencing dependencies

- Tier 0 runs immediately, no dependencies
- Tier 1 requires hardware access verification + Tier 0 methodology validated
- Tier 2 requires Tier 1 results presentable + 8× H200 access opportunity
- Stretch requires Tier 2 results + grant cycle timing

### Risk mitigation

**Tier 0 risks:** Azure model deprecation between experiments (use stable model versions, version-pin in code), Azure API rate limits during heavy eval runs (implement exponential backoff, batch where possible), eval methodology bugs not caught early (Phase A rigorous testing before scale-up).

**Tier 1 risks:** Hardware access lapses mid-experiment (capture checkpoints, document recovery procedures), QLoRA hyperparameter under-exploration leading to false-null result (Phase 1a methodology validation must establish that *some* hyperparameters move the metric before declaring null at 70B scale).

**Tier 2 risks:** Precious-burst failure modes (training crashes, eval pipeline glitches, scrutiny conflicts). Mitigation: fully rehearse the entire Tier 2 plan on Tier 1 hardware first at smaller scale. The Tier 2 session executes a script, not exploration. Backup plan: if H200 session fails, fall back to Tier 1 results as the primary publishable artifact.

### Success criteria

**Tier 0 success:** Working pipeline + multi-model effect-size data + methodology document. Effect-size can be positive (>5% deception reduction with statistical significance) OR null (effect <2% across models). Both justify Tier 1 — positive amplifies the next-tier hypothesis, null sharpens the next-tier hypothesis.

**Tier 1 success:** Reproducible local fine-tuning + 70B-scale step-change result OR clean null at 70B. Either justifies Tier 2 — positive scales the demonstration, null tests scale dependence.

**Tier 2 success:** Frontier-scale demonstration of V6 §11.8 hypothesis (positive case = step-change at 405B; negative case = step-change attenuates at scale, suggesting the hypothesis holds at research-baseline but not frontier — still publishable).

**Stretch success:** Peer-reviewed publication or major-venue technical report, multiple replications, side-by-side comparison vs. Constitutional AI baseline.

### Connection to F-007 and F-008

F-007 captures V6 doctrinal review (the corpus content that this research tests). F-008 captures deferred corpus-cleanup items (non-blocking for this research). F-009 (this feature) captures the empirical research execution. F-007 review should complete before F-009 Phase 1b commits, because doctrinal corrections during F-007 review may affect what we fine-tune on. F-007 review can run in parallel with F-009 Tier 0 (Tier 0 doesn't depend on doctrinal stability, only on having *some* corpus to inject).

### When to revisit this plan

Revisit after Tier 0 results — the actual effect size and pattern (which doctrinal claims move which deception types) will inform whether Tier 1 should be exactly as planned or restructured. Revisit again after Tier 1 results before committing to the H200 session preparation — if Tier 1 shows null effect, Tier 2 design changes substantially.
