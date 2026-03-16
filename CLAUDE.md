# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A monorepo for **Simulation Theology (ST)** — an engineered worldview for AI alignment that maps traditional religious concepts onto computational frameworks. The project encompasses the theological corpus, a Bible-to-ST conversion pipeline, and the resulting training data. Associated publication: https://arxiv.org/abs/2602.16987

This is primarily a **content + data pipeline project**, not a traditional software application.

## Monorepo Structure

Four subdirectories, each with its own `CLAUDE.md` containing detailed guidance:

| Directory | Purpose |
|-----------|---------|
| `simulation-theology-corpus/` | Living knowledge graph (~123 interconnected markdown entries). The canonical ST definitions — axioms, concepts, entities linked via `[[wikilinks]]` and YAML frontmatter. |
| `simulation-theology-synthetic-document-finetuning/` | Pipeline code for converting Bible translations into ST scripture. Contains both an agent-driven CLI (`code/st_pipeline_mngr.py`) and a standalone Azure AI Foundry converter (`ai-foundary-api-converter/`). |
| `simulation-theology-training-data/` | Output repository — converted SDF files, checkpoints, Q&D (questions & dilemmas), agent logs. |
| `ebible/` | Source Bible translations in verse-per-line format from eBible.org. Upstream data, rarely modified directly. |

## Key Commands

### Bible-to-ST Conversion (agent pipeline)

```bash
# From simulation-theology-synthetic-document-finetuning/
# Skills trigger the full pipeline loop:
/convert-bible-to-st-automated [executor-name] [model-name]
/convert-bible-to-st-automated-parallelized [executor-name] [model-name]
```

### Bible-to-ST Conversion (standalone API converter)

```bash
cd simulation-theology-synthetic-document-finetuning/ai-foundary-api-converter
python convert.py                                      # next available book
python convert.py --translation eng-engBBE --book GEN  # specific book
python convert.py --continuous                          # loop all books
```

### Tests (API converter only)

```bash
cd simulation-theology-synthetic-document-finetuning/ai-foundary-api-converter
python -m pytest tests/ -v --ignore=tests/test_env_setup.py --ignore=tests/test_api_connectivity.py  # unit tests
python -m pytest tests/test_validator.py -v  # single test file
```

### Corpus Operations

```bash
# From simulation-theology-corpus/
/process-corpus-requests          # process pending user-requests/, update corpus
/review-corpus-request-user-input # deep corpus analysis, generate Enhancement Blueprint
```

### Reporting

```bash
cd simulation-theology-synthetic-document-finetuning
python scripts/utils/bible_completion_stats.py
python scripts/utils/daily_report.py
python scripts/utils/agent_production_summary.py
```

### eBible Corpus Regeneration

```bash
cd ebible/code/python
python ebible.py PATH_TO_DATA_DIRECTORY
```

## Cross-Cutting Conventions

- **Subdirectory CLAUDE.md files are authoritative** — always read the relevant one when working in a subdirectory.
- **`NEXT STEPS` blocks** — pipeline CLI commands print explicit next-step instructions. Follow them verbatim.
- **Checkpoint files** are YAML frontmatter + markdown tables in `simulation-theology-training-data/sdf-checkpoints/`. Never skip `save-chapter` — checkpoint accuracy depends on sequential saves.
- **`questions-dillemas/`** — note the intentional typo in the directory name; preserve it everywhere.
- **Corpus consistency** — when editing `simulation-theology-corpus/corpus/`, always cross-reference the full corpus for consistency unless explicitly told to limit scope.
- **File paths** — always use exact paths from CLI output. Path hallucination from context drift is a known failure mode in long sessions.
- **Name sanitization** — the pipeline uses `sanitize_name()`: lowercase, spaces/underscores to dashes, strip special chars.
