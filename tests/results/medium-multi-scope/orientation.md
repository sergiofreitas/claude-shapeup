
# Orientation — T02 Notification Preferences Dashboard

**Date**: 2026-04-17
**Feature ID**: T02
**Appetite**: Small Batch (1 week)

## Problem Restated

Parents are drowning. Every classroom their kids belong to generates a steady stream of events, announcements, homework, and photos, and right now it's all one undifferentiated firehose — no way to say "I care about homework for 3rd grade but not photo posts from kindergarten." The only escape valve is the OS-level notification kill switch, and using it makes urgent school-safety messages disappear too. So parents cope by ignoring the app, and important messages get buried.

We want to give parents a scalpel instead of a sledgehammer: let them silence specific classroom+post-type combos, keep urgent messages unmutable, and default everything ON so new parents aren't stuck configuring before they can use the app.

## Codebase Observations (What I Expect to Find)

Based on the Package's Technical Validation section, the codebase is a Rails app with:

- **Services layer** for notification delivery — `app/services/notification_service.rb` with a `deliver_to_guardian` method that fans out to push/email/SMS. This is where the new filter has to sit.
- **Guardian model** already has a `guardianships` → `classrooms` association, so the matrix UI can iterate over `current_guardian.classrooms` naturally.
- **Post model** already has a `post_type` string column with the enum values we care about (announcement, event, homework, photo, urgent) — no schema change needed on posts.
- **Turbo + Stimulus** conventions already exist — toggle patterns are apparently in use, so the PATCH-returning-turbo-stream pattern for each toggle should fit cleanly.
- **Guardian-namespaced routes** already exist, so `guardian_notification_preferences_path` has a natural home.
- **System tests** presumably use Capybara against a real browser (standard for Rails), which lets us verify the matrix UI with accordion behavior end-to-end.

## Imagined vs. Discovered (Tensions to Watch)

A few places where the shaped solution might bump into the actual codebase:

- **"Absence = not muted" semantics in the delivery filter.** The Package says we do one `exists?` query per recipient. If the existing `deliver_to_guardian` loops over recipients individually, fine. If it batch-queries by classroom or bulk-sends, dropping an N+1 `exists?` call into the loop could regress performance on classrooms with 30+ guardians. Worth sanity-checking before we commit to the naive form.

- **Turbo Stream toggle responses.** The Package assumes each toggle round-trips a PATCH that returns a stream. That's clean for single toggles but awkward if the guardian flips 10 in a row — we'll want to watch for flicker and race conditions (toggle A request still in flight when B lands). Might need a tiny debounce or optimistic UI.

- **"Urgent toggle is disabled (always ON)".** The Package says to render the urgent column as a disabled toggle. That's the right UX, but the delivery filter must NOT trust the UI — the bypass has to be enforced server-side regardless of what shows up in preferences. (The Rabbit Hole already says this; noting here so it stays front of mind.)

- **Guardian vs. non-guardian dashboards.** Element 5 (Dashboard Link) says show only for guardians. Need to confirm the dashboard view has a role-aware helper or partial; if not, we're adding a small helper alongside.

- **Migration on a running system.** Empty table = defaults = all ON. But if the migration runs during a notification burst (homework reminders at 4pm), and the filter references `NotificationPreference` before the table exists, we get exceptions. The rollout order has to be: ship migration first, then ship the filter code that reads from it. Standard, but worth flagging in the deploy note.

## First Piece Selection

**Chosen first piece**: a single end-to-end mute round-trip — one guardian, one classroom, one post type (homework), toggled off, and a homework notification for that classroom+guardian does not get delivered. Include an urgent-bypass assertion in the same test so the safety guarantee is present from day one.

This fits Core / Small / Novel:

- **Core**: it exercises every layer that matters — migration, model, toggle endpoint, minimal UI, and the delivery filter. Everything else (matrix UI, accordion, dashboard link) is variation on top of this skeleton. Without it, nothing else has anywhere to attach.

- **Small**: no accordion, no multi-classroom layout, no polished styling, no navigation integration. One classroom, one toggle, one delivery path. Achievable inside a session with room to spare.

- **Novel**: we've never had per-recipient, per-classroom, per-type filtering in the delivery pipeline before. The absence-based preference model is also new. Doing the novel thing first validates the architecture before we invest in UI breadth.

What this first piece is **not**: the production UI. The test-driving UI might literally be a single toggle on a bare page — just enough to prove the wiring. Visual polish and the matrix layout land in a later scope.

