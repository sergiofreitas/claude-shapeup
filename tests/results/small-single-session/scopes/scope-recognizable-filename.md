# Scope: Recognizable Filename

## Hill Position
▲ Uphill — trivial implementation but explicitly nice-to-have (R3) per Package. Position is uphill only because no work has started; will move downhill in minutes once tackled.

## Prioritization Reasoning
**Build this last, and only if budget allows.** R3 is marked nice-to-have in the Package itself. The feature ships and delivers the core value (R0–R2) without it. Coordinators receiving "grades.csv" can rename if needed; the cost of the missing filename is low. By contrast, the time saved by deferring this protects against overruns on the two genuinely uphill scopes above. If scope-brazilian-spreadsheet-compatibility takes longer than expected, this scope is the first thing to cut.

## Must-Haves
*(none — entire scope is nice-to-have per Package R3)*

## Nice-to-Haves
- [ ] ~ Set `Content-Disposition` filename to `<classroom-slug>-grades-<YYYY-MM-DD>.csv`
- [ ] ~ Sanitize classroom name for filesystem safety (downcase, replace spaces with hyphens, strip special chars)
- [ ] ~ Test asserting filename format in response header

## Notes
- If cut: leave the default `export_csv.csv` filename — functional, just less polished.
- If kept: use Rails' `parameterize` on classroom name; date from `Date.current.iso8601`.

