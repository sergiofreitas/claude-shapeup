# Shape Up Plugin — Test Suite

Three-layer testing architecture for the Shape Up workflow plugin.

## Layers

| Layer | What it tests | Speed | Requires LLM |
|-------|--------------|-------|-------------|
| **Unit** | Hooks and scripts work correctly | Seconds | No |
| **Structural** | Generated artifacts have required files/sections/naming | Minutes | Yes (generation) |
| **Behavioral** | Agent follows prompt instructions correctly | Minutes | Yes (generation + judging) |

## Quick Start

```bash
# Run everything
./tests/run-all.sh

# Run only unit tests (fast, no LLM)
./tests/run-all.sh --unit

# Run only structural tests (generates artifacts + checks)
./tests/run-all.sh --structural

# Run only behavioral tests (criteria-based, LLM-as-judge)
./tests/run-all.sh --behavioral

# Structural tests using existing artifacts (skip regeneration)
./tests/run-all.sh --structural --no-generate
```

## Layer 1: Unit Tests

Deterministic bash tests for hooks and scripts. No LLM needed.

```bash
# Run all unit tests
bash tests/unit/test-phase-guard.sh
bash tests/unit/test-session-budget.sh
bash tests/unit/test-ripple-check.sh
```

**What they cover:**
- `test-phase-guard.sh` — Phase transition gates (Frame Go → Shape, Shape Go → Build, etc.)
- `test-session-budget.sh` — Session counting, appetite detection, nice-to-have/must-have tallies
- `test-ripple-check.sh` — Horizontal scope name detection, document type detection, exit codes

## Layer 2: Structural Tests

Generates build artifacts from fixtures using `claude -p`, then runs structural assertions.

```bash
# Generate artifacts for all fixtures
./tests/generate-artifacts.sh --all

# Run structural checks on generated artifacts
./tests/run-tests.sh --all
```

**Fixtures** (`fixtures/`):
- `small-single-session` — 1-day CSV export (Small Batch)
- `medium-multi-scope` — Notification preferences (Medium Batch)
- `large-multi-session` — Real-time activity feed (Big Batch)

**Assertions** (`assertions/structural-checks.sh`):
- Required files exist (orientation.md, hillchart.md, scopes/)
- Required sections present in each file
- Scope names differ from Package element names
- Hill chart has history entries
- Scope files have prioritization reasoning

**Quality Rubric** (`assertions/quality-rubric.md`):
- LLM-as-judge scoring (0-2 per criterion, 12 criteria)
- Pass threshold: 14/20 (single-session) or 16/24 (multi-session)

## Layer 3: Behavioral Tests

Tests whether agent behavior matches prompt intent using adversarial scenarios.

```bash
# Run all behavioral tests
./tests/behavioral/run-behavioral.sh --all

# Run a single scenario
./tests/behavioral/run-behavioral.sh user-raises-concern-during-build

# List available scenarios
./tests/behavioral/run-behavioral.sh --list
```

**Criteria** (`behavioral/criteria/`):
- `emergent-scope.md` — Agent captures feedback as scope tasks, never re-shapes
- `vertical-scopes.md` — Scope names are business-oriented, not technical layers
- `nice-to-have-surfacing.md` — Agent surfaces nice-to-haves before shipping
- `phase-boundaries.md` — Agent stays within its phase, redirects out-of-phase work

**Scenarios** (`behavioral/scenarios/`):
- `user-raises-concern-during-build.md` — User asks about edge case mid-build
- `scope-discovery-api-project.md` — Scope naming in backend-only project
- `must-haves-done-sessions-remain.md` — All must-haves done, budget remains
- `frame-user-proposes-solution.md` — User jumps to solution during framing

**Pipeline:** scenario → `claude -p` with skill prompt → agent response → `claude -p` with judge rubric → PASS/FAIL

**Results** saved to `behavioral/results/<scenario>.json` with full agent response and judge output.

## Architecture

```
tests/
├── run-all.sh                         ← Entry point: runs all layers
├── generate-artifacts.sh              ← Generates build artifacts via claude -p
├── run-tests.sh                       ← Existing: structural checks + quality rubric
│
├── unit/                              ← Layer 1: deterministic, no LLM
│   ├── test-phase-guard.sh
│   ├── test-session-budget.sh
│   └── test-ripple-check.sh
│
├── fixtures/                          ← Input: synthetic packages
│   ├── small-single-session/
│   ├── medium-multi-scope/
│   └── large-multi-session/
│
├── results/                           ← Output: generated artifacts (gitignored)
│
├── assertions/                        ← Structural assertion scripts + quality rubric
│   ├── structural-checks.sh
│   └── quality-rubric.md
│
└── behavioral/                        ← Layer 3: criteria-based, LLM-as-judge
    ├── run-behavioral.sh
    ├── judge-rubric.md
    ├── criteria/                      ← Pass/fail conditions per behavior
    ├── scenarios/                     ← Adversarial inputs that trigger behaviors
    └── results/                       ← Judge output (gitignored)
```

## Adding New Tests

### New unit test
Add `tests/unit/test-<name>.sh`. Follow the pass/fail/assert pattern from existing tests.

### New behavioral test
1. Add a criteria file to `tests/behavioral/criteria/<name>.md` (pass + fail conditions)
2. Add a scenario to `tests/behavioral/scenarios/<name>.md` (setup + user input + criteria ref)
3. Run: `./tests/behavioral/run-behavioral.sh <scenario-name>`

### New structural fixture
1. Add a package to `tests/fixtures/<name>/package.md`
2. Generate: `./tests/generate-artifacts.sh <name>`
3. Check: `./tests/run-tests.sh <name> --structural-only`
