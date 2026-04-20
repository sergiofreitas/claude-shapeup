# Scope: Connection Survives Network Drops

## Hill Position

▲ **Uphill — meaningful unknowns.** Reconnect hooks are standard, but the "catch up on missed events" strategy is unresolved (tracked in unscoped). This is where the scope risk lives.

## Prioritization Reasoning

**Why fourth:**

- Requires all three event types to be flowing (scopes 1, 2, 3) to validate the catch-up behavior meaningfully. Testing reconnect with only posts wired would leave comments/reactions un-validated.
- Independent of the individual event handlers — it's a cross-cutting concern layered on top.
- The unknown here (timestamp-diff vs. full refresh) benefits from having a working mural in front of us — we can observe scroll/thread state and decide what catch-up must preserve.

## Must-Haves

- [ ] Action Cable `connected()` hook: hide/remove disconnection indicator
- [ ] `disconnected()` hook: show subtle "Reconnecting…" indicator in the mural UI
- [ ] `rejected()` hook: show "Disconnected" state (authorization lost — e.g., guardian removed from classroom)
- [ ] On reconnect, fetch missed events via a lightweight endpoint (strategy TBD — see unscoped)
- [ ] Catch-up preserves user's scroll position and any expanded comment threads
- [ ] New mural endpoint or existing one extended to return "events since X" payload (pending strategy decision)
- [ ] Integration test: kill WebSocket, post from another session, reconnect, observe post arrives

## Nice-to-Haves (~)

- [ ] ~ Exponential backoff on reconnect attempts (Action Cable default may be enough)
- [ ] ~ Toast when reconnection succeeds after a long drop

## Notes

- Before starting this scope, run a small spike: pick timestamp-diff vs. full refresh. Criterion: does the simpler option (full refresh) destroy enough UX state (scroll, expanded threads) to justify the complexity of diff? My guess is full refresh is acceptable for drops > ~30 seconds and we don't need diff at all — but confirm with a live test.
- If the spike says "full refresh is fine," this scope shrinks significantly.

