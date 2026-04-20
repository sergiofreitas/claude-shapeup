# Scope: Posts Appear Live on the Mural

## Hill Position

▲ **Uphill — significant unknowns.** Backend half is downhill (Session 01). Frontend half has the DOM manipulation, dedup, and scroll-handling unknowns the Package flagged as highest complexity.

## Prioritization Reasoning

**Why first (inverted pyramid base):**

- **Carries the infrastructure cost for every other live capability.** The Stimulus controller, subscription lifecycle, and `received` dispatcher built here will be reused by comments, reactions, reconnect, and unread. Building this scope first means every subsequent scope inherits a working foundation instead of paying again.
- **Riskiest remaining work.** Handover explicitly called this out. DOM mutation against a live feed (dedup by `dom_id`, preserving scroll position, animation timing) has the most unknowns and the widest blast radius if we get it wrong. Push it uphill first so the rest of the build is downhill.
- **Validates the full vertical slice.** Channel → broadcast → wire → DOM → user sees it. Once a post appears on a second browser without refresh, we know the architecture holds. Everything else is pattern replication.
- **No dependencies on other scopes.** Comments-live depends on this; reactions-live depends on this; reconnect depends on this. Nothing depends on anything else first.

## Must-Haves

- [x] ClassroomChannel authorizes teachers, admins, and guardians (Session 01)
- [x] Post model broadcasts `new_post` event with rendered HTML after create (Session 01)
- [ ] Stimulus controller `mural_live_controller.js` created, subscribes to `ClassroomChannel` with classroom ID from data attribute
- [ ] `received(data)` dispatches on `data.type` to per-event handlers
- [ ] `handleNewPost(data)` prepends `data.html` to feed container
- [ ] Dedup: before prepending, check if a node with the same `dom_id` already exists; skip if so (covers author-sees-their-own-post-twice case)
- [ ] Scroll handling: if user is scrolled past threshold, do NOT auto-scroll; show "New post above ↑" indicator that jumps to top on click
- [ ] Slide-in animation on newly prepended post card (CSS only, no JS timing hacks)
- [ ] Data attributes added to `app/views/mural/show.html.erb` to wire the controller
- [ ] System test: two browser sessions, user A posts, user B's mural updates without refresh

## Nice-to-Haves (~)

- [ ] ~ Subtle sound/haptic on new post arrival (out of appetite, but capture)
- [ ] ~ "3 new posts" pluralization on the scroll indicator when multiple arrive before the user scrolls up

## Notes

- Scroll threshold: start with ~150px; tune during browser verification.
- The "New post above ↑" indicator markup lives in the mural view, not the controller — keep DOM structure declarative where we can.
- Dedup check runs synchronously before insertion; the author will momentarily see the Turbo form response, then the WebSocket arrival will be a no-op.
- When this scope clears the hill, the next scopes drop to low-risk pattern replication.

