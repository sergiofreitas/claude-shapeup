# Shape Up Skills for Claude Code

Four Claude Code skills that teach your AI agent the [Shape Up](https://basecamp.com/shapeup) methodology. Fixed time, variable scope, zero hand-waving.

**Frame** the problem. **Shape** the solution. **Build** the code. **Ship** the knowledge.

## Why?

Backlogs are where ideas go to die. Shape Up replaces the infinite todo list with a simple bet: pick a time budget, shape the work to fit, build it, ship it. This project gives Claude Code the vocabulary and guardrails to run that process with you — interactively, one feature at a time.

## The Skills

| Skill | What it does | Gate |
|-------|-------------|------|
| `/shapeup:frame` | Turns a vague idea into a locked problem statement with appetite | Frame Go |
| `/shapeup:shape` | Deep codebase analysis → requirements, affordance tables, fit check matrix, Package | Shape Go |
| `/shapeup:build` | TDD, hill charts, scope hammering, handovers for multi-session work | Ready to Ship |
| `/shapeup:ship` | Extracts ADRs, updates architecture docs, archives the feature folder | Done |

Each skill is self-contained with its own reference docs — no external dependencies, no magic.

## Quick Start

In Claude Code, run:

```
/plugin marketplace add tiago-peixoto/claude-shapeup
/plugin install shapeup
```

Type `/shapeup:frame` and follow the conversation.

## What Happens at Runtime

```
.shapeup/
├── 2026-04-20-csv-import-framing/       # Active: being framed
│   └── frame.md
├── 2026-04-18-auth-refresh-shaped/      # Ready: waiting for a build bet
│   ├── frame.md
│   └── package.md
├── 2026-04-15-dashboard-v2-building/    # In progress
│   ├── frame.md
│   ├── package.md
│   ├── hillchart.md
│   ├── scopes/
│   └── handover-01.md
├── 2026-04-10-search-shipped/           # Done: decisions archived
└── index.md                             # Auto-generated dashboard
```

Multiple features can run in parallel. Each folder is a date-slug key — `YYYY-MM-DD-<slug>` —
with a status suffix (`-framing`, `-shaped`, `-building`, `-shipped`, `-discarded`). Date-slug
keys are **collision-free across teammates**: two developers can frame features on separate
branches without colliding on a shared counter. If two teammates pick the same slug on the
same day, the second folder gets a 4-hex disambiguator (`2026-04-20-csv-import-bc89-framing`).

Invoke downstream skills with any of these key forms:

- Full date-slug: `/shapeup:build 2026-04-20-csv-import`
- Short slug: `/shapeup:build csv-import` (works when the slug is unique across the project)
- Legacy numeric: `/shapeup:build 001` (back-compat for features created before date-slug)

## Hooks

The plugin installs two hooks:

- **`phase-guard.sh`** (UserPromptSubmit) — blocks `/shape`, `/build`, `/ship` when gates
  haven't been passed. Resolves any accepted key form to the correct feature folder and
  verifies Frame Go / Shape Go / `build-summary.md` exists.
- **`ripple-check.sh`** (PostToolUse) — watches `.shapeup/**/*.md` edits and nudges the
  agent when a change to one document likely affects another. Advisory only.

## Verification Scripts

Two shared scripts back the "trust but verify" pattern that shape/build/ship use:

- **`hooks/lib/resolve-feature.sh`** — accepts any key form, returns the feature folder path.
- **`hooks/lib/check-consistency.sh`** — audits a feature folder for drift between scope
  checkboxes, hill chart symbols, and the pre-ship gate. Skills call it before marking a
  scope done and as the gate into `/ship`; FAILs must be resolved, not silenced.

## Project Structure

```
.claude-plugin/
├── plugin.json
└── marketplace.json
hooks/
├── hooks.json
├── phase-guard.sh
├── ripple-check.sh
└── lib/
    ├── resolve-feature.sh
    └── check-consistency.sh
skills/
├── frame/
│   ├── SKILL.md
│   ├── scripts/init-feature.sh
│   └── references/              # 9 methodology docs per skill
├── shape/
│   ├── SKILL.md
│   ├── scripts/validate-package.sh
│   └── references/
├── build/
│   ├── SKILL.md
│   ├── scripts/update-hillchart.sh
│   └── references/
└── ship/
    ├── SKILL.md
    ├── scripts/regenerate-index.sh
    └── references/
```

## Acknowledgments

This project exists because of [Ryan Singer](https://www.ryansinger.co/)'s work.

The **[Shape Up book](https://basecamp.com/shapeup)** is the foundation — written by Ryan and published by 37signals. It's free to read online and you should read it before using these skills. We distilled it; we didn't replace it.

Two of Ryan's articles pushed the methodology further and directly shaped these skills. **[Framing](https://www.ryansinger.co/framing/)** introduced a formal step before shaping — lock the problem before you design solutions — which became our `/shapeup:frame` skill and the Frame Go gate. It also renamed "Pitch" to "Package," and we followed suit. **[Pitfalls When Adopting Shape Up](https://www.ryansinger.co/pitfalls-when-adopting-shape-up/)** identified undershaped work as the #1 failure mode, which is why `/shapeup:shape` obsesses over actual codebase analysis and enforces zero TBDs.

Ryan's own **[shaping-skills](https://github.com/rjs/shaping-skills)** repo for Claude Code was a direct inspiration. We absorbed several of his ideas: formal requirement notation (R0, R1...), fit check matrices, affordance tables with wiring, flagged unknowns, and time-boxed spikes for resolving them. If you want a different take on AI-assisted shaping, check his repo out.

## License

MIT

## Contributing

Fork it, break it, make it yours. Each skill's `references/` directory is self-contained — swap in your own methodology docs, add domain-specific references, or build new skills for phases we skipped (a `/shapeup:bet` skill for the betting table, anyone?).

**Before editing a SKILL.md or a hook, read [CLAUDE.md](./CLAUDE.md) and [CONTRIBUTING.md](./CONTRIBUTING.md).** CLAUDE.md is auto-loaded by every Claude Code session and states the hard rules; CONTRIBUTING.md covers the three-layer test suite (unit / structural-snapshot / behavioral) and the prompt-change workflow (`tests/diff-against-baseline.sh`) that keeps prompt edits from silently drifting the generated artifacts.

After cloning, run `bash scripts/setup-hooks.sh` once to activate the tracked git hooks that enforce the workflow on every commit.
