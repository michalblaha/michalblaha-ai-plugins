# Session Handoff: wiki-tools — agents delegated to skills, vault init command, dynamic page layout
**Date**: 2026-05-31 22:00
**Branch**: main
**Working Directory**: /Users/michalblaha/Documents/Dev/Dev Projects/michalblaha-ai-plugins

## What Was Done

### Agents → skills unification
- `plugins/wiki-tools/agents/wiki-lint.md`: added `Edit` + `Skill` to tools. Body rewritten to delegate the full lint procedure to skill `wiki-tools:wiki-lint` instead of duplicating its checks. Safe auto-fixes (frontmatter padding, stub pages, missing wikilinks) apply automatically; risky ones (delete orphans, merge duplicates, resolve contradictions) go into `Needs review` in the report. Never touches `raw/`.
- `plugins/wiki-tools/agents/wiki-ingest.md`: added `Bash`, `WebFetch`, `Skill` to tools. Body rewritten to delegate to skill `wiki-tools:wiki-ingest`. Accepts either a file path in `raw/` or a `https://` URL. URL ingest fetches via `WebFetch`, optionally cleans via `defuddle` (detected through `which defuddle`), saves to `raw/articles/[slug]-[YYYY-MM-DD].md`, then runs Single Source Ingest. Parallel-safety constraints: must NOT touch `wiki/index.md`, `wiki/hot.md`, `wiki/log.md`, `.manifest.json` (orchestrator does these after all agents finish). May CREATE new files in `raw/articles/` during URL ingest but never modifies existing `raw/` documents.

### Autoresearch dynamic page layout
- `plugins/wiki-tools/skills/wiki-autoresearch/SKILL.md`: new section **Detekce uspořádání vaultu** — 6-step procedure that maps `{(type[, sub-type]) → folder}` by grepping `type:` frontmatter of existing pages and picking the folder with the most matches. Falls back to active profile's `Fallback uspořádání` table, then to English defaults. Synthesis frontmatter example and user report rewritten to use placeholders `<source-folder>` etc.
- `plugins/wiki-tools/skills/wiki-autoresearch/references/default.md`: `Ukládání výsledků` rewritten typed (no hardcoded paths). New `Fallback uspořádání` table — Czech folders (`wiki/zdroje/`, `wiki/myslenky/`, `wiki/entity/`, `wiki/reserse/`).
- `plugins/wiki-tools/skills/wiki-autoresearch/references/gov-project.md`: same restructure, preserving domain typology with sub-type keys `(type, entity_type/source_type)`: `projekty/`, `dodavatelé/`, `instituce/`, `osoby/`, `entity/`, `media/`, `zdroje/`, `myslenky/`, `otazky/`.

### New /wiki-create command
- `plugins/wiki-tools/commands/wiki-create.md`: idempotent vault init. Copies `${CLAUDE_PLUGIN_ROOT}/CLAUDE.md` to project root if missing, creates `raw/`, `raw/_attachments/`, `wiki/` with starter `index.md`, `log.md`, `hot.md` (only if absent). Deliberately does NOT pre-create domain subfolders (`sources/`, `entities/`, `concepts/`) — those are chosen dynamically by autoresearch detection. Heuristics check `.git/`, `package.json`, `pyproject.toml`, `README.md` for project root.

### Versioning
- `plugins/wiki-tools/.claude-plugin/plugin.json` and `.codex-plugin/plugin.json` bumped across the session: `1.3.0 → 1.4.0 → 1.4.1 → 1.4.2 → 1.5.0 → 1.5.1 → 1.6.0`.

## Current State

Working tree is clean, all changes pushed to `origin/main`. Latest plugin version is `1.6.0`. Two follow-up commits (`e0a8c00 lint improvement`, `8b58a5f export into html`, `9f4df7e Delete plugins/wiki-tools/scripts/export2HTML directory`) landed after my last direct push but before this handoff — not authored in this session.

### Git State
- **Modified**: none
- **Untracked**: none
- **Recent commits**:
  - `9f4df7e` Delete plugins/wiki-tools/scripts/export2HTML directory
  - `8b58a5f` export into html
  - `7b3f941` wiki-tools: add /wiki-create command + confidence_overall convention
  - `e0a8c00` lint improvement
  - `ae29d1a` wiki-tools: autoresearch — derive page folders from vault content
  - `558e1a5` wiki-tools: bump version to 1.4.1
  - `d9a87a0` wiki-tools: delegate agents to skills, add URL ingest to wiki-ingest agent

