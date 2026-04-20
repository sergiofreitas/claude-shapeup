
# Scope: Silence Classroom Post Types

## Hill Position

▲ Uphill — approach validated by the Package, but the filter logic against the real `notification_service.rb` is the main unknown. Once the first vertical slice lands and tests are green, this scope moves downhill quickly.

## Prioritization Reasoning

**First scope. Highest risk, deepest integration.** Every other scope in this package is a variation on top of the filter-plus-preferences foundation this scope establishes. The critical risks all live here:

- The delivery filter either blocks too much (missed messages, user complaint) or too little (failed muting, user complaint) — both are product-breaking.
- The absence-based preference model is novel in this codebase. If the semantics (no row = not muted) bump into some ORM default or accidentally-truthy behavior, we want to find out immediately.
- The urgent bypass is enforced here. The cost of getting it wrong is a missed safety message — the highest-severity failure in this feature.

By doing this scope first as a thin vertical slice — one guardian, one classroom, one toggle, one delivered vs. not-delivered notification, plus an urgent-bypass assertion — we validate the entire architecture before we invest in matrix UI or navigation polish. If the architecture is wrong, we learn it on day one, not day four.

## Must-Haves

- [ ] Migration: create `notification_preferences` table (`guardian_id`, `classroom_id`, `post_type`, `muted`) with unique index on `[guardian_id, classroom_id, post_type]`
- [ ] Model: `NotificationPreference` with `belongs_to :guardian`, `belongs_to :classroom`
- [ ] Model: `Guardian has_many :notification_preferences`
- [ ] Model test: creating/updating/toggling a preference round-trips correctly
- [ ] Delivery filter: in `notification_service.rb#deliver_to_guardian`, short-circuit to deliver if `post.post_type == 'urgent'`; otherwise skip delivery when a matching muted preference exists
- [ ] Integration test: guardian with `muted: true` preference for (classroom X, homework) does NOT receive homework notification for classroom X
- [ ] Integration test: same guardian DOES receive urgent notification from classroom X regardless of preferences
- [ ] Integration test: guardian with no preference row receives all notifications (absence = not muted)
- [ ] Minimal toggle endpoint: `PATCH /guardian/notification_preferences` accepts `classroom_id` + `post_type`, creates-or-toggles the preference, returns a success response
- [ ] Minimal preferences page: one classroom, toggles rendered for each non-urgent post type, no styling, no accordion — just enough to prove the UI-to-DB round-trip works
- [ ] System test: guardian clicks a toggle, next homework notification for that classroom is suppressed

## Nice-to-Haves

- [ ] ~ Confirmation toast after toggle
- [ ] ~ Inline "muted" visual state indicator beyond the toggle's own state

## Notes

- Follow existing Turbo Stream conventions from `app/javascript/controllers/` for the toggle response.
- Server must enforce urgent bypass independent of UI — do not rely on the disabled toggle to prevent urgent preferences being created.
- Don't prematurely optimize: one `exists?` per recipient per notification is fine at current scale per the Package. If the batch-delivery question (see unscoped) reveals an N+1, revisit here.
- Commit the migration separately from the filter code so deploys can go in the right order.

