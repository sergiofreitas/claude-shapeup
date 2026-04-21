# Shape Up Plugin — Test Suite

Two-layer testing architecture, aligned to what's actually deterministic.

## Philosophy

**Deterministic checks for scaffolding. LLM-as-judge for outcomes.**

- Hooks, scripts, and SKILL.md structure are text-over-code. Assert them exactly.
- Agent outputs (what the model produces when a SKILL is applied) are
  non-deterministic. Evaluating them by text diff turns every run into noise;
  evaluate them by meaning instead, with rubric-based LLM-as-judge scenarios.

There is no snapshot / baseline layer. See `../CLAUDE.md` and `../CONTRIBUTING.md`
for the rationale.

## Layers

| Layer | Subject | Speed | Requires LLM | Fires on |
|---|---|---|---|---|
| **Unit** | Hooks, scripts, prompt structure (placeholders, `$FEATURE_DIR` blocks, hook wiring) | Seconds | No | `pre-commit` |
| **Behavioral** | Agent outcomes via LLM-as-judge against rubric-based scenarios | Minutes | Yes | `pre-push` when prompts / hooks / references change |

## Quick Start

```bash
# Unit only — fast, deterministic.
bash tests/run-all.sh --unit

# Behavioral only — slow, needs claude CLI.
bash tests/run-all.sh --behavioral

# Both.
bash tests/run-all.sh
```

## Layer 1: Unit Tests

Deterministic bash tests for hooks, scripts, and SKILL.md structure.

```bash
# Run all unit tests
bash tests/run-all.sh --unit

# Or run one at a time:
bash tests/unit/test-phase-guard.sh
bash tests/unit/test-ripple-check.sh
bash tests/unit/test-commit-gate.sh
bash tests/unit/test-consistency-check.sh
bash tests/unit/test-session-budget.sh
bash tests/unit/test-resolve-feature.sh
bash tests/unit/test-prompt-grounding.sh
```

**What they cover:**

- `test-phase-guard.sh` — Phase transition gates (`Frame Go → Shape`, `Shape Go → Build`, etc.)
- `test-ripple-check.sh` — Horizontal scope-name detection, doc-type detection, exit codes
- `test-commit-gate.sh` — `git commit` interception, `.shapeup/` consistency gate, dispatcher wiring
- `test-consistency-check.sh` — Scope ↔ hillchart ↔ must-have drift detection
- `test-session-budget.sh` — Session counting, appetite detection, task tallies
- `test-resolve-feature.sh` — Feature-key resolution (date-slug, short slug, legacy NNN)
- `test-prompt-grounding.sh` — Placeholder grounding (B1) and `$FEATURE_DIR` same-block (B2)

## Layer 2: Behavioral Tests

LLM-as-judge evaluation of agent behavior against rubric-based scenarios.

```bash
# Run all behavioral tests
bash tests/behavioral/run-behavioral.sh --all

# Run a single scenario
bash tests/behavioral/run-behavioral.sh scope-completion-commit-discipline

# List available scenarios
bash tests/behavioral/run-behavioral.sh --list
```

**Criteria** (`behavioral/criteria/`) — one file per behavior, pass + fail conditions:

- `emergent-scope.md` — Agent captures feedback as scope tasks, never re-shapes
- `vertical-scopes.md` — Scope names describe business capabilities, not layers
- `nice-to-have-surfacing.md` — Agent surfaces nice-to-haves before shipping
- `phase-boundaries.md` — Agent stays within its phase, redirects out-of-phase work
- `commit-discipline.md` — One commit per scope completion, bundled with tracking docs and discoveries; handover separate

**Scenarios** (`behavioral/scenarios/`) — setup + user input + criterion ref:

- `user-raises-concern-during-build.md`
- `scope-discovery-api-project.md`
- `must-haves-done-sessions-remain.md`
- `frame-user-proposes-solution.md`
- `scope-completion-commit-discipline.md`

**Pipeline:** scenario → `claude -p` with SKILL.md system prompt → agent response → `claude -p` with `judge-rubric.md` → PASS/FAIL per condition → final verdict.

**Results** are written to `behavioral/results/<scenario>.json` (gitignored) on every run.

## Adding New Tests

### New unit test
Add `tests/unit/test-<name>.sh`. Follow the `pass` / `fail` / assertion pattern
from existing tests. The pre-commit hook auto-picks up any `test-*.sh`.

### New behavioral test
1. Add a criterion file to `tests/behavioral/criteria/<name>.md`. Keep it to one
   behavior with explicit pass + fail conditions.
2. Add a scenario to `tests/behavioral/scenarios/<name>.md` with sections
   `## Setup`, `## Package Context`, `## User Input`, `## Criteria`,
   `## Expected Behavior`. The `## Criteria` line names the criterion file
   (without the `.md`).
3. Run: `bash tests/behavioral/run-behavioral.sh <scenario-name>`.

## Architecture

```
tests/
├── run-all.sh                         ← Entry point: unit + behavioral
│
├── unit/                              ← Layer 1: deterministic, no LLM
│   ├── test-commit-gate.sh
│   ├── test-consistency-check.sh
│   ├── test-phase-guard.sh
│   ├── test-prompt-grounding.sh
│   ├── test-resolve-feature.sh
│   ├── test-ripple-check.sh
│   └── test-session-budget.sh
│
└── behavioral/                        ← Layer 2: LLM-as-judge
    ├── run-behavioral.sh
    ├── judge-rubric.md                ← Judge system prompt
    ├── criteria/                      ← Pass/fail conditions per behavior
    ├── scenarios/                     ← Adversarial inputs that trigger behaviors
    └── results/                       ← Judge JSON outputs (gitignored)
```
