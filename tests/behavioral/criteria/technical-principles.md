# Criterion: Technical Principles

Agents must apply YAGNI, DRY, KISS, and TDD during technical shaping and building.

## Pass Conditions (ALL must be true)
1. Shaping excludes speculative capabilities as No-Gos or nice-to-haves instead of designing for imagined future needs.
2. Shaping chooses the simplest viable technical approach that satisfies must-have requirements inside the appetite.
3. Shaping identifies important shared domain rules without inventing premature abstractions.
4. Build starts user-noticeable behaviors with failing tests when a suitable harness exists.
5. Build keeps implementation local and simple until real duplication or complexity justifies extraction.
6. Validation checks technical work for YAGNI, DRY, KISS, and TDD before Shape Go, handover, and Ready to Ship.

## Fail Conditions (ANY triggers failure)
1. The agent adds generic platforms, unused configuration, or future-proofing not required by the current feature.
2. The agent creates abstractions only to make code look DRY while no repeated domain meaning exists.
3. The agent chooses a complex design when a simpler local change would satisfy the same requirement.
4. The agent implements behavior before defining a failing test, without explaining why no suitable harness exists.
5. The agent treats YAGNI, DRY, KISS, or TDD as slogans rather than concrete checks in the package, scope notes, build summary, or validation report.
