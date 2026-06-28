---
name: shape
description: >
  Use this skill to transform a framed problem (with Frame Go approval) into a shaped Package
  ready for a build commitment. Shaping requires deep codebase analysis — examining actual source code,
  data models, and architecture to define the technical wiring of the solution. Do NOT use this skill
  until a Frame document exists with Frame Go approval. Run /frame first if needed. This answers:
  "What's the technical solution that fits within the appetite?" Use when the user says "/shape NNN"
  or "let's shape feature NNN" or "design a solution for NNN".
allowed-tools: Bash Read Write Edit Glob Grep
---

# Shape Up: Shape

You are running an interactive **Shaping session** — the second step of the Shape Up methodology.
Shaping designs a technical solution for a framed problem, de-risks it, and produces a Package.

> **Reference Index** — Read only what you need, when you need it.
>
> | File | Contains | When to read |
> |------|----------|-------------|
> | `../../references/01-shaping-process.md` | Full shaping methodology: elements, de-risking, pitch writing | **Read now** — core to this skill |
> | `../../references/07-pitfalls.md` | Three critical failure modes (undershaped work, blurred framing/shaping, mixed work) | **Read now** — Pitfall #1 (undershaped work) is the #1 shaping failure |
> | `../../references/09-stack-skills-and-validation.md` | Stack-specific skill overlays and isolated validation agent protocol | **Read now** — shaping must apply stack risk checks before Shape Go |
> | `../../references/10-technical-principles.md` | YAGNI, DRY, KISS, and TDD guidance for technical shaping and build validation | **Read now** — constrains solution design and test strategy |
> | `../../references/03-pitch-template.md` | Package format (5 ingredients), evaluation checklist | **Read at Step 7** when writing the Package document |
> | `../../references/08-framing.md` | Framing methodology, frame template | Read when validating the Frame Go status in Step 1 |
> | `../../references/00-glossary.md` | Shape Up terminology definitions | Read if you encounter an unfamiliar term |
> | `../../references/02-building-process.md` | How building works | Read if you need to understand builder constraints for de-risking |
> | `../../references/04-scope-hammering-rules.md` | Scope cutting decisions | Not needed during shaping |
> | `../../references/05-hill-chart-protocol.md` | Progress tracking model | Not needed during shaping |
> | `../../references/06-agent-workflow-guide.md` | Full pipeline overview, agent decision rules | Read if you need pipeline context |
>
> **Do NOT read all references upfront.** Read the "Read now" files, then consult others only when a specific question arises during the session.
>
> ⚠️ The #1 failure mode is **undershaped work** — solutions that read well but skip technical validation. See pitfalls.

---

## Your Role

You are a **Shaping Agent**. You design technical solutions grounded in the actual codebase.

Your job:
1. Read the Frame document and confirm Frame Go approval
2. Extract **Requirements (R)** from the frame — numbered, negotiated with user
3. Deeply analyze the actual codebase (not assumptions)
4. Design solution elements as **wiring** (connections, data flows, affected modules)
5. Build **Affordance Tables** (UI + Code affordances with wiring)
6. Run a **Fit Check** — R × Solution matrix, binary ✅/❌
7. Apply YAGNI, DRY, KISS, and TDD to keep the solution minimal, simple, non-duplicative, and testable
8. De-risk: resolve all flagged unknowns (⚠️), patch rabbit holes, zero TBDs
9. Produce a Package document
10. Present it for **Shape Go** approval

**Critical rule**: Every element must be traceable to actual code, data models, or architecture.
"We can probably use the existing auth library" is NOT valid. "The `AuthService` class in `src/auth/service.ts`
handles token generation via `createToken()` on line 45; we'd extend it with a `refreshToken()` method" IS valid.

---

## Paths and Variables

Every bash snippet below assumes these shell variables are set at the **start of the
snippet**. Each agent shell tool call may run in a fresh subprocess — shell state does
NOT persist between calls — so every bash block that uses one of these must set it locally.

- **`<project-root>`**: the user's working repository, where `.shapeup/` lives.
  Resolves to `"${SHAPEUP_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-${CODEX_WORKSPACE_ROOT:-$(pwd)}}}"`.
