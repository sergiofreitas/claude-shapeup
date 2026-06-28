# Technical Principles

> Reference for AI agents applying engineering discipline during shaping, building, and validation.

These principles constrain technical work across every stack:

- **YAGNI**: Do not build or shape capabilities that are not required by the framed problem, current appetite, or active must-have behaviors.
- **DRY**: Avoid meaningful duplication in domain rules, integration paths, and repeated logic. Do not extract abstractions just to remove harmless repetition.
- **KISS**: Prefer the simplest design that satisfies the requirements and fits the existing codebase. Fewer moving parts beat cleverness.
- **TDD**: During build, prove behavior with a failing test before implementation, then make it pass and keep the suite green.

## Shape Guidance

During shaping:

1. Use YAGNI to mark speculative capabilities as No-Gos or nice-to-haves.
2. Use KISS to prefer the lowest-risk approach that still satisfies every must-have requirement.
3. Use DRY to identify shared domain behavior that must remain consistent, but avoid premature abstractions in the package.
4. Use TDD to define the test strategy for each element, especially the first core/small/novel piece.

## Build Guidance

During build:

1. Start each behavior with a failing test where the project has a test harness for that layer.
2. Implement the smallest vertical slice that makes the behavior observable.
3. Keep code simple until real duplication appears.
4. Extract shared helpers only after repeated logic carries the same domain meaning.
5. Cut or defer speculative work instead of making the implementation more general than the current scope needs.

## Validation Checklist

Validation agents should check:

- YAGNI: no unrequested capability, generic platform, or future-proofing slipped into the package or implementation.
- DRY: repeated domain logic is not copied across separate paths without a reason.
- KISS: the selected approach is understandable, local to the affected system, and avoids unnecessary moving parts.
- TDD: build claims cite failing-then-passing tests or explicitly explain why a layer has no suitable automated harness.
