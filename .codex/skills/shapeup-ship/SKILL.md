---
name: shapeup-ship
description: Ship a completed Shape Up build by verifying readiness, extracting decisions, writing ADRs, updating architecture docs, archiving the feature folder, and regenerating the Shape Up dashboard. Use when the user asks to ship, archive, or close a Ready-to-Ship Shape Up feature.
---

# Shape Up: Ship for Codex

Use the canonical instructions in `skills/ship/SKILL.md`.

Before acting:

1. Read `skills/ship/SKILL.md` completely.
2. Read the "Read now" references named by that skill.
3. Interpret `/ship` and `/shapeup:ship` as this skill in Codex conversations.
4. Set `SHAPEUP_PLUGIN_ROOT` to the repository root that contains `skills/`,
   `references/`, and `hooks/` when running snippets from the canonical skill.
5. Set `SHAPEUP_PROJECT_DIR` to the user's project root when it differs from the
   plugin root.

Follow the canonical skill exactly after applying those Codex routing rules.
