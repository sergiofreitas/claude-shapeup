# Package: CSV Export for Grade Reports

**Feature ID**: T01
**Created**: 2026-02-16
**Status**: Shape Go

---

## Problem

Teachers want to download grade reports as CSV files to share with school coordinators who use spreadsheets. Currently the only way to get data out is to manually copy-paste from the screen, which is error-prone and tedious for classes with 30+ students.

## Appetite

**Small Batch: 1 day**

## Requirements (R)

| ID | Requirement | Status |
|----|-------------|--------|
| R0 | Teacher can download a CSV of grades for a classroom | Core goal |
| R1 | CSV includes student name, grade value, and date | Must-have |
| R2 | Download works from the grades index page | Must-have |
| R3 | File is named with classroom and date for easy identification | Nice-to-have |

## Solution

Add a CSV export action to the existing grades controller and a download button on the grades index view.

### Element: Export Controller Action

**What**: Add a `export_csv` action to `GradesController` that queries grades for the classroom and streams a CSV response.
**Where**: `app/controllers/grades_controller.rb`
**Wiring**: Receives `classroom_id` from route params. Loads `@classroom.grades.includes(:student)`. Generates CSV with `CSV.generate`. Sends as `text/csv` with `Content-Disposition: attachment`.
**Affected code**: `app/controllers/grades_controller.rb`, `config/routes.rb`
**Complexity**: Low

### Element: Download Button on Grades Index

**What**: Add a "Download CSV" button to the grades index page, styled as a secondary action.
**Where**: `app/views/grades/index.html.erb`
**Wiring**: Links to `export_csv_classroom_grades_path(@classroom)`. Conditionally shown when grades exist (`@grades.any?`).
**Affected code**: `app/views/grades/index.html.erb`
**Complexity**: Low

## Rabbit Holes

- **Large classrooms**: CSV generation is in-memory. For classrooms up to 50 students × 20 grades = 1000 rows, this is negligible. Streaming not needed within appetite. **Patched**.
- **Character encoding**: Brazilian names with accents. Use `CSV.generate(encoding: 'UTF-8', col_sep: ';')` (semicolon separator is Brazilian Excel convention). **Patched**.

## No-Gos

- No PDF export — CSV only
- No filtering by date range — exports all grades
- No background job — synchronous generation is fine for this scale

## Technical Validation

**Codebase reviewed:**
- `app/controllers/grades_controller.rb` — existing index action loads grades with student includes
- `app/views/grades/index.html.erb` — has an action bar area for buttons
- `config/routes.rb` — grades are nested under classrooms
- `app/models/grade.rb` — has `student` association and `value`, `date` attributes

**Test strategy**: Integration test: request CSV endpoint, assert response content type and CSV content.