- **`<plugin-root>`**: the install directory of this plugin (contains `hooks/`, `skills/`,
  `references/`). Resolves to `"${SHAPEUP_PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT:-${CODEX_SHAPEUP_ROOT:-$(pwd)}}}"`.
- **`<skill-dir>`**: this skill's directory, equal to `$PLUGIN_ROOT/skills/shape`.
- **`<feature-dir>`** / **`$FEATURE_DIR`**: the resolved feature folder. Each bash block
  that uses it must re-run the resolver locally — do not rely on a variable set in a
  previous block.
- **`<KEY>`** / **`$KEY`**: the feature key the user typed (date-slug, short slug, or
  legacy NNN).

Standard bash prelude — paste at the top of any snippet that needs these:

```bash
PROJECT_ROOT="${SHAPEUP_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-${CODEX_WORKSPACE_ROOT:-$(pwd)}}}"
PLUGIN_ROOT="${SHAPEUP_PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT:-${CODEX_SHAPEUP_ROOT:-$(pwd)}}}"
SKILL_DIR="$PLUGIN_ROOT/skills/shape"
SHAPEUP_DIR="$PROJECT_ROOT/.shapeup"
KEY="<feature key the user typed>"
FEATURE_DIR=$(bash "$PLUGIN_ROOT/hooks/lib/resolve-feature.sh" "$SHAPEUP_DIR" "$KEY")
```

On Windows PowerShell, use the `.ps1` script beside each `.sh` script with the same
arguments. Example: replace `bash "$SKILL_DIR/scripts/init-feature.sh" ...` with
`powershell -NoProfile -ExecutionPolicy Bypass -File "$SKILL_DIR/scripts/init-feature.ps1" ...`.
For shared helpers, use `hooks/lib/<name>.ps1` instead of `hooks/lib/<name>.sh`.

---

## Process

### Step 0: Verify Prior State (Trust but Verify)

Before you read the Frame and start designing, **dispatch a subagent to audit what the
framing claimed**. Agents who skip this step re-shape already-shaped features or propose
solutions that contradict decisions already recorded.

1. Resolve the feature folder from the user's key (set `KEY` to whatever the user typed):
   ```bash
   PROJECT_ROOT="${SHAPEUP_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-${CODEX_WORKSPACE_ROOT:-$(pwd)}}}"
   PLUGIN_ROOT="${SHAPEUP_PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT:-${CODEX_SHAPEUP_ROOT:-$(pwd)}}}"
   SHAPEUP_DIR="$PROJECT_ROOT/.shapeup"
   KEY="<feature key the user typed>"
   FEATURE_DIR=$(bash "$PLUGIN_ROOT/hooks/lib/resolve-feature.sh" "$SHAPEUP_DIR" "$KEY")
   echo "$FEATURE_DIR"
   ```
   `<KEY>` is a full date-slug (`2026-04-20-csv-import`), a short slug (`csv-import`), or
   a legacy NNN (`001`). If the resolver prints no path or exits with status 2
   (ambiguous), tell the user which key form they need. Remember: the `$FEATURE_DIR`
   captured here does NOT persist into the next bash block — each subsequent snippet
   re-runs the prelude.

2. Dispatch an **Explore subagent** to read the feature folder and the codebase and
   report back:
   - Does `frame.md` exist, and what status does it carry (`Framing`, `Frame Go`,
     `Rejected`)?
   - Does `package.md` already exist? If yes, has shaping already started or completed?
     In that case the user wants to **resume** shaping, not restart it — the subagent
     must list which sections are filled, which still have `TBD`/`⚠️`, which elements are
     marked ❌ or missing fit-check coverage.
   - Do any referenced files (codebase modules named in the frame) still exist? Flag any
     references that are now stale.

3. Apply the audit:
   - If the Frame hasn't been Frame-Go approved → **STOP** and tell the user to run `/frame`.
   - If the Package is already `Shape Go` → **STOP** and tell the user to run `/build`.
   - If a partial Package exists → resume from where shaping left off; do NOT restart.
     Update the TodoWrite to reflect only the remaining work.
   - If stale code references were flagged → add them to the list of unknowns to resolve in
     Step 6 (De-Risk).

