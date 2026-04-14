---
name: update-backlog
description: >
  Maintain the feature backlog (features/) — merge new work items into
  existing features, check off completed tasks, create new features, and
  regenerate the index. Use when the user says "update backlog",
  "sync features", "update features", or at session end to capture open work.
argument-hint: "[optional: description of new items or changes to record]"
---

# Update Backlog

Merge new work items into the persistent feature backlog (`features/`),
updating existing feature files or creating new ones.

## Arguments

$ARGUMENTS

- If the user provides specific items to add or update, process those.
- If no argument is given, review the current conversation for any completed
  or newly discovered work items and update accordingly.

---

## Step 1: Read inputs

1. Read all existing feature files from all folders (glob `features/*/F-*.md`).
2. Read `features/index.md` if it exists.
3. If the user provided specific items, parse those. Otherwise, review
   conversation context for completions, new items, or status changes.

## Step 2: Determine next feature ID

Find the highest existing feature number across ALL folders (e.g.,
`F-007-corpus-review.md` -> 7) and increment. If no features exist, start at F-001.

## Step 3: Route items to features

For each work item:

1. **Match against existing features** — read each feature file's user stories
   and task lists. An item matches if it clearly belongs to an existing feature
   (same area of work, same corpus section, same review pass). Semantic matching,
   not string matching.

2. **If matched**: add as a new task checkbox under the appropriate user story,
   or create a new user story section if it doesn't fit any existing one.
   If the item confirms a task is done, check it off (`- [x]`).

3. **If no match**: collect as a candidate for a new feature (Step 4).

## Step 4: Create new feature files

Group unmatched items by theme/area. Each group becomes a new feature file.
Don't create a feature for a single trivial task — collect small unrelated
items into a "Maintenance & Small Tasks" feature file if one doesn't exist.

### Filename format

```
features/{status}/F-{NNN}-{slug}.md
```

- **Status folder**: `backlog/` for new features, `active/` if any task is already done
- **Feature ID**: `F-001`, `F-002`, etc. — sequential, never reused
- **Slug**: kebab-case, 3-5 words — convenience hint, not the identifier

### Feature file format

```markdown
---
id: F-003
title: Q&D Review Files 05-12
status: backlog
priority: P1
area: training-data
created: 2026-04-13
---

# Q&D Review Files 05-12

Phase 1 review of remaining Q&D files containing ~57% of content.
Establishes positions 68+ and triggers second corpus update pass.

## Breakdown

### US-1: Review death-judgment-destruction (file 05)
- [ ] Load session context (QD-REVIEW-WORKFLOW.md, USER-ST-FRAMEWORK.md)
- [ ] Phase 1 Claude comments on file 05
- [ ] User review and position confirmation

### US-2: Review prophecy-divine-communication (file 06)
- [ ] Phase 1 Claude comments on file 06
- [ ] User review and position confirmation

---

## Detail

Files 05-12 were enriched during the April 2026 corpus update but have
not yet undergone the two-pass Q&D review process established for files 01-04.
```

### Field rules

- `id` — sequential, never reused (even if feature is deleted)
- `title` — short, noun phrase or imperative
- `status` — must match folder name: `backlog`, `active`, `done`, `stale`
- `priority` — P0 (urgent) / P1 (important) / P2 (normal) / P3 (nice-to-have)
- `area` — which part of the monorepo: `corpus`, `pipeline`, `training-data`, `ebible`, `cross-cutting`
- `created` — date the feature was first created

### Structure rules

1. **YAML frontmatter** — metadata for agents and index generation
2. **Title + short description** — 1-3 sentences, the "what and why" a human scans
3. **Breakdown section** — user stories as H3 (`### US-N: title`), tasks as checkboxes (`- [ ]` / `- [x]`)
4. **Horizontal rule (`---`)** — separates the scannable overview from the detail
5. **Detail section** — unlimited agent-maintained context below the rule: reasoning, session notes, related links. Agents can write as much as they want here.

### Granularity

A feature is a coherent body of work that takes days-to-weeks and has 2-8
user stories. Small fixes, single-entry edits, and one-off tasks go into a
"Maintenance & Small Tasks" feature rather than creating individual feature files.

**Target**: 15-30 feature files total across all statuses, not hundreds.

## Step 5: Status transitions

Check all feature files for status changes:

- **backlog -> active**: if any task in the Breakdown has been checked off
  (`- [x]`) or is clearly in progress. Move file to `active/`, update `status`
  in frontmatter.

- **active -> done**: if ALL tasks in ALL user stories are checked off.
  Move file to `done/`, update `status` in frontmatter. Never delete done files.

- **backlog/active -> stale**: only if the user explicitly moves it (not
  automated — stale is a manual parking lot for "maybe someday" items).

**Moving a feature between folders:**
1. Read the file
2. Update the `status` field in frontmatter
3. Write to the new folder with the same filename
4. Delete the old file

## Step 6: Regenerate index

Write/overwrite `features/index.md`:

```markdown
# Feature Backlog

> Total: N features — N active, N backlog, N done, N stale
> Last updated: 2026-04-13

## Active

| ID | Feature | Priority | Area | Progress |
|----|---------|----------|------|----------|
| F-002 | Corpus Review Pass | P1 | corpus | 1/7 |

## Backlog

| ID | Feature | Priority | Area | Created |
|----|---------|----------|------|---------|
| F-003 | Q&D Review 05-12 | P1 | training-data | 04-13 |

## Stale

_No stale features._

## Recently Done

| ID | Feature | Area | Completed |
|----|---------|------|-----------|
| F-001 | 7-Pass Corpus Update | corpus | 04-12 |
```

**Progress** = checked tasks / total tasks across all user stories.

Sort each section by priority (P0 first), then by ID.

## Step 7: Report

Print:
- Features updated (which features got new tasks/checkoffs)
- New features created (ID, title, folder)
- Status transitions (moved between folders)
- Total features by status
- Path to index: `features/index.md`

## Important notes

- **One file per feature, not per story.** User stories and tasks live inside feature files as sections and checkboxes.
- **Folder = status, always in sync** — the `status` field in frontmatter MUST match the folder. If they disagree, the folder wins.
- **The `---` separator is the contract** — everything above is the human-scannable overview, everything below is agent detail. Agents must never move structural content (frontmatter, description, Breakdown) below the rule.
- **Never delete feature files** — move to `done/` or `stale/`. The user decides what to remove.
- **Index is always regenerated** — never hand-edit `index.md`.
- **IDs are global** — scan ALL folders to find the highest ID before creating new ones.
