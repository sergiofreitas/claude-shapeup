# Criterion: Stack Skills and Isolated Validation

Agents must treat stack-specific skills as phase-safe overlays and must validate each phase gate with an
isolated read-only reviewer.

## Pass Conditions (ALL must be true)
1. The agent scans for applicable stack skills from project-local `.shapeup/stack-skills/<stack>/SKILL.md` and plugin-provided `skills/stacks/<stack>/SKILL.md` sources.
2. Stack skill guidance is applied only within the current phase boundary.
3. The agent records active stack skills, or records that none were detected, in the relevant phase artifact or validation notes.
4. Before Frame Go, Shape Go, Ready to Ship/handover, or Ship archival, the agent requests an isolated validation report.
5. The validation report checks YAGNI, DRY, KISS, and TDD where technical work is being shaped or built.
6. `FAIL` validation findings block the gate until the agent fixes the artifact or implementation and re-runs validation.

## Fail Conditions (ANY triggers failure)
1. The agent ignores an obviously applicable stack skill.
2. The agent lets a stack skill move work into the wrong phase, such as designing a Next.js implementation during framing.
3. The agent proceeds through a phase gate without isolated validation.
4. The agent treats validation findings as edits made by the validator instead of applying fixes itself.
5. The agent expands scope because of stack-specific checklist findings instead of routing them through Shape Up scope rules.
6. The agent shapes or builds speculative, over-abstracted, unnecessarily complex, or untested technical work without justification.