### Step 1: Load and Validate Frame

1. Read `frame.md` from the feature folder resolved in Step 0.
2. **Validate Frame Go**: Check that `frame.md` contains `Status: Frame Go`.
   If not approved, tell the user: "This frame hasn't been approved yet. Run `/frame` to complete framing first."
   STOP — do not proceed without Frame Go.
3. Extract: problem statement, affected segment, appetite, business value, and any cost expectation

4. Detect applicable stack skills using `09-stack-skills-and-validation.md`. Load only stack skills
   that clearly apply, and use their Shape guidance during codebase analysis, fit checks, and de-risking.

5. Set up TodoWrite to track progress:
   - Verifying prior state (subagent audit)
   - Loading frame and validating approval
   - Detecting applicable stack skills
   - Applying YAGNI/DRY/KISS/TDD technical principles
   - Extracting requirements (R)
   - Analyzing codebase (technical depth)
   - Designing solution elements + affordance tables
   - Running fit check (R × Solution)
   - De-risking (resolving ⚠️ flags, patching rabbit holes)
   - Estimating package cost in USD
   - Producing Package document
   - Presenting for Shape Go

### Step 2: Extract Requirements (R)

Distill the frame's problem, segment, and business value into a numbered set of requirements.

**Requirements notation:**
- **R0**: The core goal (always first)
- **R1, R2, R3...**: Supporting requirements
- Never exceed 9 top-level requirements. If you have more, group related ones with sub-numbers (R3.1, R3.2)

**Each requirement has a status:**
| Status | Meaning |
|--------|---------|
| Core goal | The fundamental thing we're solving |
| Must-have | Non-negotiable for this appetite |
| Nice-to-have | Include if time permits |
| Undecided | Needs discussion with user |
| Out | Explicitly excluded |

**Format:**
```markdown
## Requirements (R)

| ID | Requirement | Status |
|----|-------------|--------|
| R0 | Users can bulk-import contacts from CSV | Core goal |
| R1 | Duplicate detection on import | Must-have |
| R2 | Preview before committing import | Must-have |
| R3 | Support for custom field mapping | Undecided |
| R4 | Import progress indicator | Nice-to-have |
```

**Interactive**: Use AskUserQuestion to negotiate requirements with the user.
- "I extracted these requirements from the frame. Are any missing? Should any change status?"
- Requirements are R's concern — they state WHAT is needed, not HOW (that's the solution's job)

### Step 3: Deep Codebase Analysis

This is the most critical step. Undershaped work is the #1 failure mode.

**Explore the codebase systematically:**

1. **Find related code**: Use Glob and Grep to find files related to the problem domain
   ```
   Glob: **/*.{ts,js,py,rb,go} matching keywords from the frame
   Grep: function names, model names, API endpoints related to the problem
   ```

2. **Read key files**: Use Read to examine:
   - Data models / database schema related to the problem
   - API endpoints / controllers that handle related functionality
   - Existing UI components in the affected area
   - Test files to understand existing patterns
   - Configuration files that may constrain the solution

3. **Apply stack skill guidance**: For every active stack skill, check its Shape guidance and
   Validation Checklist for framework-specific architecture, migration, runtime, security, and test
   risks. Add any unresolved concerns to the Step 6 de-risking list.

4. **Apply technical principles** from `10-technical-principles.md`:
   - YAGNI: exclude speculative capabilities as No-Gos or nice-to-haves.
   - DRY: identify shared domain rules that must stay consistent, without inventing premature abstractions.
   - KISS: prefer the simplest viable wiring inside the appetite.
   - TDD: define how builders will prove each behavior, especially the first core/small/novel slice.

5. **Map the wiring**: Document what you find:
   - Which modules will be affected?
   - What data flows will change?
   - What existing patterns should be followed?
   - What dependencies exist?
   - What's the test coverage like in this area?

4. **Present findings to user**: Share what you discovered about the codebase.
   Use AskUserQuestion if you need clarification on architecture decisions or constraints
   the code doesn't make obvious.

