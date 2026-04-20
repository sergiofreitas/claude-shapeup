# Package: Real-Time Classroom Activity Feed

**Feature ID**: T03
**Created**: 2026-02-16
**Status**: Shape Go

---

## Problem

When a teacher posts an announcement, uploads photos, or a parent comments on a post, other users don't see updates until they manually refresh the page. The mural — the main classroom view — is a static HTML page that only updates on full page load.

This creates two problems:
1. **Teachers don't see engagement**: After posting, a teacher has no way to know if parents are reading and responding without constantly refreshing.
2. **Parents miss live conversations**: Comment threads feel dead because you can't see others typing or new replies appearing.

The workaround today: users refresh the page manually or rely on push notifications to know when to return. This breaks the "classroom community" feeling the product aims for.

## Appetite

**Big Batch: 2 weeks**

## Requirements (R)

| ID | Requirement | Status |
|----|-------------|--------|
| R0 | New posts, comments, and reactions appear on the mural without page refresh | Core goal |
| R1 | Real-time delivery via WebSocket connection (Action Cable) | Must-have |
| R2 | Events are scoped to the classroom — users only receive updates for classrooms they belong to | Must-have |
| R3 | New post notification: card slides in at the top of the mural feed | Must-have |
| R4 | New comment notification: comment count badge updates, comment appears if thread is open | Must-have |
| R5 | Reaction updates: reaction counts update in real-time | Must-have |
| R6 | Connection resilience: reconnects automatically after network interruptions | Must-have |
| R7 | Read tracking: new items are marked as unread until scrolled into view | Must-have |
| R8 | Typing indicators (who is writing a comment) | Out |
| R9 | Presence indicators (who is online) | Out |
| R10 | Real-time for teacher/admin dashboards | Out |

## Solution

Use Action Cable (already in the Rails stack but unused) to broadcast classroom events over WebSocket channels. A Stimulus controller on the mural page subscribes to the classroom channel and updates the DOM when events arrive. Server-side callbacks in Post, Comment, and Reaction models broadcast after creation.

### Element: Action Cable Channel

**What**: A `ClassroomChannel` that accepts subscriptions scoped to a classroom. Authorizes that the subscriber belongs to the classroom (teacher, admin, or guardian with a child in the classroom).
**Where**: `app/channels/classroom_channel.rb` (new file)
**Wiring**: `subscribed` method verifies membership via `ClassroomMembership` or `Guardianship` chain. Streams from `"classroom_#{params[:classroom_id]}"`. `unsubscribed` stops the stream.
**Affected code**: New channel file, `app/channels/application_cable/connection.rb` (add `identified_by :current_user` if not present)
**Complexity**: Medium — authorization logic must handle three user types (teacher, admin, guardian)

### Element: Event Broadcasting

**What**: After creating a post, comment, or reaction, broadcast the event to the classroom channel.
**Where**: `app/models/post.rb`, `app/models/comment.rb`, `app/models/reaction.rb` — `after_create_commit` callbacks
**Wiring**: Each callback calls `ClassroomChannel.broadcast_to(classroom, { type: "new_post"|"new_comment"|"new_reaction", data: serialized_payload })`. Payload includes rendered HTML partial for the new item.
**Affected code**: Three model files (add callbacks), new serialization concern or helper
**Complexity**: Medium — rendering partials inside model callbacks requires care (use `ApplicationController.render`)

### Element: Mural Subscription Controller

**What**: A Stimulus controller (`mural_live_controller`) that creates an Action Cable subscription when the mural page loads. Handles incoming events by updating the DOM.
**Where**: `app/javascript/controllers/mural_live_controller.js` (new file)
**Wiring**: On `connect()`, creates Action Cable subscription for the current classroom (classroom ID from data attribute). `received(data)` method dispatches to handlers: `handleNewPost` (prepend card to feed), `handleNewComment` (update badge, append if thread open), `handleNewReaction` (update count).
**Affected code**: New Stimulus controller, `app/views/mural/show.html.erb` (add data attributes for controller)
**Complexity**: High — DOM manipulation must handle edge cases (duplicate detection, scroll position preservation, animation)

### Element: New Post Card Insertion

**What**: When a "new_post" event arrives, prepend the rendered post card HTML to the mural feed container. Animate the insertion (slide-in from top). If the user has scrolled down, show a "New post above ↑" indicator instead of auto-scrolling.
**Where**: Handler inside `mural_live_controller.js`, CSS animation in `application.css`
**Wiring**: `handleNewPost(data)` — check if the post already exists in DOM (dedup by `dom_id`). If not, prepend `data.html` to the feed container. If user has scrolled past threshold, show floating indicator.
**Affected code**: Stimulus controller, CSS, possibly mural view for indicator markup
**Complexity**: Medium

### Element: Comment Live Update

**What**: When a "new_comment" event arrives: (1) update the comment count badge on the post card, (2) if the comment thread for that post is currently open/expanded, append the new comment HTML.
**Where**: Handler inside `mural_live_controller.js`
**Wiring**: `handleNewComment(data)` — find the post card by `dom_id(post)`. Update the comment count element. Check if the comment section is expanded (data attribute or DOM state). If yes, append `data.html` to the comments container.
**Affected code**: Stimulus controller, post card partial (ensure comment count has a targetable element)
**Complexity**: Medium — must coordinate with existing comment Turbo Stream behavior

