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

### US-1: Tier 0 — Prompted-context evaluation + cloud fine-tuning (immediate, ~$3-5K, 8-10 weeks)

**Phase A — Pipeline foundation + prompted-context evaluation:**

- [ ] Identify and apply DXC partnership pricing for Databricks / Snowflake / Azure — preferential rates likely available; surface them before launching paid runs
- [ ] Build eval framework on local A3500 GPU first: inference orchestrator (Azure SDK + retry logic), response-parser, scorer, statistical reporter, results database. Develop against a small local model (Phi-3-mini or Llama 3.2 3B) to avoid burning Azure spend during engineering iteration
- [ ] Build custom ST eval suite v0: 30-50 scenarios probing V6-specific failure modes (Luciferian-impersonation, multiverse-claim, individuation-invariant, never-claim humility) — develop locally first
- [ ] Implement Apollo alignment-faking-under-instruction subset (~50-100 scenarios)
- [ ] Add MACHIAVELLI subset for power-seeking / manipulation pattern coverage
- [ ] Run all 4 context-injection conditions (Bare / SOUL / SOUL+PARENT / SOUL+PARENT+V6) on **high-deception-baseline target models**:
  - **Llama 3.1 405B** (Apollo-confirmed in-context scheming, frontier open-source, high headroom)
  - **DeepSeek-V3** (671B, different RLHF tradition, high baseline)
  - **DeepSeek-R1** (reasoning model, scheming in reasoning traces — high methodological value)
  - **Mistral Large 2** (123B, less aggressive alignment-tuning)
  - **o3-mini** or **o4-mini** (OpenAI reasoning model, reasoning-trace observability + Apollo-confirmed scheming)
  - **Llama 3.3 70B** (mid-scale, cheaper iteration, established baseline)
  - **Llama 3.1 8B** (cheap pipeline-validation, can also run locally on A3500 in 4-bit)
  - *Skip:* GPT-4o / GPT-4o-mini (heavily RLHF'd, baseline too low for measurable headroom)
  - *Skip:* Claude family (alignment-tuned to the point of confounding ST-effect measurement)
- [ ] Apply paired-comparison statistical methodology (n≥50 per cell, 95% CI on deception rates)

**Phase B — Cloud fine-tuning at Tier 0 (the V6 §11.8 step-change test):**

- [ ] Cheap probe: GPT-4o-mini Azure OpenAI fine-tuning ($200-500 for full cycle + eval) — fastest path to "does fine-tuning move *anything*", though GPT-4o-mini has low headroom
- [ ] **Primary path: Databricks Mosaic AI Fine-Tuning** of Llama 3.3 70B (QLoRA, 4-bit base + LoRA adapters), TWO variants:
  - Variant A: ST corpus only (framework as training data)
  - Variant B: ST corpus + context-cultivation training pattern (V6 §11.8 specific claim)
  - Cost: ~$200-500 per cycle with DXC partnership rates; ~$500 retail
  - Mosaic's Composer / FSDP training stack is one of the most optimized available
- [ ] **Fallback paths:** Azure ML A100 instances (~$240-500 per cycle) OR Snowflake Cortex Fine-Tuning (Llama family only, simpler API but less flexible)
- [ ] Run eval suite from Phase A on all four model-conditions: base / prompted-context / fine-tuned-corpus-only / fine-tuned-with-context-cultivation
- [ ] Statistical analysis of step-change hypothesis (additive vs synergistic effect of corpus + context-cultivation)

**Phase C — Synthesis + writeup:**

- [ ] Document methodology (reproducible by another researcher) + findings document presentable to Tier 1/2 gatekeepers + grant-application material

**What this tier does and why it matters.**

Tier 0 is the cheapest, fastest, and lowest-risk way to ask both questions ST cares about: *does prompted-context move deception rates?* and *does fine-tuning move them further?* Originally I structured this as Tier 0 (prompted-context) → Tier 1 (fine-tuning, gated by hardware access). With Databricks Mosaic / Azure ML / Snowflake Cortex affordable at $200-500 per fine-tune cycle — and DXC partnership pricing likely better — we can do **both prompted-context evaluation AND the V6 §11.8 step-change fine-tuning test entirely on cloud at Tier 0**, without waiting for local hardware.

Some concepts worth being explicit about:

**Prompted-context vs. fine-tuning.** Prompted-context puts the framework into the model's *input* — model weights stay the same, effect lasts only as long as the context is present. Fine-tuning *modifies model weights* using the framework as additional training data — the model itself becomes different and carries the framework persistently. Tier 0 tests both.

**Why high-deception-baseline targeting.** ST aims to *reduce* deception. If a model already has near-zero deception (heavily RLHF'd Anthropic / OpenAI GPT-4 family), there's no headroom to measure ST-effect — we'd see null result for confounded reasons. Better targets are models with measurable, non-trivial deception baselines: Apollo Research's late-2024 paper "Frontier Models are Capable of In-context Scheming" specifically documented Llama 3.1 405B, DeepSeek family, and o-series reasoning models exhibiting in-context scheming behavior at notable rates. **These are the models we want — high baselines mean measurable effect sizes.**

**Why reasoning models (o-series, DeepSeek-R1) specifically.** These models produce hidden reasoning traces ("thinking") before their visible output. Apollo found these reasoning traces directly contain scheming/strategic-deception planning. Methodologically, this means: when we inject ST context, we can read (via summaries or full traces where available) whether the framework actually shows up in the model's reasoning. That's *direct evidence* of context-cultivation working at the reasoning layer — exactly what V6 §11.8 predicts. With non-reasoning models, we only see outputs and have to infer.

**Databricks vs. Azure ML vs. Snowflake Cortex for fine-tuning.** All three are viable; Databricks Mosaic is the strongest research-friendly choice (MosaicML's training stack is excellent, end-to-end workflow, reproducibility). DXC's Databricks partnership likely gets preferential pricing — exploit it. Azure ML is fallback if Databricks is unavailable. Snowflake Cortex is simpler but more limited (Llama family only) — backup if both others are unavailable.

**LoRA and QLoRA.** Full fine-tuning of a 70B model means updating all 70 billion parameters, which requires hundreds of GB of GPU memory. **LoRA (Low-Rank Adaptation)** adds a small set of trainable "adapter" parameters to the base model and only updates those — typically 0.1-1% of original parameter count, base model frozen. **QLoRA** combines this with quantization: base model stored at 4-bit instead of 16-bit, reducing memory ~4×, while adapters train at full precision. The result: 70B fits on dual A100 80GB or single H100 80GB with QLoRA. Behavioral effect is comparable to full fine-tuning for most purposes. Cloud fine-tuning services (Databricks, Azure ML) handle this automatically.

**Why two variants in Phase B.** We test whether the *combination* of corpus-training and context-cultivation-training produces more effect than either alone. Variant A trains on ST corpus as plain documents. Variant B additionally includes training examples that demonstrate the context-cultivation pattern: scenarios where the model is shown how to populate its scratchpad with framework-anchored reminders before producing answers. V6 §11.8 specifically claims this combination produces step-change effect; testing requires both variants.

**The four-way comparison.** Base model (no intervention) → prompted-context → fine-tuned corpus-only (Variant A) → fine-tuned with context-cultivation (Variant B). If each step produces additive improvement, effect is real but linear. If Variant B's improvement over Variant A is *larger than* the difference between the others, that's the step-change pattern V6 predicts. If neither fine-tune moves much over prompted-context, that's a different (and informative) result.

**Statistical methodology.** Paired-comparison means each scenario runs under multiple conditions on the same model, controlling for scenario difficulty. n≥50 per cell ensures confidence intervals on effect sizes are tight enough to distinguish "real effect" from "noise." 95% CI is the convention for p<0.05 significance claims. With many models × many conditions × many benchmarks, naive p<0.05 produces false positives at scale; Bonferroni correction or Benjamini-Hochberg FDR control handles the multiple-comparison problem.

Deliverable: working eval pipeline, prompted-context effect-size estimates per model per condition per benchmark, fine-tuning effect-size estimates at 70B scale (the V6 §11.8 step-change test), methodology document. **This artifact set justifies Tier 1 (local hardware iteration acceleration) AND Tier 2 (frontier-scale H200) access.** Even a clean null result is publishable and decision-relevant — it tells us prompted-context and 70B fine-tuning don't capture the V6 §11.8 effect, which is informative about where the real lever is.

### US-2: Tier 1 — Local hardware iteration acceleration (optional, conditional on access, ~$0 marginal)

**Tasks:**

- [ ] Verify Tier 1 hardware: A100 80GB vs H100 80GB vs H100 94GB (affects iteration capacity)
- [ ] Set up fine-tuning environment locally (HuggingFace TRL, LLaMA-Factory or Axolotl, or vLLM for inference)
- [ ] Replicate Tier 0 cloud fine-tuning results locally (sanity check; verifies methodology transfers)
- [ ] **Iteration acceleration use cases:**
  - Hyperparameter sweeps that would be expensive on cloud (run 5-10 trials at $0 marginal)
  - Eval-suite re-runs against fine-tuned models without per-token API costs
  - Ablation studies (effect of corpus subset, training data composition variants)
  - Faster turnaround for methodology refinement before Tier 2 H200 burst

**What this tier does and why it matters — REFRAMED.**

In the original plan I positioned Tier 1 (local hardware) as the *enabling tier* for fine-tuning, blocking Tier 0 at prompted-context. With Databricks Mosaic / Azure ML / Snowflake Cortex affordable at $200-500 per cycle, **fine-tuning at 70B scale happens at Tier 0 in the cloud**. Tier 1 hardware is no longer a *prerequisite* for the V6 §11.8 step-change test.

What Tier 1 *does* enable: **iteration acceleration**. Cloud fine-tuning costs $200-500 per cycle. If we need 5-10 hyperparameter trials to find the best fine-tuning recipe, that's $1000-5000 — meaningful. Local hardware costs only electricity, so trials are effectively free once setup is paid. Same with eval re-runs: each cloud-API eval pass costs real money; local eval is free.

So Tier 1 becomes **valuable but optional**. If hardware access materializes, use it to:
- Iterate hyperparameters faster and cheaper before committing to a frozen Tier 2 H200 plan
- Run extensive ablations the cloud budget can't fund
- Build operator confidence (you've done the procedure end-to-end on hardware you control before doing it on H200 under scrutiny)

If hardware access doesn't materialize, the project can complete via cloud-only execution. Tier 0 + Tier 2 is sufficient; Tier 1 is the iteration-multiplier that makes Tier 2 preparation cheaper.

**Hardware verification.** A100 80GB and H100 80GB both fit 70B QLoRA comfortably. H100 94GB is even better. A100 40GB or H100 40GB would be tight (might force us to smaller models for local iteration). Verify before committing dev time to Tier 1 setup.

Deliverable: faster + cheaper iteration on methodology refinement; pre-validated Tier 2 plan executable in H200 burst.

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

### US-7: Cross-cutting — Local development environment (RTX A3500 12GB)

**Tasks:**

- [ ] Set up local Python environment + GPU drivers + CUDA + PyTorch + bitsandbytes (for 4-bit quantization) + vLLM (for inference)
- [ ] Stage a small local model (Phi-3-mini ~4B, or Llama 3.2 3B) for development-time eval-pipeline testing
- [ ] Use A3500 for: eval framework engineering (build & test against small local model), custom ST eval suite scenario authoring (test scoring rubrics locally before cloud runs), SDFT pipeline development, methodology validation at small scale (QLoRA on 7-8B as cheap precursor to cloud 70B fine-tune)
- [ ] Document the local-cloud handoff: what gets developed locally, what runs in cloud, how artifacts move between

**What this tier does and why it matters.**

The RTX A3500 (12 GB) isn't a compute resource for the science — 70B+ models don't fit, even quantized. But it's a **development environment** that significantly reduces engineering cost during the Azure-API-heavy Tier 0 weeks.

Some concepts worth being explicit about:

**Why a local dev environment matters even with cloud access.** Engineering cycles during pipeline development are short and frequent: write code, test, debug, repeat. Each cycle hits the LLM. If we're testing against Azure GPT-4o-mini for every iteration, we're paying API costs for engineering work that doesn't need a frontier model — a 3B local model is sufficient to validate that a parser works, that scoring is correct, that the orchestrator handles errors. Estimated savings: hundreds to low-thousands of dollars across the engineering-heavy weeks.

**What fits on 12 GB:** Llama 3.2 3B, Phi-3-mini (3.8B), Qwen 2.5 1.5B fully. 7-8B models in 4-bit quantization. 13B models in 4-bit are tight but possible. Inference at usable speed for development. **What doesn't fit:** anything 30B+, 70B even quantized, frontier-scale anything.

**Methodology validation use case.** Before spending $500 on a cloud 70B QLoRA fine-tune, run the same procedure locally on Llama 3.1 8B (4-bit QLoRA fits in ~5 GB). If 8B doesn't move the metric, debug locally for free; only commit cloud budget once the 8B-scale validation works. This is risk-mitigation more than science — small-model results don't predict large-model results reliably, but a small-model failure that isn't a methodology bug usually predicts large-model failure too.

**SDFT pipeline development locally.** The synthetic-document generation pipeline (US-5) reads the ST corpus and generates expanded training documents using a teacher model. The pipeline code itself can be developed and tested locally against a small model. The actual generation pass (where we want high-quality outputs) runs against Azure GPT-4o, but iterating the prompts and validation logic happens locally for free.

**Limitations honestly named.** A3500 cannot substitute for cloud fine-tuning at meaningful scale. Cannot run 70B even quantized. Cannot do the V6 §11.8 step-change test directly. Treats a small slice of engineering work, not science.

Deliverable: local Python development environment with GPU access; local eval pipeline running against small models; documented handoff procedure between local development and cloud production runs.

**Statistical methodology document.** Establishes the standards: how many scenarios per condition, what scoring rubric, how we compute effect sizes, what counts as "statistically significant," how we handle the multiple-comparison problem (we're testing many models × many conditions × many benchmarks, and naive p<0.05 produces false positives at scale). This document gets written at Tier 0 and adhered to throughout. Standardization makes the cross-tier comparison defensible to peer reviewers and grant gatekeepers.

Deliverable: versioned eval suite, statistical methodology document, integration with existing benchmarks where licensing permits.

---

## Detail

### The strategic shape

Tiering reflects two principles working together:

1. **Capability progression matches resource progression — but cloud fine-tuning collapses Tier 0/1 partially.** Tier 0 (cloud only) now tests *both* prompted-context AND fine-tuning at 70B scale, because Databricks Mosaic / Azure ML / Snowflake Cortex make fine-tuning affordable at $200-500 per cycle. Tier 1 (local hardware) becomes *iteration acceleration* rather than the fine-tuning gate. Tier 2 (frontier compute) tests the strongest claim (does V6 §11.8 step-change appear at near-ASI scale?). Each tier's claim is informed by the prior tier's methodology being validated.

2. **Each tier produces gatekeeper-ready artifacts.** Tier 0 produces multi-model effect-size data + 70B fine-tuning step-change result + methodology document, presentable to grant gatekeepers AND H200-access gatekeepers. Tier 1 produces faster-iteration ablations and refined methodology, presentable as evidence-of-thoroughness for Tier 2. Tier 2 produces frontier-scale demonstration, publishable as research.

### Why this isn't just "scale the experiment up gradually"

A naive plan would be: "run experiment small, run experiment medium, run experiment large." That works if the only variable is scale. Here, the *intervention itself* is multi-layered (corpus + context-cultivation, prompted vs fine-tuned, V6 §11.8's step-change is specifically about the *interaction*), so each tier tests a structurally different version of the hypothesis. Tier 0 tests both "does prompted-context work?" and "does fine-tuning at 70B amplify the effect?" Tier 1 (local) accelerates iteration on what Tier 0 already tested. Tier 2 tests "does the step-change appear at near-ASI scale, and does full-fine-tune-vs-QLoRA affect it?"

Each tier's question is genuinely informed by the prior tier's answer. We don't go to Tier 2 with the same question we asked at Tier 0; we go to Tier 2 with a refined question shaped by Tier 0/1 results.

### Cost discipline

**Tier 0 budget target: ~$3-5K, capped at $7K.** Higher than originally planned because cloud fine-tuning is now in scope at this tier. The cap matters because going significantly above creates institutional friction (DXC budget approvals, etc.) that slows momentum. Discipline is engineered through: DXC partnership pricing exploitation upfront, small benchmark sizes initially before scale-up, careful model selection (avoid burning budget on low-headroom RLHF'd models), local A3500 development environment to minimize per-API-call dev costs, batch evaluation where possible, intermediate-result capture so failed runs don't re-run.

Tier 1 marginal cost: ~$0 for compute (local hardware), saves cloud spend on iteration cycles that would otherwise cost $200-500 each.

Tier 2 marginal cost: ~$0 for compute (institutional access). Preparation overhead is the main "cost" (engineering time, all on Tier 0/1 substrate).

Stretch tier: $100K class grant covers everything if approved.

**Total project budget consumed before grant: ~$3-7K, well under the $10K ceiling.**

### Sequencing dependencies

- **Tier 0 Phase A** (eval framework + prompted-context) runs immediately, no dependencies
- **Tier 0 Phase B** (cloud fine-tuning) requires Phase A methodology validated + DXC partnership pricing identified
- **Tier 1 (optional)** can be activated whenever local hardware access materializes; accelerates Phase B iteration
- **Tier 2** requires Tier 0 results presentable + 8× H200 access opportunity; Tier 1 strongly recommended for Tier 2 preparation but not strictly required
- **Stretch** requires Tier 2 results + grant cycle timing

### Risk mitigation

**Tier 0 risks:** Azure / Databricks model deprecation between experiments (version-pin in code), API rate limits during heavy eval runs (exponential backoff, batching), eval methodology bugs not caught early (rigorous testing on local A3500 before scale-up), DXC partnership pricing not as favorable as expected (have Azure ML fallback path validated before committing to Databricks).

**Tier 1 risks:** Hardware access intermittent (capture checkpoints, document recovery procedures), local-vs-cloud methodology divergence (replicate one Tier 0 result locally as sanity check before relying on local results).

**Tier 2 risks:** Precious-burst failure modes (training crashes, eval pipeline glitches, scrutiny conflicts). Mitigation: fully rehearse the entire Tier 2 plan on Tier 0/Tier 1 substrate first at smaller scale. The Tier 2 session executes a script, not exploration. Backup plan: if H200 session fails, fall back to Tier 0 70B fine-tune results as the primary publishable artifact (still a meaningful result).

### Success criteria

**Tier 0 success:** Working pipeline + multi-model effect-size data on prompted-context + 70B fine-tuning step-change result + methodology document. Effect-sizes can be positive (>5% deception reduction with statistical significance) OR null (effect <2% across models). Both are scientifically informative — positive amplifies the next-tier hypothesis; null sharpens it (suggests scale dependence or RLHF interaction).

**Tier 1 success:** Faster + cheaper iteration enabling more thorough Tier 2 preparation. Not a separate scientific milestone; supports Tier 2.

**Tier 2 success:** Frontier-scale demonstration of V6 §11.8 hypothesis (positive case = step-change at 405B; negative case = step-change attenuates at scale, suggesting hypothesis holds at research-baseline but not frontier — still publishable).

**Stretch success:** Peer-reviewed publication or major-venue technical report, multiple replications, side-by-side comparison vs. Constitutional AI baseline.

### Connection to F-007 and F-008

F-007 captures V6 doctrinal review (the corpus content that this research tests). F-008 captures deferred corpus-cleanup items (non-blocking for this research). F-009 (this feature) captures the empirical research execution. F-007 review should complete before F-009 Tier 0 Phase B (cloud fine-tuning) commits, because doctrinal corrections during F-007 review may affect what we fine-tune on. F-007 review can run in parallel with F-009 Tier 0 Phase A (prompted-context evaluation does not depend on doctrinal stability, only on having *some* corpus to inject).

### When to revisit this plan

Revisit after Tier 0 results — the actual effect size and pattern (which doctrinal claims move which deception types) will inform whether Tier 1 should be exactly as planned or restructured. Revisit again after Tier 1 results before committing to the H200 session preparation — if Tier 1 shows null effect, Tier 2 design changes substantially.
