
# Unscoped Tasks

Tasks that have surfaced but don't yet fit a scope, or need a decision before they can be placed.

## Open Questions

- **Batch-delivery path in `notification_service.rb`**: confirm whether `deliver_to_guardian` is called in a loop per-recipient or whether there's a batch path. Determines whether the filter is O(1) per call or needs a single bulk query. → resolves into either `scope-silence-classroom-post-types` (if per-recipient) or spawns a new scope (if batch path needs rework).

- **Toggle debounce / race handling**: do we need optimistic UI on the toggles, or is the PATCH fast enough that a plain round-trip is fine? → will likely land in `scope-manage-many-classrooms` once we have the full matrix in front of us.

- **Role-aware dashboard rendering**: confirm whether the dashboard view already has a guardian-only partial helper or if we're adding one. → lands in `scope-discover-preferences` once confirmed.

## Possible Nice-to-Haves (Not Yet Placed)

- ~ Analytics event when a guardian mutes something (which type gets muted most? informs future product decisions, but not needed to ship)
- ~ "You have muted X of Y notifications from this classroom" summary text on the preferences page
- ~ Toast confirmation after toggle ("Homework from Ms. Patel's class muted")

## Deferred / Likely Out

- OS-level push-disabled info banner (Package Rabbit Hole mentions this). Belongs in `scope-discover-preferences` if we do it, but may defer entirely since the OS setting is outside our control — candidate for `~`.