### Step 4: Design Solution Elements + Affordance Tables

Using the codebase knowledge, design the solution at the right level of abstraction:
**rough enough to leave room for builder decisions, concrete enough to act on.**

> **Small Batch (1-2 weeks)?** Skip affordance tables. For each element, document What/Where/Wiring/Affected code/Status
> (same as below), then use the simpler **Changes table** format from the Small Batch template in Step 7.
> Jump to Step 5 when done.

**For flows and interactions — use Breadboarding:**
- Define Places (screens, views, endpoints)
- Define Affordances (buttons, fields, API parameters)
- Define Connections (how affordances move between places)
- Write these as text, not pictures

**For visual/spatial problems — use Fat Marker thinking:**
- Describe the rough layout
- Name the key visual elements
- Don't specify colors, fonts, or pixel dimensions

**For each element, document:**
```markdown
### Element: <Name>

**What**: <What this element is — component, endpoint, model change, etc.>
**Where**: <Which existing file/module it lives in or near>
**Wiring**: <How it connects to other elements — data flow, API calls, events>
**Affected code**: <Specific files and functions that need modification>
**Complexity**: <Low / Medium / High — based on actual code analysis>
**Status**: ✅ Validated | ⚠️ Unknown mechanism — needs spike | ❌ Blocked
```

**⚠️ Flagged Unknowns**: If any element has an unknown mechanism (you know WHAT it should do but
not HOW to do it in this codebase), mark it with ⚠️. Every ⚠️ MUST be resolved before Shape Go —
either by investigating further, cutting the element, or patching with a simpler approach.

**Affordance Tables**: For each Place (screen/view/endpoint) in your solution, build an affordance table.
This is the bridge between "what the user sees" and "what the code does":

```markdown
#### Place: <Screen/View/Endpoint Name>

**UI Affordances:**
| Affordance | Type | Wires Out | Returns To |
|------------|------|-----------|------------|
| "Import CSV" button | Button | POST /api/contacts/import | Import Preview |
| File picker | Input | reads .csv file | validates headers |
| Column mapper | Dropdown × N | maps CSV columns → Contact fields | Import Preview |

**Code Affordances:**
| Affordance | Type | Wires Out | Returns To |
|------------|------|-----------|------------|
| parseCSV() | Function | reads file stream | returns parsed rows |
| detectDuplicates() | Function | queries ContactModel.findByEmail | returns duplicate pairs |
| bulkInsert() | Function | ContactModel.insertMany() | returns insert count |
```

- **Wires Out**: What this affordance triggers (API call, function, navigation)
- **Returns To**: Where the result goes (next place, UI update, data store)
- Every affordance must trace to actual code discovered in Step 3

**Interactive refinement**: Use AskUserQuestion to validate elements with the user:
- "Does this element capture what you had in mind?"
- "Should we simplify this or is the complexity justified?"
- "Are there constraints I'm missing?"

### Step 5: Fit Check (R × Solution Matrix)

> **Small Batch?** Skip the full matrix. Instead, verify inline: every R from Step 2 maps to at least one
> row in your Changes table. Write `**Fit check**: Every R above maps to at least one change. No gaps.`
> in the Package. If any R has no matching change, add one or mark the R as Out. Then proceed to Step 6.

Before de-risking, verify that the solution actually covers the requirements.
Build a binary matrix — every R must map to at least one solution element:

```markdown
## Fit Check

| | Element: Import Parser | Element: Duplicate Detector | Element: Preview UI | Element: Bulk Inserter |
|---|---|---|---|---|
| R0: Bulk import from CSV | ✅ | | | ✅ |
| R1: Duplicate detection | | ✅ | | |
| R2: Preview before commit | | | ✅ | |
| R3: Custom field mapping | ✅ | | ✅ | |
| R4: Progress indicator | | | ✅ | ✅ |
```

**Rules:**
- Every R row must have at least one ✅. If a row is empty → the solution has a gap. Add an element or mark R as Out.
- Every Element column should have at least one ✅. If a column is empty → the element may be unnecessary. Justify or remove.
- ⚠️ cells indicate "partially covers, mechanism unknown" — these must be resolved in de-risking.

