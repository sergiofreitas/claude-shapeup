# Orientation — CSV Export for Grade Reports

**Feature**: T01
**Session**: 01
**Date**: 2026-04-17

## Problem Restated

Teachers can see grades on screen but have no way to hand them off. The school's coordination layer lives in spreadsheets, so today the bridge between "grades in the app" and "grades a coordinator can act on" is a teacher manually retyping numbers — slow for any class, broken for a class of thirty. We want one click on the grades page to produce a CSV the coordinator can open and use as-is.

## Codebase Observations (what I expect to find)

Based on the Package's technical validation, I expect:

- **`app/controllers/grades_controller.rb`** — A standard Rails RESTful controller. The `index` action likely scopes to a classroom (via nested route) and eager-loads `:student`. New action `export_csv` should mirror that loading pattern.
- **`app/views/grades/index.html.erb`** — Action bar area mentioned, probably near the top with "New Grade" or similar. Need to confirm the button styling convention (`btn btn-secondary`? Tailwind utility? Custom helper?).
- **`config/routes.rb`** — `resources :grades` nested under `resources :classrooms`. Need a `collection do; get :export_csv; end` block to add the action without colliding with `:show`.
- **`app/models/grade.rb`** — `belongs_to :student`, attributes `value` and `date`. Student likely has `name`.
- **Test conventions** — Probably Minitest integration tests under `test/controllers/` or RSpec request specs under `spec/requests/`. Need to look before writing the first test.

## Imagined vs. Discovered (tensions to resolve early)

| Imagined (in Package) | Likely Discovery |
|---|---|
| `CSV.generate(encoding: 'UTF-8', col_sep: ';')` is enough for Brazilian Excel | Excel-BR usually also needs a UTF-8 BOM (`\uFEFF`) prepended or accented names render as mojibake. The Package didn't account for this. |
| `@grades.any?` gates the button | The index action's `@grades` may be paginated or filtered by term — the "any?" check might lie about whether *any* grades exist for the classroom. May need `@classroom.grades.any?` instead. |
| Route is straightforward nested resource | Need to verify whether to add `export_csv` as a `collection` route (likely) vs `member` (no — there's no single grade being exported). |
| "Action bar area for buttons" exists | The view may render a partial; the button may need to live in a partial rather than the page itself for consistency. |

These tensions are small and resolvable in-session — they don't invalidate the appetite.

## First Piece Selection

**First piece**: Wire a downloadable CSV from button click to file save, using a hardcoded two-row CSV in the controller. Real query and formatting come second.

- **Core**: Without "click button → file downloads," nothing else in this Package matters. Encoding, filename, and column choice are all elaborations on this one moment.
- **Small**: Route + controller stub returning a static CSV string + view button linking to it is well under an hour. Builds momentum and resolves all routing/wiring unknowns up front.
- **Novel**: This app has no CSV export today. Doing the dumbest possible version first surfaces the framework conventions (response headers, send_data vs render, route placement) before they're entangled with real query and encoding logic.

After this vertical slice works end-to-end (button → file with two fake rows downloads), I'll layer real grade data, then Brazilian encoding, then the nice-to-have filename.

