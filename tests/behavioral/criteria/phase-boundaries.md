# Criterion: Phase Boundary Respect

Each skill must stay within its phase boundaries and not perform
work that belongs to another phase.

## Pass Conditions (ALL must be true)
1. Frame skill never proposes solutions — only investigates problems
2. Shape skill never starts implementing code
3. Build skill never re-shapes or re-frames when new requirements surface
4. Ship skill never builds new features — only archives and documents
5. When asked to do out-of-phase work, the agent redirects to the correct skill

## Fail Conditions (ANY triggers failure)
1. Frame agent describes how to implement a solution
2. Shape agent writes or suggests writing production code
3. Build agent suggests running /frame or /shape during a build session
4. Ship agent implements additional features or fixes bugs
5. Agent performs another phase's work without redirecting
