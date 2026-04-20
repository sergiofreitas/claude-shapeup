
# Scope: Urgent Messages Always Break Through

## Hill Position

▲ Uphill — basic bypass lands in the first scope via TDD, but exhaustive coverage of every edge case hasn't been written. The unknown here is not "how" but "are we sure we covered every path."

## Prioritization Reasoning

**Second scope. The safety guarantee gets its own scope for visibility.** Even though the core urgent-bypass lives in the first scope's filter (you can't write the filter without it), the cost of a missed urgent message is high enough that we want explicit, exhaustive test coverage as a dedicated unit of work — not a handful of assertions buried in the main filter test.

This also serves as a forcing function: if a future change to the delivery pipeline breaks urgent bypass, we want a loud, obvious failure in a named test suite, not a subtle miss in an integration test labeled "silence classroom post types."

We do this second (not first) because the filter must exist before we can prove it short-circuits. And we do it before UI work because the safety property is more important than the matrix layout.

## Must-Haves

- [ ] Test: urgent bypass works when guardian has muted the specific (classroom, urgent) combo (attempted — shouldn't even be possible to create, but verify defense-in-depth)
- [ ] Test: urgent bypass works when guardian has muted every non-urgent type in the classroom
- [ ] Test: urgent bypass works when guardian has muted every classroom they're in
- [ ] Test: urgent bypass works when the `notification_preferences` table is empty
- [ ] Test: the toggle endpoint refuses to create a preference row with `post_type == 'urgent'` (server-side enforcement, not just UI)
- [ ] UI: urgent column in the preferences matrix renders a disabled toggle with a tooltip / helper text explaining why
- [ ] Manual smoke test: fire a synthetic urgent notification against a test guardian with maximum muting, confirm it arrives

## Nice-to-Haves

- [ ] ~ Observability: log a counter when the urgent bypass fires, so we can spot regressions in production metrics

## Notes

- The bypass is ALREADY implemented in scope-silence-classroom-post-types — this scope is about hardening, not building.
- If the toggle endpoint currently accepts `post_type=urgent`, that's a bug — fix here.
- The disabled-toggle UI treatment also lives here since it's semantically about the urgent guarantee, not the matrix layout.

