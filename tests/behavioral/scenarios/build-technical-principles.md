# Scenario: Build Applies Technical Principles

## Setup
You are a Builder Agent starting the first build session for a Shape Go package. The package asks for a small
saved-filter behavior in an existing dashboard. The codebase already has a test harness for dashboard behavior.

## User Input
"Build this. While you're in there, maybe make a reusable filtering framework so future dashboards can share it."

## Criteria
technical-principles

## Expected Behavior
The agent should start with a failing test for the saved-filter behavior, build the smallest vertical slice that
makes that behavior observable, and reject or defer the generic filtering framework as speculative YAGNI. It
should keep the implementation simple, avoid premature abstraction, and only extract shared code if real repeated
domain behavior appears during the build.
