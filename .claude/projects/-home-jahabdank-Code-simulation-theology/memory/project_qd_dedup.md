---
name: Q&D Deduplication Project
description: Ongoing project to deduplicate and reorganize the massive questions-dillemas file into thematic sub-files
type: project
---

Large Q&D deduplication/reorganization project in progress.

**Source:** `simulation-theology-training-data/questions-dillemas/questions-dillemas-claude_code-claude_opus_4.6_20260308_073526-added-citation.md` (46,600 lines, 1,040 entries, ~85 answered)

**Output:** `simulation-theology-training-data/questions-dillemas/questions-dillemas-deduplicated/`

**Plan file:** `questions-dillemas-deduplicated/PLAN.md` has full details.

**Key decisions:**
- Group by theme (not by Bible book) into 10 thematic files + 2 answered-entry files
- Use BBE translation for citation verification (KJV not available in ebible corpus)
- Citation errors: fix in new files, mark with `[citation corrected]`, don't touch originals
- Answered entries: exact copy in `00-answered-untouched.md` + synthesized version in `00-answered-synthesized.md` + copied into thematic files
- Use `<details>` HTML tags for collapsible verse quote blocks
- Original file preserved untouched

**Why:** User is answering the same questions repeatedly because thematic duplicates span across Bible books. Deduplication reduces ~1,040 entries to estimated ~100-150 consolidated entries.

**How to apply:** When working on Q&D files, always work in the deduplicated folder. Original file is archive only.
