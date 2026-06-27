# Working on this repo

This repository is a Shape Up skill pack for AI coding agents. The canonical
methodology lives in `skills/*/SKILL.md`, `references/`, `hooks/`, and shared
scripts. Claude Code consumes the `.claude-plugin/` package. Codex consumes the
project-local wrappers in `.codex/skills/`.

When changing agent behavior, treat prompt edits like code:

- Read `CLAUDE.md` and `CONTRIBUTING.md` before editing `skills/*/SKILL.md`,
  `references/*`, hooks, or behavior tests.
- Keep the methodology agent-neutral unless a section is explicitly about a
  specific host tool.
- Prefer `SHAPEUP_PROJECT_DIR` and `SHAPEUP_PLUGIN_ROOT` in docs/scripts. Keep
  `CLAUDE_PROJECT_DIR` and `CLAUDE_PLUGIN_ROOT` only as compatibility fallbacks.
- Maintain `.ps1` peers for runtime `.sh` scripts because Claude Code users for this
  project are expected to run on Windows.
- Run `bash tests/run-all.sh --unit` after deterministic changes on Unix-like hosts. On Windows, use the PowerShell runtime scripts for manual parity checks until a full PowerShell test harness exists.
- Run the behavioral suite when prompt contract changes matter and the required
  headless agent CLI is available.

Codex skill wrappers should stay thin. Update the canonical skill first, then
adjust `.codex/skills/shapeup-*/SKILL.md` only when routing or Codex-specific
usage changes.
