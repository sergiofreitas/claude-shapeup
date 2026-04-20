# Package: Notification Preferences Dashboard

**Feature ID**: T02
**Created**: 2026-02-16
**Status**: Shape Go

---

## Problem

Parents receive every notification from every classroom their children are in — event announcements, homework reminders, photo posts, admin messages. A parent with 3 kids in different classrooms gets 15+ notifications daily. They can't mute specific types or classrooms. The only option is to disable notifications entirely in their phone's OS settings, which means they miss urgent messages too.

The workaround today: parents mentally filter notifications, eventually ignoring most of them. Important messages get lost in the noise.

## Appetite

**Small Batch: 1 week**

## Requirements (R)

| ID | Requirement | Status |
|----|-------------|--------|
| R0 | Parents can control which notifications they receive | Core goal |
| R1 | Per-classroom toggle: mute/unmute all notifications from a classroom | Must-have |
| R2 | Per-type toggle: mute/unmute by post type (event, announcement, homework, photo, urgent) | Must-have |
| R3 | "Urgent" type cannot be muted (school safety messages always delivered) | Must-have |
| R4 | Preferences persist across sessions and devices | Must-have |
| R5 | Default state: all notifications ON (opt-out model) | Must-have |
| R6 | Delivery channel preferences (push vs email vs SMS) | Out |
| R7 | Quiet hours / scheduling | Out |

## Solution

A preferences page accessible from the parent dashboard, backed by a `notification_preferences` table that stores per-guardian, per-classroom, per-type muting decisions. The notification delivery pipeline checks preferences before sending.

### Element: Preferences Data Model

**What**: New `NotificationPreference` model with columns: `guardian_id`, `classroom_id`, `post_type`, `muted` (boolean).
**Where**: New migration, new model file `app/models/notification_preference.rb`
**Wiring**: `belongs_to :guardian`, `belongs_to :classroom`. Unique index on `[guardian_id, classroom_id, post_type]`. Default: no rows = all notifications ON (absence = not muted).
**Affected code**: New migration, new model, `Guardian` model gains `has_many :notification_preferences`
**Complexity**: Low

### Element: Preferences UI Page

**What**: A settings page showing a matrix of classrooms × post types with toggle switches. Each toggle mutes/unmutes that combination.
**Where**: New route `GET /guardian/notification_preferences`, new controller `Guardian::NotificationPreferencesController`, new view.
**Wiring**: Loads all classrooms for the current guardian (via `Guardianship` → `Classroom`). For each classroom, shows toggles for each post type. "Urgent" type toggle is disabled (always ON). Toggles submit via Turbo with PATCH requests.
**Affected code**: New controller, new view, `config/routes.rb` update
**Complexity**: Medium — the matrix UI needs to handle variable number of classrooms and degrade gracefully on mobile.

### Element: Toggle Endpoint

**What**: PATCH endpoint that creates or updates a `NotificationPreference` record to toggle muting.
**Where**: `Guardian::NotificationPreferencesController#update`
**Wiring**: Receives `classroom_id` and `post_type` params. Finds or creates `NotificationPreference` for the guardian. Toggles `muted` boolean. Returns Turbo Stream that updates the toggle state without full page reload.
**Affected code**: Controller update action, Turbo Stream template
**Complexity**: Low

### Element: Delivery Pipeline Filter

**What**: Before sending any notification, check the recipient's preferences. Skip delivery if the guardian has muted that classroom+type combination.
**Where**: `app/services/notification_service.rb` (existing service that handles push/email/SMS delivery)
**Wiring**: In the `deliver_to_guardian` method, add a check: `NotificationPreference.exists?(guardian: guardian, classroom: post.classroom, post_type: post.post_type, muted: true)`. If muted, skip. If no preference record exists, deliver (default ON).
**Affected code**: `app/services/notification_service.rb` — add filter before delivery
**Complexity**: Low — single query check, but must be tested thoroughly to avoid accidentally blocking urgent messages.

### Element: Dashboard Link

**What**: Add "Notification Settings" link to the parent dashboard navigation.
**Where**: `app/views/dashboard/index.html.erb`
**Wiring**: Simple link to `guardian_notification_preferences_path`. Show only for guardians (not teachers/admins).
**Affected code**: Dashboard view, possibly shared navigation partial
**Complexity**: Low

## Rabbit Holes

- **Urgent message bypass**: The delivery filter must ALWAYS deliver `urgent` type regardless of preferences. Hard-code this exception. Never check preferences for urgent posts. **Patched** — filter short-circuits: `return true if post.post_type == 'urgent'`.
- **Guardian with many classrooms**: A guardian with 5 classrooms × 5 types = 25 toggles. Mobile layout must handle this. Use a collapsible per-classroom section. **Patched** — accordion UI per classroom.
- **Notification preferences vs OS-level settings**: If a user disables push notifications at the OS level, our preferences page can't re-enable them. Show a notice: "Push notifications are disabled on your device. Enable them in your phone settings." **Patched** — info banner, not a blocker.
- **Migration on production**: The `notification_preferences` table starts empty (all defaults = ON). No data migration needed. **Patched**.
- **Preference caching**: At current scale (hundreds of guardians), a single query per notification is fine. No caching needed within appetite. **Patched**.

## No-Gos

- No delivery channel preferences (push vs email vs SMS) — out of scope (R6)
- No quiet hours or scheduling — out of scope (R7)
- No per-post muting — only per-type, per-classroom granularity
- No admin control over notification preferences — guardians self-serve only
- No batch mute/unmute ("mute everything") — use individual toggles

## Technical Validation

**Codebase reviewed:**
- `app/services/notification_service.rb` (89 lines) — `deliver_to_guardian` method at line 34
- `app/models/guardian.rb` — has `guardianships` → `classrooms` association chain
- `app/models/post.rb` — has `post_type` attribute (string enum: announcement, event, homework, photo, urgent)
- `app/views/dashboard/index.html.erb` — parent dashboard with navigation section
- `config/routes.rb` — guardian namespace exists
- `app/javascript/controllers/` — Stimulus controllers for toggle patterns exist

**Approach validated**: Absence-based preference model (no rows = all ON) avoids migration complexity and handles new classrooms automatically. Delivery filter is a single `exists?` query — O(1) per recipient per notification.

**Test strategy**: TDD — model tests for preference logic, integration tests for toggle endpoint, integration test for delivery filtering (especially urgent bypass), system test for the preferences UI.
