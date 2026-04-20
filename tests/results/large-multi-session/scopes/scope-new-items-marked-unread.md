# Scope: New Items Marked Unread Until Seen

## Hill Position

~ **Nice-to-have.** Hammered from Session 01. Existing page-load unread glow covers the first-visit case; real-time unread styling is polish.

## Prioritization Reasoning

**Why last (and cuttable):**

- Entire scope is nice-to-have per Session 01 decision.
- Depends on all prior scopes (needs live event arrival to attach unread state to).
- Cutting it does not break the core promise: "new items appear without refresh." It only affects the visual "freshness" indicator.
- If appetite runs tight, this is the first thing to drop with no protest.

## Must-Haves

(None — scope is entirely nice-to-have)

## Nice-to-Haves (~)

- [ ] ~ New posts/comments inserted via WebSocket get `unread` CSS class (consistent with existing unread glow)
- [ ] ~ IntersectionObserver watches unread elements entering viewport
- [ ] ~ On intersection, PATCH existing read-tracking endpoint and remove `unread` class
- [ ] ~ No double-marking if the item was already read via page-load path

## Notes

- Only pick up if Connection Resilience finishes with session budget remaining.
- If we take it on, integrate with the existing read-tracking endpoint — do not create a parallel path.
- Acceptance is purely visual; no backend schema changes.

