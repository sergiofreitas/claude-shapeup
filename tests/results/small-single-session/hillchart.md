# Hill Chart — CSV Export for Grade Reports

**Feature**: T01
**Updated**: 2026-04-17
**Session**: 01

## Scopes
  ▲ Teacher Downloads Grade CSV — Uphill (wiring unknowns: route helper, button placement, response headers)
  ▲ Brazilian Spreadsheet Compatibility — Uphill (genuine unknown: BOM requirement for Excel-BR)
  ▲ Recognizable Filename — Uphill (trivial; not started; nice-to-have only)

## Sequencing Rationale (Inverted Pyramid)

The order is **spine → risk → polish**, deliberately not "easiest first":

1. **Teacher Downloads Grade CSV** goes first because it's the *base of the pyramid*: a wide, low-fidelity end-to-end slice that proves the feature is wireable. Without it, the other scopes have nothing to attach to. Tackling it first surfaces all the boring framework unknowns (routes, headers, view conventions) so they don't ambush the riskier work later.

2. **Brazilian Spreadsheet Compatibility** goes second because it's the *highest-risk unknown that affects whether the feature actually works for its user*. The Package patches it with one line of code, but real-world Excel-BR behavior is the kind of thing that's optimistic until verified. Putting it second — not last — protects appetite: if the BOM workaround turns out to be more involved, we discover that with time still on the clock to scope-hammer or escalate.

3. **Recognizable Filename** goes last because the Package itself flagged it nice-to-have and it has no unknowns. Doing it last means it's the natural cut line if either upstream scope eats more time than expected.

## Risk

**Brazilian Spreadsheet Compatibility** is the riskiest scope. The unknown is empirical, not architectural: will the Package's prescribed `CSV.generate(encoding: 'UTF-8', col_sep: ';')` actually produce a file that Excel-BR opens with accents rendered correctly, or is a UTF-8 BOM also required? If the BOM is needed, that's still small. If something stranger is needed (e.g., Latin-1 encoding for legacy Excel installs the school uses), the appetite assumption breaks and we'd need to scope-hammer R1's "student name" requirement to ASCII-safe or escalate.

## Next

Push **Teacher Downloads Grade CSV** uphill. Specifically: the first vertical slice — route + controller action returning two hardcoded rows + view button — to validate end-to-end wiring before adding real query logic.

## History

### Session 01 — 2026-04-17 (Orientation)
- Read Package, oriented on codebase expectations.
- Identified three discovered scopes (none pre-planned beyond "make CSV export work").
- All three start ▲ Uphill — no code yet.
- Identified Brazilian Excel BOM as the highest-risk unknown the Package may have under-specified.
- Selected Teacher Downloads Grade CSV as first piece (Core / Small / Novel).
- **Movement**: Initial chart established. No scopes have moved yet — first session begins next.
