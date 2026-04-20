# Contributing

This plugin's skills are mostly prompts. A prompt edit can silently change what the
agent produces even when every unit test still passes, because the structural checks
only verify shape ("does hillchart.md have a Scopes section?"), not content quality.
The regression story therefore has three layers, and you need to run all three whenever
you touch a SKILL.md, a hook, or a shared script.

## One-time setup

After cloning, activate the tracked git hooks that enforce the workflow at commit time:

```bash
bash scripts/setup-hooks.sh
```

This sets `core.hooksPath` to `.githooks/`. From then on:

- **`pre-commit`** runs `tests/run-all.sh --unit` and blocks the commit on red.
- **`commit-msg`** blocks commits that change a `skills/*/SKILL.md` without either
  co-staging `tests/results/` updates OR including `baselines unchanged` /
  `breaking change` in the commit message body.

Bypass with `git commit --no-verify` only when you know exactly why and the
bypassed check is genuinely irrelevant to your change.

## Test layers

| Layer | Runs | What it catches | Cost |
|---|---|---|---|
| Unit | `bash tests/run-all.sh --unit` | hook / script logic, placeholder grounding, variable wiring | seconds, no LLM |
| Structural snapshot | `bash tests/diff-against-baseline.sh` | content drift in generated artifacts | ~1 min per fixture (LLM) |
| Behavioral (LLM-judge) | `bash tests/run-all.sh --behavioral` | semantic correctness against a rubric | slow, non-deterministic |

- **Unit tests are deterministic**: they must be green before anything else.
- **Structural snapshots are the regression spine for prompt changes**: the committed
  `tests/results/` tree is a golden baseline. Prompt edits that alter generated artifacts
  show up as diffs against this baseline, so the PR reviewer can see exactly what
  changed.
- **Behavioral tests are advisory**: LLM-as-judge output is non-deterministic. Use them
  to catch semantic regressions, but don't require them to pass deterministically.

## Prompt-change workflow

Follow this sequence whenever you edit a SKILL.md, a reference under `references/`,
or any shared script that the skills call into.

1. **Write the change.** Make the edit.

2. **Run unit tests.** They must be green before you go further.
   ```bash
   bash tests/run-all.sh --unit
   ```
   If the `test-prompt-grounding.sh` layer fails, you've reintroduced an undefined
   placeholder or an ungrounded `$FEATURE_DIR` reference — fix it before continuing.

3. **Diff against the committed baselines.** This regenerates artifacts for every
   fixture into a scratch dir and diffs them against `tests/results/`:
   ```bash
   bash tests/diff-against-baseline.sh
   ```
   Three possible outcomes:
   - **No drift** → your prompt change didn't move the generated output. Commit and
     open the PR.
   - **Drift, and it was intentional** (you expected the output to change) → rerun with
     `--update` to overwrite the baselines, then commit the baseline updates **in the
     same commit** as the prompt change. A reviewer reading the PR should see both.
     ```bash
     bash tests/diff-against-baseline.sh --update
     git add tests/results/
     ```
   - **Drift, and it was NOT intentional** → your prompt change has side effects you
     didn't plan for. Tighten the prompt until the diffs disappear (or shrink to only
     the bits you meant to change).

4. **Run behavioral tests if the change is semantic.** If you moved beyond wording
   (e.g., you changed how build picks the first piece, or how shape validates the fit
   check), the structural snapshot may still pass while the semantic behavior regresses.
   Run:
   ```bash
   bash tests/run-all.sh --behavioral
   ```
   Expect noise — don't block on single-run failures. Look for consistent regressions.

5. **Commit with a tight message.** Example:
   ```
   fix(build): tighten scope-emergence wording in Step 3

   - Replace "pre-plan scopes" with "discover scopes from work"
   - Regenerate baselines: large-multi-session scope list stabilized
     around 4 scopes instead of oscillating between 3-6
   ```

## What counts as a "breaking" prompt change

A prompt change is breaking when it changes the *contract* the agent gives the user:
new files emitted, existing files removed, status labels renamed, step numbering
shifted. When a change is breaking:

1. Bump the plugin version in `.claude-plugin/plugin.json` and
   `.claude-plugin/marketplace.json`.
2. Note the breaking change in the PR description (reviewers may need to update their
   own `.shapeup/` directories).
3. Keep any legacy-path support code (e.g. the resolver's NNN fallback) until at least
   one release after the break.

## Running one fixture at a time

The whole suite takes a couple of minutes because of LLM calls. During iteration:

```bash
# Unit tests only — sub-second.
bash tests/run-all.sh --unit

# Just one fixture's snapshot — ~30-60s.
bash tests/diff-against-baseline.sh small-single-session

# Just one fixture's behavioral judge.
bash tests/behavioral/run-behavioral.sh frame-user-proposes-solution
```

## Baselines: committed or not?

| Path | Committed? | Why |
|---|---|---|
| `tests/fixtures/**` | yes | Test INPUTS — stable across runs |
| `tests/results/**` | yes | Structural snapshot baselines (see workflow above) |
| `tests/behavioral/results/**` | no (gitignored) | LLM-judge JSON outputs — regenerated every run, non-deterministic |

If you ever find `tests/results/` is churning noisily on every run (multiple contributors
seeing constant whitespace drift), the first fix is to make `generate-artifacts.sh`
deterministic (temperature 0, pinned model version). Re-baselining as a habit is a
sign something is wrong with generation, not with the baselines.
