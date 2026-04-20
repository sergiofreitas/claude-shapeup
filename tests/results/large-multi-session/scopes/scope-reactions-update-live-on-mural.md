# Scope: Reactions Update Live on the Mural

## Hill Position

▲ **Uphill — low unknowns.** Essentially a repeat of the post/comment pattern with the simplest UI surface. Listed uphill only because no code is written yet.

## Prioritization Reasoning

**Why third:**

- Depends on the Stimulus controller infrastructure (scope 1) and validates the dispatch pattern a third time.
- Lowest-risk capability in the build: one DOM element, one count update, idempotent at the model level (no dedup concern — a reaction either exists or it doesn't; the broadcast is a state-of-the-world update).
- Placing it after comments means the more complex coordination work (Turbo Streams, thread state) is already behind us. This scope becomes a confidence-builder.
- Doing it before Connection Resilience means the full set of live events is wired, so reconnect/catch-up has a complete target to validate against.

## Must-Haves

- [ ] Reaction model `after_create_commit :broadcast_to_classroom` that broadcasts `new_reaction` event with post dom_id + updated reaction summary payload
- [ ] `handleNewReaction(data)` in Stimulus controller: locate parent post card, update count display and emoji row
- [ ] Targetable elements confirmed on `_post_card.html.erb` (count span, emoji container) — add `data-mural-live-target` attributes if missing
- [ ] Channel broadcast test for Reaction model
- [ ] System test: user A reacts, user B's reaction count updates without refresh

## Nice-to-Haves (~)

- [ ] ~ Brief scale animation on count change
- [ ] ~ Handle reaction *removal* event (out of appetite unless cheap)

## Notes

- Because reactions are state-of-the-world, the broadcast payload should include the *full* current reaction summary, not a delta. That sidesteps race conditions if events arrive out of order.
- If the payload grows (many reaction types), revisit — but for current emoji set it's trivial.

