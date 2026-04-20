# Handover — Session 01

**Date**: 2026-02-16
**Feature**: T03 — Real-Time Classroom Activity Feed

## Completed This Session
- **Channel Authorization**: ClassroomChannel created with authorization for all 3 user types. Tests passing.
- **Event Broadcasting (Posts only)**: Post model broadcasts after_create_commit. Renders partial server-side. Tests passing.

## Current Hill Chart

### Session 01 — 2026-02-16
  ✓ Channel Authorization — Done (channel created, auth tested for teacher/admin/guardian)
  ▼ Event Broadcasting — Downhill (posts work, comments and reactions not yet wired)
  ▲ Mural Live Controller — Uphill (Stimulus controller scaffolded, subscription connects, but DOM handling not started)
  ▲ Connection Resilience — Uphill (not started, depends on live controller being functional)
  ▲ Read Tracking Integration — Uphill (not started, depends on live controller)

## Next Session Should
1. **Mural Live Controller** — This is the riskiest scope. The DOM manipulation (prepend posts, update counts, dedup, scroll handling) has the most unknowns. Push it uphill first.
2. **Event Broadcasting (Comments + Reactions)** — Extend the working post broadcasting to comments and reactions. Low risk since the pattern is established.
3. **Connection Resilience** — Can only be validated after the live controller handles events.

## Known Unknowns
- How to handle scroll position when prepending new posts (auto-scroll vs indicator)
- Whether existing Turbo Stream comment creation conflicts with WebSocket insertion
- How to structure the "catch up on missed events" refresh on reconnect

## Scope Hammering Decisions Made
- Read Tracking Integration marked as nice-to-have (~) — the existing unread glow from page load still works. Real-time unread tracking is polish, not core.

## Code Changes
- `app/channels/classroom_channel.rb` — new file
- `app/channels/application_cable/connection.rb` — added `identified_by :current_user`
- `app/models/post.rb` — added `after_create_commit :broadcast_to_classroom`
- `test/channels/classroom_channel_test.rb` — new file
- `test/models/post_broadcast_test.rb` — new file