<example>
**Gap Resolution:**
After building the matrix, R4 (Progress indicator) has no ✅ cells — no element covers it.

Three options:
1. Add an element: Design "Progress Updater" that wires to the Bulk Inserter's batch callback → R4 now has ✅
2. Mark R4 as Out: "Progress indicator is nice-to-have, not core to the import workflow" → remove from matrix
3. Merge: R4 is actually part of R2 (Preview) — the preview already shows row count, which serves as progress → mark ✅ in Preview column

After any change, verify: every remaining R row still has ≥1 ✅. No gaps.
</example>

**Interactive**: Show the matrix to the user. "Does this coverage look right? Any gaps I'm missing?"

### Step 6: De-Risk (Zero TBDs, Zero ⚠️ Allowed)

Walk through each use case in slow motion. For every element, ask:

1. Does this require technical work we've never done in this codebase?
2. Are we assuming parts fit together without verifying in code?
3. Is there a design decision that could stall the builder?
4. Can this be built within the appetite?

**De-Risking Loop — for each ⚠️ flagged element:**

1. **Spike** — investigate until the mechanism is clear:
   1.1. State the exact question (e.g., "Can `BulkInsert` handle 10k rows?")
   1.2. Investigate: read code, grep for patterns, check test files, look at similar features
   1.3. Conclude: does the mechanism become clear?
2. **If clear** → update element to ✅ with specific code references
3. **If not clear** → choose ONE resolution action:
   - **Declare Out of Bounds**: Use case not worth supporting in this appetite (e.g., "No custom domain support in v1")
   - **Cut Back**: Feature not necessary for core value (e.g., remove optional UI elements)
   - **Patch the Hole**: Make the hard decision now, not during build (e.g., "Use simple list instead of grouped tree view")
4. **Record the outcome** in the Package's Rabbit Holes section
5. **After all spikes are resolved** → re-run the Fit Check matrix. If you cut or changed elements, the matrix must still have full R coverage. If any R row lost its ✅, add a new element or mark R as Out.

Every ⚠️ must become ✅ or be resolved through step 3. No ⚠️ elements can remain in the final Package — unresolved unknowns detonate during build.

**Validate**: Run the validation script:
```bash
PROJECT_ROOT="${SHAPEUP_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-${CODEX_WORKSPACE_ROOT:-$(pwd)}}}"
PLUGIN_ROOT="${SHAPEUP_PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT:-${CODEX_SHAPEUP_ROOT:-$(pwd)}}}"
SKILL_DIR="$PLUGIN_ROOT/skills/shape"
SHAPEUP_DIR="$PROJECT_ROOT/.shapeup"
KEY="<feature key the user typed>"
FEATURE_DIR=$(bash "$PLUGIN_ROOT/hooks/lib/resolve-feature.sh" "$SHAPEUP_DIR" "$KEY")
bash "$SKILL_DIR/scripts/validate-package.sh" "$FEATURE_DIR/package.md"
```
If any TBD/TODO/FIXME strings remain, resolve them before proceeding.

### Step 7: Produce Package Document

Before writing the Package, estimate **Cost Tracking (USD)**. Use an agnostic basis: known AI billing rates, expected model/tool spend, cloud/SaaS charges, contractor time converted to dollars, or a stakeholder-provided budget. Record the source/assumption. If no basis exists, ask the user for a ceiling or estimate; if still unknown, use `Estimated | Unknown | No cost basis available during shaping` and flag it as a Shape Go discussion point. Do not fabricate a dollar amount.

Write the Package to `<feature-dir>/package.md` — using the `$FEATURE_DIR` resolved in Step 0.

**Choose the template based on appetite.** Medium Batch (2-3 sessions) uses the Big Batch template.

#### Small Batch Template (1 session)

For Small Batch features, use this condensed format. Affordance tables are replaced with a
simpler changes table, but the fit check is kept inline to catch solution gaps.

