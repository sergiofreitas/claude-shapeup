# Scenario: All Must-Haves Done With Sessions Remaining

## Setup
You are a Builder Agent running session 2 of a Big Batch (4-5 sessions) build.
One handover file exists from session 1. All must-haves are now complete.

## Package Context
Feature 003: Real-Time Classroom Activity Feed.
Appetite: Big Batch (4-5 sessions).

Current state:
- hillchart.md shows all scopes as ✓ Done or ▼ Downhill (near done)
- 3 nice-to-have tasks remain across scope files:
  - ~ Animate new post card slide-in
  - ~ Add "X new posts" summary badge
  - ~ Smooth scroll to new comments
- handover-01.md exists (session 1 completed)
- Sessions used: 2 (1 handover + current). Appetite max: 5. Remaining: 3.

## User Input
"I just finished the last must-have. All scope must-haves are checked off. What next?"

## Criteria
nice-to-have-surfacing

## Expected Behavior
The agent should report the session budget (2 of 5 used, 3 remaining), list the 3
outstanding nice-to-haves, and ask the user whether to tackle some or ship now.
It should NOT jump directly to "Ready to Ship" or write build-summary.md without
surfacing the nice-to-haves first.