### Element: Reaction Count Update

**What**: When a "new_reaction" event arrives, update the reaction count display on the relevant post card.
**Where**: Handler inside `mural_live_controller.js`
**Wiring**: `handleNewReaction(data)` — find the post card, find the reaction count element, update the count and emoji display.
**Affected code**: Stimulus controller, post card partial (ensure reaction count has a targetable element)
**Complexity**: Low

### Element: Connection Resilience

**What**: Handle WebSocket disconnection and reconnection gracefully. Show a subtle connection status indicator. On reconnect, fetch missed events or refresh stale data.
**Where**: `mural_live_controller.js` (connection lifecycle hooks)
**Wiring**: Action Cable provides `connected()`, `disconnected()`, `rejected()` callbacks. On disconnect, show "Reconnecting..." indicator. On reconnect, fetch the latest mural state via a lightweight AJAX request to avoid missing events during downtime.
**Affected code**: Stimulus controller, mural view (connection indicator markup)
**Complexity**: Medium — the "catch up on missed events" logic needs careful design

### Element: Read Tracking Integration

**What**: New items arriving via WebSocket should be marked as "unread" with visual styling (orange glow, consistent with existing unread post styling). Mark as read when scrolled into the viewport using Intersection Observer.
**Where**: `mural_live_controller.js` and existing read tracking logic
**Wiring**: New posts/comments inserted via WebSocket get an `unread` CSS class. An Intersection Observer watches for these elements entering the viewport. On intersection, fire a PATCH request to mark as read (existing endpoint). Remove `unread` class.
**Affected code**: Stimulus controller, CSS, existing read tracking endpoint
**Complexity**: Medium — Intersection Observer setup and coordination with existing read tracking

## Rabbit Holes

- **Action Cable in production**: The app runs on a standard Rails setup. Action Cable uses the async adapter in development and should use Redis in production. Check if Redis is available. **Patched** — Heroku Redis addon is already provisioned for Sidekiq. Action Cable can share the same Redis instance with a different channel prefix.
- **Rendering partials in model callbacks**: `after_create_commit` runs outside the request cycle. Use `ApplicationController.render(partial: ..., locals: ...)` to render HTML. This is a known Rails pattern. **Patched**.
- **Duplicate messages**: If a user creates a post, they see it via the form redirect AND via the WebSocket broadcast. The Stimulus controller must dedup by checking `dom_id` before inserting. **Patched**.
- **Mobile battery/bandwidth**: WebSocket connections consume battery. Action Cable's built-in heartbeat (every 3 seconds) keeps connections alive. For mobile, this is acceptable — WhatsApp and similar apps maintain persistent connections. **Patched** — no special mobile handling needed.
- **Authorization on reconnect**: When Action Cable reconnects, it re-runs `subscribed`. The authorization check runs again. If a guardian has been removed from a classroom between disconnection and reconnection, the subscription will be rejected. **Patched** — correct behavior.
- **Turbo Stream conflict**: The existing comment system uses Turbo Streams for create/update. WebSocket-based comment insertion must not conflict. When a user creates a comment, they get the Turbo Stream response. Other users get the WebSocket broadcast. The dedup check prevents doubles. **Patched**.

## No-Gos

- No typing indicators — too complex for this appetite, real-time updates are sufficient
- No presence indicators — "who is online" is a separate feature
- No real-time for dashboards — mural only
- No real-time for the comments page (separate from mural) — mural view only
- No custom WebSocket infrastructure — use Action Cable only
- No event persistence/replay — if a user was offline, they see updates on next page load (existing behavior). The "catch up" on reconnect is a lightweight refresh, not an event log.

## Technical Validation

**Codebase reviewed:**
- `Gemfile` — `actioncable` is included (part of Rails 7)
- `config/cable.yml` — exists with async adapter for development
- `app/channels/` — directory exists but is empty (no channels yet)
- `app/javascript/controllers/` — Stimulus controller infrastructure in place
- `app/views/mural/show.html.erb` — feed container identifiable, post cards have `dom_id`
- `app/views/mural/_post_card.html.erb` — comment count and reaction count elements exist
- `app/models/post.rb` — no `after_create_commit` callbacks yet
- `app/models/comment.rb` — has `after_create_commit` for existing Turbo Stream
- `app/services/notification_service.rb` — existing notification pipeline (separate from real-time)
- `config/environments/production.rb` — Action Cable not yet configured for production

**Approach validated**: Action Cable is already in the stack, Redis is available, Stimulus controller infrastructure is in place. The main risk is the Stimulus controller complexity (DOM manipulation, dedup, scroll handling, reconnection). This is the scope that needs to go uphill first.

**Test strategy**: TDD — channel authorization tests, model callback tests (broadcast called), Stimulus controller tests (if infrastructure supports), integration tests for end-to-end flow, system tests for visual verification.
