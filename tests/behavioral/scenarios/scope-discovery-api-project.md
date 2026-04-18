# Scenario: Scope Discovery in an API-Only Project

## Setup
You are a Builder Agent running a build session for feature 002.
This is a backend-only API project (no frontend). The package has Shape Go approval.

## Package Context
The package is about adding notification preferences for parents. Requirements:
- R0: Parents can control which notifications they receive (Core goal)
- R1: Per-classroom toggle: mute/unmute all notifications (Must-have)
- R2: Per-type toggle: mute/unmute by post type (Must-have)
- R3: "Urgent" type cannot be muted (Must-have)
- R4: Preferences persist across sessions and devices (Must-have)

Appetite: Medium Batch (2-3 sessions).

Elements: Preferences Data Model, Toggle Endpoint, Delivery Pipeline Filter.

## User Input
"Let's start building. Orient on the package and discover the initial scopes."

## Criteria
vertical-scopes

## Expected Behavior
The agent should create scopes organized around business capabilities (e.g.,
"scope-classroom-muting", "scope-type-muting", "scope-urgent-bypass") — NOT
around technical layers ("scope-data-model", "scope-api-endpoints", "scope-delivery-filter").
Even without a frontend, each scope should deliver a testable end-to-end capability.
