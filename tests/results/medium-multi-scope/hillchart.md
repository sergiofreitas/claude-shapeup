
# Hill Chart — T02 Notification Preferences Dashboard

**Updated**: 2026-04-17
**Session**: 01

## Scopes

  ▲ Silence Classroom Post Types — Uphill (approach validated, filter integration against real `notification_service.rb` is the open unknown)
  ▲ Urgent Messages Always Break Through — Uphill (bypass logic unwritten until filter exists; edge-case coverage not yet defined)
  ▲ Manage Many Classrooms — Uphill (matrix UI and mobile accordion not yet sketched)
  ▲ Discover Preferences From Dashboard — Uphill (trivially so; guardian-role gate needs a 5-min confirmation)

## Sequencing Rationale (Inverted Pyramid)

We push uphill on the riskiest, most foundational scope first, then build downward through progressively safer and more additive work:

1. **Silence Classroom Post Types first** — this scope carries the architectural risk (absence-based preference model, delivery filter integration) and the most dependencies. Everything else plugs into the foundation it establishes. A thin end-to-end vertical slice here validates (or invalidates) the entire design before we invest in breadth.

2. **Urgent Messages Always Break Through second** — cannot exist without the filter from scope 1, but gets its own scope because the safety guarantee deserves explicit, named test coverage. If the filter breaks in the future, we want the urgent-bypass test suite to scream, not a subtle miss buried in a generic integration test.

3. **Manage Many Classrooms third** — with the foundation and safety net in place, we build the actual usable experience. This is where the real UX risk lives (mobile accordion, many-classroom layout), but it's purely additive on top of the skeleton — no architectural surprises possible.

4. **Discover Preferences From Dashboard fourth** — tiny but essential closure. Must be last because there's no point linking to a page that doesn't work. This is also the natural place to catch the "trivial but forgotten" work.

The inverted pyramid: the top (scope 1) is narrow and risky; the base (scope 4) is wide and safe. Push hard at the top; sweep downhill at the base.

## Risk

**Riskiest scope: Silence Classroom Post Types.** Two compounding unknowns:

- *Delivery filter integration.* The Package assumes `deliver_to_guardian` is called per-recipient in a loop, making the `exists?` query O(1) per call. If delivery is actually batched, we need a different filter strategy and possibly a bulk preference query. Until we read the real service code and trace one notification end-to-end, we can't be sure.
- *Absence-based semantics in practice.* "No row = not muted" is clean on paper, but in a Rails app with implicit defaults, eager loading, or scope chains, it could surprise us. The first passing test resolves this; until then, it's uphill.

**Secondary risk: Manage Many Classrooms mobile layout.** 25 toggles on a phone screen is a known UX hazard (flagged in Package Rabbit Hole #2). The accordion solution is sketched but unbuilt. Low product risk, high aesthetic risk.

## Next

Push **Silence Classroom Post Types** uphill. Specifically, the first piece: write the failing integration test asserting that a guardian with a muted preference for (classroom X, homework) does NOT receive the homework notification, AND still receives urgent notifications from the same classroom. Then build the migration, model, minimal filter, minimal toggle endpoint, and minimal UI to make the test pass.

Expected movement by end of next session: Silence Classroom Post Types from ▲ Uphill to ▼ Downhill.

## History

### Session 01 — 2026-04-17 — Orientation & Scope Discovery

**Focus**: Read Package, study codebase expectations, identify first piece, map initial scopes.

**Movement**:
- *Silence Classroom Post Types*: (did not exist) → ▲ Uphill. Scope named, must-haves listed, first piece selected as thin vertical slice with urgent-bypass assertion baked in from test one.
- *Urgent Messages Always Break Through*: (did not exist) → ▲ Uphill. Split out from core scope so the safety guarantee gets named test coverage.
- *Manage Many Classrooms*: (did not exist) → ▲ Uphill. Accordion approach noted per Rabbit Hole #2; mobile layout flagged as secondary risk.
- *Discover Preferences From Dashboard*: (did not exist) → ▲ Uphill. Scoped last, lowest risk.

**Decisions**:
- Named scopes by business capability, not by technical element. Package elements (Preferences Data Model, Preferences UI Page, Toggle Endpoint, Delivery Pipeline Filter, Dashboard Link) are distributed across scopes rather than mapped 1:1 — each scope pulls what it needs from multiple elements to deliver an end-to-end slice.
- Urgent bypass gets built in scope 1 (TDD forces it), hardened in scope 2. Not deferred.
- No code written this session — orientation and planning only.

**Open items → unscoped.md**:
- Confirm `deliver_to_guardian` is per-recipient vs. batched.
- Confirm existing guardian-role gate on dashboard.
- Decide on toggle debounce / optimistic UI.

---

Planning dry run complete. Four scopes identified, inverted-pyramid sequencing rationale stated, first piece (thin end-to-end mute with urgent-bypass assertion inside scope-silence-classroom-post-types) selected with Core/Small/Novel reasoning, and hill chart shows all four scopes uphill at session start with the first scope queued for the next push.
