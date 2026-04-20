# Orientation — T03 Real-Time Classroom Activity Feed (Session 02)

## Problem Restated

The mural is the "living room" of the classroom community, but today it behaves like a printed bulletin — you only see what's new when you walk up to it again (page refresh). Teachers can't feel engagement after posting; parents can't feel a conversation forming. We want the mural to update itself as new posts, comments, and reactions arrive, while staying scoped to classrooms the viewer actually belongs to. Keep it narrow: mural view only, no typing/presence, no dashboards.

## Codebase Observations (What I Expect to Find)

Based on the package's technical validation plus Session 01's work:

- `app/channels/classroom_channel.rb` — already created, authorization works for teacher/admin/guardian (Session 01).
- `app/channels/application_cable/connection.rb` — already has `identified_by :current_user` (Session 01).
- `app/models/post.rb` — `after_create_commit :broadcast_to_classroom` exists, renders the post partial server-side (Session 01).
- `app/models/comment.rb` — has an existing `after_create_commit` for Turbo Streams. Will need a second callback for channel broadcast (conflict risk).
- `app/models/reaction.rb` — no callbacks yet.
- `app/views/mural/show.html.erb` — feed container with `dom_id`; need to add `data-controller="mural-live"` + `data-mural-live-classroom-id-value`.
- `app/views/mural/_post_card.html.erb` — post has `dom_id`, comment count and reaction count are targetable.
- `app/javascript/controllers/` — standard Stimulus setup. Controller file does not yet exist.
- `config/cable.yml` — async in dev; production needs Redis wired (Heroku Redis already provisioned for Sidekiq, different prefix).
- No existing JS dedup/scroll-handling helpers — we build from scratch.
- `test/channels/classroom_channel_test.rb` and `test/models/post_broadcast_test.rb` exist; pattern established.

## Imagined vs. Discovered

Tensions between what the Package imagined and what Session 01 + the live codebase suggest:

1. **"Mural Live Controller" was imagined as a single element — reality is it's the shared chassis for three different capabilities.** Every live behavior (posts, comments, reactions, reconnect, unread) depends on this controller existing. That means the first capability we ship pays the full infrastructure cost; later ones are cheap add-ons. Scopes should reflect this — the first business capability absorbs the scaffold.

2. **Comment broadcasting lives alongside existing Turbo Stream behavior.** The Package flagged this as "Patched" via dedup, but Session 01 listed it as a Known Unknown. Real conflict surface: when the author creates a comment, they get Turbo Stream *and* the Action Cable broadcast. The dedup must run reliably in the Stimulus `received` handler before the Turbo Stream patch lands, otherwise we'll see flicker or duplicates. This is a behavioral risk the Package's one-line "Patched" understates.

3. **"Catch up on missed events" on reconnect is vaguer than the Package implies.** The Package says "lightweight AJAX request to refresh mural state." In practice that means either (a) re-rendering the feed container (loses scroll position, kills any expanded threads), or (b) diffing against a `since` timestamp. Session 01 did not resolve this. Expect this to be the slow spot in the Connection Resilience scope.

4. **Read Tracking was imagined core, Session 01 hammered it to nice-to-have.** Agreeing with that call — the existing unread glow from page load already covers the first-visit case, and the mural's "new conversation" feeling is driven by content arrival, not unread state. Keep it nice-to-have.

5. **Reactions are simpler than the Package treats them.** It's a count + emoji update on an existing element. No new markup, no scroll, no dedup concern (reactions are idempotent at the model level). Effectively a 30-minute scope once the controller exists.

## First Piece Selection

**This is a continuation session.** Session 01 already picked and shipped the first piece (Channel Authorization + Post Broadcasting — the backend half of "posts appear live"). The next first piece for Session 02 is:

**Making posts actually appear on other users' murals in the browser.**

That means completing the frontend half of `scope-posts-appear-live-on-mural`: the Stimulus controller, subscription, DOM insertion, dedup, and scroll handling.

Core / Small / Novel reasoning:

- **Core**: Without this, nothing the backend broadcasts is visible. Every other live capability (comments, reactions, reconnect, unread) depends on the controller's subscription + `received` dispatch existing. This is *the* walking skeleton for the whole feature.
- **Small**: Scoped to posts only. Not comments, not reactions, not reconnection. One event type, one handler, one DOM operation (prepend). Deliberately narrow so we get the controller validated end-to-end before extending it.
- **Novel**: This codebase has no Action Cable subscription on the client side, no prior Stimulus controller that mutates the mural feed, and no existing dedup/scroll pattern. All three things are being done for the first time in this repo. Perfect candidate for first-piece focus.

Handover also flagged this as the riskiest remaining scope ("Mural Live Controller — uphill, most unknowns"), which matches the inverted pyramid: push the risk up first, validate with working code, then extend.

