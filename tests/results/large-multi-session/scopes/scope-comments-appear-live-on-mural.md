# Scope: Comments Appear Live on the Mural

## Hill Position

▲ **Uphill — moderate unknowns.** Pattern is established by the posts scope, but coordination with the existing Turbo Stream comment path is the open question.

## Prioritization Reasoning

**Why second:**

- Can only begin once the Stimulus controller + subscription + dispatcher exist (built in `scope-posts-appear-live-on-mural`).
- Higher risk than reactions because of the Turbo Stream conflict surface — the author creates a comment and receives a Turbo Stream response; other users receive a WebSocket broadcast. Dedup logic must handle both paths without flicker.
- Two UI changes per event (badge increment + conditional thread append) — more surface than reactions.
- Sequence it before reactions so we pay the "second vertical" cost — proving the controller extends cleanly — while risk is still meaningful. Reactions become trivial after this.

## Must-Haves

- [ ] Comment model `after_create_commit :broadcast_to_classroom` that broadcasts `new_comment` event with rendered HTML + parent post dom_id
- [ ] Broadcast runs *alongside* existing Turbo Stream callback without conflict (verify with existing comment tests still green)
- [ ] `handleNewComment(data)` in Stimulus controller: locate parent post card by `dom_id`
- [ ] Update the comment count badge element on the parent post card
- [ ] If the comment thread under that post is currently expanded, append the new comment HTML to the thread container
- [ ] If the thread is collapsed, do not append — just bump the badge
- [ ] Dedup: if a node with the new comment's `dom_id` is already in the thread (author's own comment via Turbo Stream), skip append; still update badge only if not already counted
- [ ] Channel broadcast test for Comment model
- [ ] System test: user A comments, user B sees badge update; user B expands thread, sees comment
- [ ] Existing Turbo Stream comment tests still pass

## Nice-to-Haves (~)

- [ ] ~ Animate badge increment (subtle pulse)
- [ ] ~ Inline preview of the latest comment under the collapsed thread

## Notes

- The Turbo Stream coordination is the spot to watch. Plan to have two browsers open during implementation — one as author (Turbo Stream path), one as observer (WebSocket path).
- Badge element must have a stable target. Check the post card partial early; if it doesn't, that's a small markup change.
- If dedup gets hairy, consider having the server *not* broadcast to the author's own session (identify via `current_user` in the channel), but treat that as an optimization only if the dedup approach fails.

