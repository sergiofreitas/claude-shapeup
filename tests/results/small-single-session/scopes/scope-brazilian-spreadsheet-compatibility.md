# Scope: Brazilian Spreadsheet Compatibility

## Hill Position
▲ Uphill — genuine unknown. Package prescribes `col_sep: ';'` and UTF-8 encoding, but in practice Brazilian Excel often also requires a UTF-8 BOM for accented characters to render. Need to validate empirically.

## Prioritization Reasoning
**Build this second**, immediately after the spine works. Reason: this is the highest-risk unknown in the feature. If we discover Excel-BR mangles names *after* shipping, the feature is functionally broken for the user we shaped it for — coordinators won't accept a file with `Jo�o` instead of `João`. Tackling it second (not last) gets the unknown over the hill while we still have appetite. It also stays *separate* from scope #1 because it's verifiable independently: same endpoint, but the verification is "open in Excel-BR and see correct rendering," not "file downloads."

## Must-Haves
- [ ] Set `col_sep: ';'` in CSV generation (Brazilian Excel default)
- [ ] Investigate: does Excel-BR need UTF-8 BOM prepended? Test with an accented name (`João`, `Conceição`).
- [ ] If BOM needed, prepend `\uFEFF` to response body
- [ ] Test with a fixture row containing accented characters — assert byte sequence in response
- [ ] Manual verification: download file, open in LibreOffice Calc with Brazilian locale (closest available proxy if Excel unavailable), confirm accents render

## Nice-to-Haves
- [ ] ~ Add a comment in the controller explaining the BOM/encoding choice with a one-line "why" so future maintainers don't strip it

## Notes
- This scope is where the Package's "Patched" rabbit hole gets stress-tested. The Package may be optimistic; verify don't assume.
- Acceptable downhill criterion: a downloaded file with `José Conceição` opens with the accents intact in the target tool.