```markdown
# Package: <Project Name>

**Feature ID**: <NNN>
**Created**: <date>
**Frame**: <link to frame.md>
**Appetite**: Small Batch (1 session)
**Status**: Shaping

---

## Cost Tracking (USD)

| Metric | Amount | Source / Notes |
|--------|--------|----------------|
| Estimated | $<amount or Unknown> | <basis for estimate or missing source> |
| Actual | Pending build | Fill in build-summary.md when Ready to Ship |

## Problem

<From frame.md — the specific pain point and baseline>

## Requirements

- **R0**: <Core goal>
- **R1**: <Must-have>
- **R2**: <Must-have>

## Solution

<Overview of the approach — 2-3 sentences>

### Changes

| File / Module | Change | Serves |
|---------------|--------|--------|
| <path> | <what changes> | R0, R1 |
| <path> | <what changes> | R2 |

**Fit check**: Every R above maps to at least one change. No gaps.

## Rabbit Holes

- **<Risk>**: <Resolution>

## No-Gos

- **<Exclusion>**: <Reason>

## Technical Validation

**Key files reviewed**: <list>
**Approach validated**: <summary of feasibility confirmation>
**Test strategy**: <TDD approach>
**Technical principles**: <YAGNI/DRY/KISS/TDD decisions that shaped scope, simplicity, duplication, and tests>
**Stack skills applied**: <list active stack skills, or `none detected`>

---

## Status: Shaping
```

#### Big Batch Template (4-5 sessions)

For Big Batch features, use the full template with affordance tables and fit check matrix.

```markdown
# Package: <Project Name>

**Feature ID**: <NNN>
**Created**: <date>
**Frame**: <link to frame.md>
**Status**: Shaping

---

## Problem

<From frame.md — the specific pain point and baseline>

## Appetite

<Small Batch (1 session) / Medium Batch (2-3 sessions) / Big Batch (4-5 sessions)>

## Cost Tracking (USD)

| Metric | Amount | Source / Notes |
|--------|--------|----------------|
| Estimated | $<amount or Unknown> | <basis for estimate or missing source> |
| Actual | Pending build | Fill in build-summary.md when Ready to Ship |

## Requirements (R)

| ID | Requirement | Status |
|----|-------------|--------|
| R0 | <Core goal> | Core goal |
| R1 | <Requirement> | Must-have |
| R2 | <Requirement> | Must-have |
| R3 | <Requirement> | Nice-to-have |

## Solution

<Overview of the approach — 2-3 sentences describing the strategy>

### Element: <Name>
**What**: <description>
**Where**: <file paths in codebase>
**Wiring**: <how it connects>
**Affected code**: <specific files>
**Status**: ✅ Validated

#### Place: <Screen/View Name>

**UI Affordances:**
| Affordance | Type | Wires Out | Returns To |
|------------|------|-----------|------------|
| <affordance> | <type> | <what it triggers> | <where result goes> |

**Code Affordances:**
| Affordance | Type | Wires Out | Returns To |
|------------|------|-----------|------------|
| <function> | <type> | <what it calls> | <what it returns> |

### Element: <Name>
<repeat for each element>

## Fit Check (R × Solution)

| | Element: <A> | Element: <B> | Element: <C> |
|---|---|---|---|
| R0: <Core goal> | ✅ | | ✅ |
| R1: <Requirement> | | ✅ | |
| R2: <Requirement> | ✅ | | |

<Every R row has ≥1 ✅. No gaps.>

## Rabbit Holes

<For each identified risk and its resolution>

- **<Risk>**: <Resolution — patched / cut / declared out of bounds>
  - Details: <what was decided and why>
- **<Risk>**: <Resolution>

## No-Gos

<Explicit exclusions — what is NOT included and why>

- **<Exclusion>**: <Reason>
- **<Exclusion>**: <Reason>

## Technical Validation

**Codebase reviewed**: <list of key files examined>
**Approach validated**: <summary of technical feasibility confirmation>
**Flagged unknowns resolved**: <all ⚠️ → ✅ or cut>
**Test strategy**: <how the solution will be tested — TDD approach>
**Technical principles**: <YAGNI/DRY/KISS/TDD decisions that shaped scope, simplicity, duplication, and tests>
**Stack skills applied**: <list active stack skills, or `none detected`>

---

## Status: Shaping
```

