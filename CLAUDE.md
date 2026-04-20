# Working on this repo (baseline instructions for any Claude agent)

This repo is a Claude Code plugin. Its skills under `skills/*/SKILL.md` are
mostly prompts — the agent's behavior is defined by the text, not by code.
A prompt edit can silently shift what the agent produces, even when every
deterministic test still passes. Follow the workflow below on every session
that touches a SKILL.md, a hook, or a shared script. Full rationale:
[`CONTRIBUTING.md`](./CONTRIBUTING.md).

## One-time setup (per clone)

Run once after cloning, to activate the local git hooks that enforce the
workflow at commit time:

```bash
bash scripts/setup-hooks.sh
```

This points `core.hooksPath` at `.githooks/` (tracked in the repo), so
the hooks stay in sync as the repo evolves.

## Before editing a prompt

1. Start from a concrete signal: a failing test, a user complaint, or a
   behavioral scenario. No speculative rewording — if you can't describe
   what's broken, don't edit.
2. Run `bash tests/run-all.sh --unit`. Must be green before continuing.
3. Dispatch an Explore subagent to audit the current state of the skill
   you plan to edit. Do not edit blind.

## After editing a prompt

1. Run unit tests again:
   ```bash
   bash tests/run-all.sh --unit
   ```
2. Run the snapshot regression gate:
   ```bash
   bash tests/diff-against-baseline.sh
   ```
   - **No drift** → commit. Add `baselines unchanged` to the commit body.
   - **Intentional drift** → `bash tests/diff-against-baseline.sh --update`,
     stage `tests/results/` alongside the prompt edit, commit both together.
   - **Unintentional drift** → tighten the prompt until diffs disappear.

## Commit discipline

- **One SKILL = one commit.** Never combine edits to multiple SKILLs in a
  single commit — baselines become impossible to attribute.
- **Never manually edit `plugin.json` / `marketplace.json` versions.** The
  `pre-push` hook bumps the patch automatically. Exception: explicit minor
  or major bumps for breaking changes (new files emitted, status labels
  renamed, step numbers shifted).
- **Never run `--update` without reading the diff.** If you find yourself
  rubber-stamping baselines, generation is non-deterministic — fix
  temperature / seed / prompt determinism, don't keep re-baselining.
- **Never skip hooks with `--no-verify`** unless you know exactly why and
  the tests that would have fired are irrelevant to the change.

## Hard rules (enforced by `tests/unit/test-prompt-grounding.sh`)

These fail the unit suite, which fails the pre-commit hook, which blocks
the commit:

- Every `<plugin-root>`, `<skill-dir>`, `<project-root>` placeholder in a
  SKILL.md MUST have a definition in that same file (a table row or a
  bulleted list item of the form `` - **`<name>`**: <definition> ``).
- Every `$FEATURE_DIR` reference inside a ```bash``` block MUST be assigned
  locally at the top of that same block, **before** first use. Claude
  Code's Bash tool spawns a fresh subprocess per call — shell state does
  not persist between invocations.

If these tests fail on your change, fix the prompt. Do not edit the test
to silence them.

## Breaking prompt changes

A prompt change is breaking when it shifts the contract the agent gives
the user: new files emitted, existing files removed, status labels
renamed, step numbers reordered. For breaking changes:

1. Edit `plugin.json` and `marketplace.json` manually to bump the minor or
   major version BEFORE pushing (the pre-push hook only bumps patch).
2. Explicitly describe the break in the commit body.
3. Keep any legacy-path support (e.g. the resolver's NNN fallback) for at
   least one release after the break.

## When in doubt

- Path and environment variable conventions: see the "Paths and Variables"
  section at the top of each SKILL.md.
- Test-layer responsibilities: see `CONTRIBUTING.md` § Test layers.
- How to extend the grounding tests when you find a new class of mistake:
  `tests/unit/test-prompt-grounding.sh` is itself part of the contract —
  add a new check when you discover a new failure mode.
