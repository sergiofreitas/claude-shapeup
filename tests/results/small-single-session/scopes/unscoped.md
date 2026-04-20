# Unscoped

Tasks discovered but not yet assigned to a scope. Move into a scope file once their home is clear.

## Open Questions
- [ ] Confirm test framework (Minitest vs RSpec) before writing the first test
- [ ] Confirm button styling convention used elsewhere in the views (helper? utility classes?)
- [ ] Confirm whether `app/views/grades/index.html.erb` renders inline or via partial — affects where the button goes

## Cross-Cutting / Possibly Future
- [ ] ~ Audit other controllers for "export" patterns we might want to extract into a concern later (out of scope for T01; note for a future shaping cycle if export spreads)

## Decisions Pending
- [ ] Decide whether to prepend UTF-8 BOM or document Excel import workaround — pending discovery during scope-brazilian-spreadsheet-compatibility

