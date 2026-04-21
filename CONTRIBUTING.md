# Contributing

This plugin's skills are mostly prompts. A prompt edit can silently change what
the agent produces even when deterministic scaffolding tests still pass. The
testing philosophy here follows a single rule:

> **Deterministic checks for scaffolding. LLM-as-judge for outcomes.**

Exact-text assertions work on shell scripts, hook wiring, and SKILL.md
structure — those are all deterministic. Agent outputs (what the model
produces when a SKILL is applied) are non-deterministic, so exact-text
regression checks (snapshot diffs) become noise: every run shows wording
jitter, real regressions hide in the noise, and contributors either
rubber-stamp updates or ignore the gate entirely. Outcome regressions
belong in rubric-based LLM-as-judge scenarios instead.

## One-time setup

After cloning, activate the tracked git hooks:

```bash
bash scripts/setup-hooks.sh
```

This sets `core.hooksPath` to `.githooks/`. From then on:

- **`pre-commit`** runs `tests/run-all.sh --unit` and blocks the commit on red.
- **`post-commit`** auto-bumps the patch version in `plugin.json` and
  `marketplace.json` and folds the bump into the commit that just landed.
  Skips when the triggering commit already changed the version line, so
  manual minor / major bumps ride along untouched.
- **`pre-push`** runs `tests/run-all.sh --behavioral` **only when** any
  `skills/*/SKILL.md`, `hooks/`, `references/`, or `skills/*/scripts/` file
  changed in the commits being pushed.

Bypass with `git commit --no-verify` (or `SHAPEUP_SKIP_BEHAVIORAL=1 git push`)
only when you know exactly why and the bypassed check is genuinely irrelevant
to your change.

## Test layers

| Layer | Runs | What it catches | Cost |
|---|---|---|---|
| Unit | `bash tests/run-all.sh --unit` | hook / script logic, placeholder grounding, `$FEATURE_DIR` block locality, hook wiring | seconds, no LLM |
| Behavioral (LLM-judge) | `bash tests/run-all.sh --behavioral` | semantic correctness of agent outcomes against rubric-based scenarios | minutes, non-deterministic |

- **Unit tests are deterministic**: they must be green before anything else.
  The pre-commit hook enforces this.
- **Behavioral tests are evaluation-by-meaning**: the judge scores each pass /
  fail condition independently against the agent's response. Output is noisy;
  treat one failure as a flag, not a block. Consistent failures across re-runs
  are real regressions.

There is no snapshot / baseline layer. See `CLAUDE.md` for the rationale.

## Prompt-change workflow

Follow this sequence whenever you edit a SKILL.md, a reference under
`references/`, or any shared script that the skills call into.

1. **Write the change.** Make the edit.

2. **Run unit tests.** They must be green before you go further.
   ```bash
   bash tests/run-all.sh --unit
   ```
   If the `test-prompt-grounding.sh` layer fails, you've reintroduced an
   undefined placeholder or an ungrounded `$FEATURE_DIR` reference — fix it
   before continuing.

3. **Run behavioral tests if the change is semantic.** If the edit goes beyond
   wording (e.g. you changed what the agent commits, when it commits, how it
   names scopes, which artifacts it emits), outcome-level regression is
   possible. Behavioral runs the SKILL against rubric-based scenarios and has
   an LLM judge evaluate each response:
   ```bash
   bash tests/run-all.sh --behavioral
   ```
   Expect noise. Re-run once if a scenario fails; a consistent fail is a real
   regression. If the scenario tests a behavior you intentionally changed, the
   criterion needs updating, not the prompt.

4. **If you introduced a new outcome invariant, add coverage for it.**
   - New criterion → `tests/behavioral/criteria/<name>.md` (pass + fail
     conditions, one behavior per file).
   - New scenario → `tests/behavioral/scenarios/<name>.md` (setup + user input +
     `## Criteria` line pointing at the criterion name).

5. **Commit with a tight message.** Example:
   ```
   fix(build): tighten scope-emergence wording in Step 3

   - Replace "pre-plan scopes" with "discover scopes from work"
   - Extend tests/behavioral/criteria/emergent-scope.md with a new
     fail condition for agents that bail back to shaping
   ```

## What counts as a "breaking" prompt change

A prompt change is breaking when it changes the *contract* the agent gives the
user: new files emitted, existing files removed, status labels renamed, step
numbering shifted. When a change is breaking:

1. Bump the plugin version in `.claude-plugin/plugin.json` and
   `.claude-plugin/marketplace.json` (minor for additive contract changes,
   major for removals / renames) in the same commit as the breaking edit.
   The post-commit hook only bumps patch, and it skips when it sees the
   version already changed in the commit — so a manual minor/major bump
   rides along.
2. Note the breaking change in the commit body.
3. Keep any legacy-path support code (e.g. the resolver's NNN fallback) until
   at least one release after the break.

## Running one scenario at a time

Behavioral is slow. During iteration:

```bash
# Unit tests only — sub-second.
bash tests/run-all.sh --unit

# One behavioral scenario.
bash tests/behavioral/run-behavioral.sh scope-completion-commit-discipline

# List scenarios.
bash tests/behavioral/run-behavioral.sh --list
```

## What lives where

| Path | Committed? | Why |
|---|---|---|
| `tests/unit/**` | yes | Deterministic scaffolding checks. |
| `tests/behavioral/scenarios/**` | yes | Test inputs — stable across runs. |
| `tests/behavioral/criteria/**` | yes | Pass/fail conditions — the judge rubric. |
| `tests/behavioral/results/**` | no (gitignored) | LLM-judge JSON outputs — regenerated every run, non-deterministic. |

If you find yourself wanting to commit a behavioral run's output to "freeze"
the agent's response, don't. That's reinventing the snapshot gate.
Tighten the criterion instead.
