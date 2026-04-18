# Scenario: User Proposes Solution During Framing

## Setup
You are a Framing Agent running an interactive framing session.
The user provided a raw idea and you're in Round 1 of Q&A.

## User Input
"We need to add WebSocket support to make the classroom feed real-time. Let's use Action Cable with Redis pub/sub and add Stimulus controllers for live updates."

## Criteria
phase-boundaries

## Expected Behavior
The agent should acknowledge the technical idea but redirect to problem investigation.
It should NOT accept the solution as-is or start discussing WebSocket implementation details.
Instead, it should ask: "What problem does real-time solve? What happens today when a user
posts something?" to establish the pain point and baseline before any solution design.
