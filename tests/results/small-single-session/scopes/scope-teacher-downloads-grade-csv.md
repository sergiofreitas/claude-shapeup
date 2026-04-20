# Scope: Teacher Downloads Grade CSV

## Hill Position
▲ Uphill — approach is clear (Rails controller + send_data + view link) but no end-to-end wiring exists yet. Unknowns: exact route helper name, button placement convention, response header pattern in this app.

## Prioritization Reasoning
**Build this first.** It is the spine of the feature — every other scope decorates this one. Until a teacher can click a button and receive *some* CSV file, nothing else is verifiable. The riskiest unknowns here are wiring unknowns (does the route compose correctly? does the view helper exist?), and they're best resolved with a thin end-to-end slice rather than by building the controller and view in isolation. Inverted pyramid: this scope is the broad base — wide reach, low fidelity — that everything else narrows on top of.

## Must-Haves
- [ ] Add `export_csv` route under nested classroom grades (collection route)
- [ ] Add `export_csv` controller action that loads `@classroom.grades.includes(:student)`
- [ ] Generate CSV with columns: student name, grade value, date
- [ ] Respond with `text/csv` and `Content-Disposition: attachment`
- [ ] Add "Download CSV" button to grades index view
- [ ] Conditionally show button only when grades exist
- [ ] Integration test: request endpoint, assert content type and CSV body has expected rows
- [ ] Manual browser verification: navigate to grades page, click button, confirm file downloads with correct content

## Nice-to-Haves
- [ ] ~ Disable button (vs hide) when no grades, with tooltip explaining why
- [ ] ~ Match button styling to nearest sibling action button exactly

## Notes
- Start with hardcoded CSV body to validate routing and download mechanics, then swap in the real query.
- Watch the `@grades.any?` vs `@classroom.grades.any?` distinction — pagination on index could mislead.
- Defer encoding concerns to the next scope; here, plain UTF-8 is fine for the test.

