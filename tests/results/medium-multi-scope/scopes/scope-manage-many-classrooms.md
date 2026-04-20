
# Scope: Manage Many Classrooms

## Hill Position

▲ Uphill — the accordion pattern is new for this page, and mobile layout with 5 classrooms × 5 types is the Rabbit Hole we explicitly flagged. Until we've seen it render on a phone-sized viewport with real data, unknowns remain.

## Prioritization Reasoning

**Third scope. Medium risk, medium effort, unblocks the full user experience.** Once the vertical slice proves the architecture, this is where we make the page actually usable for the parent with 3 kids in different classrooms — the exact persona the problem statement names. The riskiest part is the mobile accordion: desktop is forgiving but a 25-toggle matrix on a 375px-wide screen is not.

We do this third because (a) the foundation is in place after scope 1, (b) the safety net is in place after scope 2, and (c) the dashboard link (scope 4) is trivial and benefits from landing after this page is polished.

There's also a scope-hammering opportunity here: the accordion is a must-have on mobile, but if we get pinched for time, a simple "collapse classrooms with >N types muted" could substitute for a full animated accordion.

## Must-Haves

- [ ] Matrix UI: render all classrooms the guardian belongs to, each with its full set of post-type toggles
- [ ] Accordion: each classroom is a collapsible section; expanded by default on desktop, collapsed by default on mobile
- [ ] Mobile layout: toggles stack vertically within a classroom section; no horizontal scroll
- [ ] Each toggle submits independently via Turbo Stream PATCH; page does not reload
- [ ] Visual state matches DB state after each toggle (no stale UI)
- [ ] System test: guardian with 3 classrooms sees all 3, can expand/collapse each, can toggle within each
- [ ] System test at mobile viewport: same as above, layout does not overflow

## Nice-to-Haves

- [ ] ~ "Mute all non-urgent for this classroom" one-click action per classroom header (Package no-gos explicitly forbid "batch mute everything" but per-classroom bulk might be fine — flag with user before building)
- [ ] ~ Smooth expand/collapse animation (functional accordion first; animation is polish)
- [ ] ~ Count badge: "3 of 5 types muted" in the classroom header
- [ ] ~ Empty state for guardian with no classrooms ("You aren't in any classrooms yet")

## Notes

- Re-read Package Rabbit Hole #2 before starting: "collapsible per-classroom section" is the explicit guidance.
- Keep the toggle-submit pattern from scope 1 — don't invent a new mechanism here.
- If we find ourselves writing custom CSS beyond the project's existing conventions, stop and ask — styling should come from the existing design system.