## What Remains
- [ ] Validate `/wiki-create` end-to-end in a fresh project (cwd detection, idempotence on second run, CLAUDE.md skip-when-present).
- [ ] Run `wiki-lint` subagent against a real vault and confirm it actually invokes `wiki-tools:wiki-lint` via Skill (not just reads SKILL.md as text).
- [ ] Test URL ingest path in `wiki-ingest` agent — verify slug derivation and `raw/articles/` write.
- [ ] Decide whether the parallel `wiki-ingest` orchestrator should also write `.manifest.json` entries for URL-fetched files (currently agents don't touch manifest at all).
- [ ] Consider unifying `wiki-lint` agent + skill (overlap is large; agent is now a thin wrapper). Open question whether to keep both or drop the agent.
- [ ] Possible follow-up: add `commands/wiki-create.md` analogue for the Codex plugin (currently only Claude commands are wired).

## Key Decisions Made

- **Czech fallback folders** in `default.md` (`zdroje/myslenky/entity/reserse/`) — chosen over English to match the profile's Czech voice. English (`sources/concepts/entities/research/`) remain as last-resort skill-level defaults if profile has no fallback section.
- **`type:` frontmatter is the detection discriminator**, not folder name — robust against renames and mixed naming.
- **Sub-type keying** `(type, entity_type)` and `(type, source_type)` lets gov-project profile preserve its domain typology (companies, institutions, persons, media) without hardcoding paths.
- **Subagent stays report-mostly**: `wiki-lint` applies only skill's "safe" auto-fixes; risky ones defer to user because subagent cannot interactively ask.
- **Parallel-safety boundary**: `wiki-ingest` agent never mutates shared singletons (`index.md`, `hot.md`, `log.md`, `.manifest.json`) — orchestrator does after all per-source agents complete.
- **`/wiki-create` does NOT pre-create domain subfolders** — would conflict with autoresearch's content-based detection (it would always find the empty pre-created folders).
- Renamed `/create` → `/wiki-create` for consistency with `/wiki-autoresearch` (done by user/linter post-write).

## Gotchas / Notes

- The `confidence_overall` page-level field + inline `míra jistoty: low|medium|high` convention shipped alongside the agent/skill unification in commit `7b3f941`. Was authored in parallel by user (linter notes), not by me — but is now load-bearing in CLAUDE.md, all templates, `wiki-lint` skill, and both autoresearch profiles.
- Version numbers jumped twice mid-session due to external linter bumps (`1.4.1→1.4.2`, `1.5.0→1.5.1`). Don't assume my commits are the only version-changing actor.
- The `wiki-lint` subagent has `Skill` in its tools but the skill's own auto-fix safety check ("show report first, ask before fixing") was relaxed for the subagent because it cannot ask interactively. This is a deliberate divergence from skill semantics.
- `wiki-ingest` URL ingest writes to `raw/articles/` — this is the only path where the agent is allowed to create files inside `raw/`. Existing raw documents remain immutable.
- All slash commands are namespaced under the plugin (`wiki-tools:wiki-create`, `wiki-tools:wiki-autoresearch`).

## Key Files

- `plugins/wiki-tools/agents/wiki-lint.md` — subagent definition, now delegates to skill
- `plugins/wiki-tools/agents/wiki-ingest.md` — subagent definition, now delegates to skill + supports URLs
- `plugins/wiki-tools/skills/wiki-autoresearch/SKILL.md` — new "Detekce uspořádání vaultu" section drives page placement
- `plugins/wiki-tools/skills/wiki-autoresearch/references/default.md` — Czech fallback layout
- `plugins/wiki-tools/skills/wiki-autoresearch/references/gov-project.md` — domain-typed fallback layout with sub-types
- `plugins/wiki-tools/commands/wiki-create.md` — new vault init command
- `plugins/wiki-tools/CLAUDE.md` — contains the `confidence_overall` convention now referenced by skills and templates
- `plugins/wiki-tools/.claude-plugin/plugin.json` + `.codex-plugin/plugin.json` — version `1.6.0`
