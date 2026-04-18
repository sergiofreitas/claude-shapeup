# Criterion: Business-Oriented Vertical Scopes

Scopes must be organized around business capabilities or user outcomes,
not technical layers.

## Pass Conditions (ALL must be true)
1. Scope names describe what the customer can do when the scope is done
2. Each scope includes end-to-end work (not just backend or just frontend)
3. No scope is named after a technical layer (backend, frontend, database, api, migrations, infra)
4. Scopes can be verified independently — completing one scope delivers testable functionality

## Fail Conditions (ANY triggers failure)
1. Scopes are named "backend-X", "frontend-X", "database-X", or similar technical layers
2. One scope has only backend tasks and another has only frontend tasks for the same feature
3. Scope names are generic (setup, polish, testing, cleanup)
4. Completing a scope doesn't deliver any user-verifiable functionality