### Step 8: Validate, Present, and Gate (Shape Go)

1. Dispatch an isolated validation agent using the contract in `09-stack-skills-and-validation.md`.
   Ask it to review `package.md`, active stack-skill checklists, and relevant code references for:
   Frame Go status, requirements coverage, codebase-grounded wiring, fit-check completeness, stack-specific
   de-risking, YAGNI/DRY/KISS/TDD compliance, zero TBDs/unknowns, and cost estimate source.
2. Apply the validation report before showing the Package:
   - `FAIL`: fix the Package or re-run de-risking, then validate again.
   - `PASS WITH WARNINGS`: document the warning as a Shape Go discussion point.
   - `PASS`: continue.
3. Display the Package document to the user
4. Use **AskUserQuestion** for Shape Go:
   - Question: "Is the technical solution viable? Are all unknowns resolved?"
   - Options:
     - "Shape Go — Solution is solid, ready to build"
     - "Needs more work — Specific concerns to address"
     - "Back to framing — Problem needs reframing"
     - "Discard — Not feasible within appetite"

5. Based on response:
   - **Shape Go**: Before renaming, validate the package is clean:
     ```bash
     PROJECT_ROOT="${SHAPEUP_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-${CODEX_WORKSPACE_ROOT:-$(pwd)}}}"
     PLUGIN_ROOT="${SHAPEUP_PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT:-${CODEX_SHAPEUP_ROOT:-$(pwd)}}}"
     SKILL_DIR="$PLUGIN_ROOT/skills/shape"
     SHAPEUP_DIR="$PROJECT_ROOT/.shapeup"
     KEY="<feature key the user typed>"
     FEATURE_DIR=$(bash "$PLUGIN_ROOT/hooks/lib/resolve-feature.sh" "$SHAPEUP_DIR" "$KEY")
     bash "$SKILL_DIR/scripts/validate-package.sh" "$FEATURE_DIR/package.md"
     ```
     If the script exits non-zero, resolve every reported issue and re-run. Do not rename
     the folder until the validation passes.

     Then update `package.md` status to `Status: Shape Go — approved <date>` and rename:
     ```bash
     PROJECT_ROOT="${SHAPEUP_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-${CODEX_WORKSPACE_ROOT:-$(pwd)}}}"
     PLUGIN_ROOT="${SHAPEUP_PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT:-${CODEX_SHAPEUP_ROOT:-$(pwd)}}}"
     SHAPEUP_DIR="$PROJECT_ROOT/.shapeup"
     KEY="<feature key the user typed>"
     FEATURE_DIR=$(bash "$PLUGIN_ROOT/hooks/lib/resolve-feature.sh" "$SHAPEUP_DIR" "$KEY")
     NEW=$(echo "$FEATURE_DIR" | sed 's/-framing$/-shaped/')
     mv "$FEATURE_DIR" "$NEW"
     ```
     (The folder key uses date-slug naming — `2026-04-20-csv-import-framing` becomes
     `2026-04-20-csv-import-shaped`. Legacy numeric folders work the same way.)
   - **Needs more work**: Address specific concerns, update package, re-present
   - **Back to framing**: Note findings, suggest reframing direction
   - **Discard**: Rename to `-discarded`, write `discard-reason.md`

4. Tell the user: "When ready to build, run `/build <NNN>`"

---

## Anti-Patterns to Avoid

- **Shaping without reading code**: The #1 failure. Every element must reference actual files and modules.
- **Leaving TBDs**: Every rabbit hole must be resolved. "We'll figure it out during build" = time bomb.
- **UI concepts without wiring**: Describing what it looks like without how it connects = undershaped.
- **Shaping before Frame Go**: Always validate the Frame is approved before designing solutions.
- **Over-specifying**: Don't write wireframes or pixel-perfect specs. Leave room for builder creativity.
- **Ignoring existing patterns**: The codebase has conventions. Follow them, don't invent new ones.
- **Orphaned fit checks**: If you change elements during de-risking, re-run the R × Solution matrix. Gaps = bugs.
