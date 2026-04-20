# Hill Chart — T03 Real-Time Classroom Activity Feed

**Updated**: 2026-04-17
**Session**: 02
**Appetite**: Big Batch (2 weeks)

## Scopes

  ▲ **Posts Appear Live on the Mural** — Uphill, significant unknowns (DOM mutation, dedup, scroll handling). Backend done, frontend is where risk lives.
  ▲ **Comments Appear Live on the Mural** — Uphill, moderate unknowns (Turbo Stream coordination). Not started.
  ▲ **Reactions Update Live on the Mural** — Uphill, low unknowns (pattern replication). Not started.
  ▲ **Connection Survives Network Drops** — Uphill, meaningful unknowns (catch-up strategy undecided). Not started.
  ~ **New Items Marked Unread Until Seen** — Nice-to-have. Cut candidate.

## Sequencing Rationale (Inverted Pyramid)

Push the riskiest, most load-bearing work uphill first; let validated infrastructure flow downhill into cheaper, lower-risk scopes.

1. **Posts Appear Live first** — carries the shared Stimulus controller, subscription lifecycle, and dispatcher. Every other live scope inherits this foundation. Riskiest DOM work lives here. Validating this scope end-to-end means the architecture holds; everything after becomes pattern replication.

2. **Comments second** — depends on #1. Higher risk than reactions because of the Turbo Stream conflict. Tackling it before reactions means we prove the controller extends cleanly while the risk is still non-trivial. If the controller design is wrong, we find out here, not at the end.

3. **Reactions third** — simplest capability; confidence builder. Fast. Having it done means all three event types are wired before we touch reconnect logic — so reconnect has a complete target to validate.

4. **Connection Resilience fourth** — cross-cutting concern. Only meaningful once all events are flowing. Contains a design decision (catch-up strategy) best made with a working mural in front of us, not up front.

5. **Unread tracking last, and cuttable** — already hammered to nice-to-have. First thing to drop if appetite tightens.

Note on the Package's original element list: "Mural Live Controller" was a technical element, not a capability. It does not appear as a scope — it's absorbed into scope #1, which is the first capability that requires it.

## Risk

**Posts Appear Live on the Mural.** Specifically: DOM dedup interacting with scroll-position preservation when multiple posts arrive in quick succession. The Stimulus `received` handler must (a) check for duplicate `dom_id`, (b) decide scroll vs. indicator, (c) animate insertion, all without racing itself if two events land within the same animation frame. This is where an afternoon could evaporate.

## Next

Push **Posts Appear Live on the Mural** uphill. Concretely:

1. Create `app/javascript/controllers/mural_live_controller.js` with `connect()` subscription and a skeleton `received(data)` dispatcher.
2. Add data attributes to `app/views/mural/show.html.erb`.
3. Implement `handleNewPost` with dedup + prepend (no scroll logic yet — simplest case).
4. Verify in two browsers: user A posts, user B's feed updates.
5. Add scroll-threshold indicator and animation.
6. Write system test covering the full path.

When the two-browser verification works, this scope tips over the hill. Expect comments + reactions to go downhill quickly after.

## History

### Session 01 — 2026-02-16
  ✓ Channel Authorization — Done (channel created, auth tested for teacher/admin/guardian)
  ▼ Event Broadcasting (posts) — Downhill (post callback + partial rendering working; comments/reactions not yet wired)
  ▲ Mural Live Controller — Uphill (scaffolded, subscription connects, DOM handling not started)
  ▲ Connection Resilience — Uphill (not started)
  ~ Read Tracking Integration — Nice-to-have (hammered from must-have; existing unread glow covers first-visit case)

  **Movement**: Channel Authorization went from uphill → done. Event Broadcasting went from uphill → downhill for posts. Read Tracking reclassified as nice-to-have.

### Session 02 — 2026-04-17 (starting)
  ▲ Posts Appear Live on the Mural — Uphill (scopes restructured around capabilities; absorbs the former "Mural Live Controller" element plus the finished post broadcasting)
  ▲ Comments Appear Live on the Mural — Uphill (new scope; absorbs the comment broadcast element + comment live update element)
  ▲ Reactions Update Live on the Mural — Uphill (new scope; absorbs the reaction elements)
  ▲ Connection Survives Network Drops — Uphill (renamed from Connection Resilience for capability framing)
  ~ New Items Marked Unread Until Seen — Nice-to-have (renamed from Read Tracking Integration)

  **Movement**: No work completed yet this session — this entry captures the re-framing of Package elements into business-capability scopes. Next push targets the Posts-Appear-Live scope.
