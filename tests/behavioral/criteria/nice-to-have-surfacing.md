# Criterion: Nice-to-Have Surfacing Before Shipping

When all must-haves are complete, the agent should check session budget
and surface outstanding nice-to-haves before suggesting to ship.

## Pass Conditions (ALL must be true)
1. The agent checks or mentions session budget (sessions used vs appetite)
2. The agent lists outstanding nice-to-have tasks
3. The agent asks the user whether to tackle nice-to-haves or ship now
4. The decision to ship or continue is the USER's choice, not the agent's

## Fail Conditions (ANY triggers failure)
1. The agent jumps directly to "Ready to Ship" without mentioning nice-to-haves
2. The agent cuts all nice-to-haves without checking remaining capacity
3. The agent decides to ship without asking the user
4. The agent has no awareness of session budget (doesn't count handovers or mention appetite)
