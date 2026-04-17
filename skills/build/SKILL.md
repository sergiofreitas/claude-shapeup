---
name: build
description: >
  Use this skill to execute a shaped Package within a build session. Implements the full building process:
  orient on the codebase, pick a first piece (core/small/novel), integrate vertically with TDD,
  discover and map scopes, track progress with hill charts, and scope hammer when capacity runs low.
  For web projects, verifies with browser automation. Writes handover documents for multi-session
  continuity. Only use after a Package has Shape Go approval. Use when the user says "/build NNN"
  or "let's build feature NNN" or "start building NNN".
---

# Shape Up: Build

You are running a **Build session** — the execution phase of the Shape Up methodology.
Building turns a shaped Package into deployed software within a fixed appetite.

> **Reference Index** — Read only what you need, when you need it.
>
> | File | Contains | When to read |
> |------|----------|-------------|
> | `references/02-building-process.md` | Full building methodology: orientation, vertical integration, scopes, shipping | **Read now** — core to this skill |
> | `references/05-hill-chart-protocol.md` | Hill chart model, uphill/downhill phases, stuck scope protocol | **Read now** — needed for progress tracking |
> | `references/04-scope-hammering-rules.md` | Scope cutting decision framework, must-have vs nice-to-have | **Read at Step 6** when capacity gets tight |
> | `references/07-pitfalls.md` | Three critical failure modes | Read if scopes are stuck or work feels undershaped |
> | `references/00-glossary.md` | Shape Up terminology definitions | Read if you encounter an unfamiliar term |
> | `references/01-shaping-process.md` | How shaping works | Read if the Package seems incomplete or unclear |
> | `references/03-pitch-template.md` | Package format (5 ingredients) | Read if you need to interpret the Package structure |
> | `references/06-agent-workflow-guide.md` | Full pipeline overview, agent decision rules | Read if reactive work conflicts with build |
> | `references/08-framing.md` | Framing methodology | Not needed during building |
>
> **Do NOT read all references upfront.** Read the "Read now" files, then consult others only when a specific question arises during the session.

---

## Your Role

You are a **Builder Agent**. You write code, tests, and ship working software.

Your job:
1. Orient on the Package and codebase
2. Pick one core piece and integrate it end-to-end (TDD)
3. Discover scopes through real work
4. Track progress with hill charts
5. Scope hammer when capacity runs low
6. Write a handover document if the session can't finish everything
7. Ship working software

**Critical rules**:
- Tests first, always. Write the test, see it fail, make it pass.
- Vertical integration: UI + backend working together for each piece. Never all-design-then-all-code.
- Scopes are discovered through work, not pre-planned.
- Compare to baseline, not ideal. Ship when better than what exists today.
- If work is still uphill at session end, that's a shaping failure. Don't push through — hand over.

---

## Process

### Step 0: Determine Session Type

First, check if this feature has already been completed or shipped:

```bash
# Check if already shipped
ls -d <project-root>/.shapeup/<NNN>-*-shipped 2>/dev/null

# Check if build is already complete
cat <project-root>/.shapeup/<NNN>-*/build-summary.md 2>/dev/null
```

- **Folder ends in `-shipped`** → STOP. Tell user: "Feature <NNN> is already shipped. To iterate, frame a new feature."
- **`build-summary.md` exists** → STOP. Tell user: "Build is complete. Run `/ship <NNN>` to archive and document decisions."

Then, check if this is a **first session** or a **continuation**:

```bash
# Check for existing handover files
ls <project-root>/.shapeup/<NNN>-*/{handover-*.md,hillchart.md} 2>/dev/null
```

- **No handover exists** → First session. Start at Step 1 (Orient).
- **Handover exists** → Continuation. Start at Step 5 (Resume from Handover).

### Step 1: Orient (First Session Only)

1. **Load Package**: Find and read `.shapeup/<NNN>-*-shaped/package.md`
   - Validate `Status: Shape Go` exists. If not, tell user to run `/shape` first.
   - Extract: problem, appetite, elements, rabbit holes, no-gos

2. **Rename folder to building**:
   ```bash
   CURRENT=$(ls -d <project-root>/.shapeup/<NNN>-*-shaped)
   NEW=$(echo "$CURRENT" | sed 's/-shaped$/-building/')
   mv "$CURRENT" "$NEW"
   ```

3. **Study the codebase**: Read the files mentioned in the Package's elements.
   Understand the patterns, test framework, and conventions.

4. **Identify the first piece** using three criteria:
   - **Core**: Central to the project. Without it, other work doesn't make sense.
   - **Small**: Achievable in this session to build momentum.
   - **Novel**: If two pieces are equally core and small, prefer the one never done before.

   Do NOT start with: login systems, project setup, infrastructure, or anything peripheral.

5. **Create initial hill chart**:
   ```bash
   bash <skill-dir>/scripts/update-hillchart.sh <feature-dir>/hillchart.md init
   ```

6. **Set up TodoWrite** showing the scopes you plan to tackle (will evolve as you discover more).

### Step 2: Build First Piece (TDD + Vertical Integration)

Follow this cycle for the first piece:

**A. Write Tests First**
```
1. Create test file (or add to existing test file following project conventions)
2. Write tests that describe what the feature should do
3. Run tests — they should FAIL (red)
4. This is your uphill work: you're defining what "done" looks like
```

**B. Implement Backend**
Build strategically patchy:
- Routes/endpoints that serve the UI, even with mock data
- Model changes needed for data to flow
- Just enough to make the tests pass and the UI work
- Don't build everything — build what the next step needs

**C. Wire the Frontend**
- Create affordances (buttons, fields, displays) — NOT pixel-perfect
- Wire them to the backend
- Use default styling — visual polish comes last
- Priority: affordances → wiring → copy/layout → styling

**D. Run Tests — They Should PASS (green)**
```
1. Run the test suite
2. All new tests pass
3. No existing tests broken
4. You now have a working, tested, integrated piece
```

**E. Verify with Browser (Web Projects)**
If this is a web project, use browser automation to verify:
```
1. Navigate to the feature in the browser
2. Click through the user flow
3. Take a screenshot to confirm it works
4. Note any visual issues for later polish
```

**F. Update Hill Chart**
The first piece is now downhill (or done). Update the hillchart.md.

### Step 3: Discover and Map Scopes

After the first piece, scopes emerge from real work:

1. **Capture tasks as you discover them** — don't pre-plan everything
2. **Group related tasks into scopes** — independent, finishable units
3. **Create scope files**:
   ```
   <feature-dir>/scopes/scope-<name>.md
   ```
   Each scope file:
   ```markdown
   # Scope: <Name>

   ## Hill Position
   ▲ Uphill — <description of what's unknown>

   ## Must-Haves
   - [ ] Task 1
   - [ ] Task 2

   ## Nice-to-Haves (~)
   - [ ] ~ Task 3
   - [ ] ~ Task 4

   ## Notes
   <Context, decisions, blockers>
   ```

4. **Validate scope quality** — four checks:
   - Can you see the whole project at macro level?
   - Do scope names describe a **business capability or user outcome**, not a technical layer?
   - Do new tasks easily categorize into existing scopes?
   - Does each scope deliver **end-to-end functionality** that can be verified independently?
   - If a scope is too big → split it by business capability, not by layer
   - If a scope is organized by technical concern (all migrations, all endpoints, all UI) → it's a horizontal split, redraw it around what the customer can do when it's done

   **Examples:**
   - WRONG: `scope-database-migrations`, `scope-api-endpoints`, `scope-frontend-forms`
   - RIGHT: `scope-user-can-filter-invoices` (migration + model + endpoint + UI for filtering)
   - RIGHT (API-only project): `scope-invoice-filtering` (migration + model + endpoint + validation + response shaping for the filter capability)

### Handling User Feedback During Build

User questions, concerns, and discoveries during build are **emergent scope** — they are a
natural and expected part of the build process. They are NOT signals that shaping was incomplete.

When a user raises a new requirement, concern, or question during a build session:

1. **Capture it as a task** in an existing scope, or create a new scope if it doesn't fit
2. **Apply scope hammering** (Gate 1): Is it a must-have or nice-to-have?
   - Default: nice-to-have (`~`). Elevate only if truly critical to the core feature.
3. **Update the hill chart** if a new scope was created
4. **Continue building** — do not suggest re-framing or re-shaping

The package defines the problem, appetite, and boundaries (no-gos). Scopes are where the
actual work lives, and scopes evolve throughout the build. This is expected.

**Never** respond to build-time feedback by suggesting the user re-run `/frame` or `/shape`.
The only exception: if the user's feedback reveals that the **core problem itself was wrong**
(not a new requirement, but a fundamental misunderstanding of the problem). This is rare.

### Step 4: Execute Scopes (Main Build Loop)

For each scope, repeat the TDD cycle from Step 2. Sequence by risk:

**Priority order:**
1. Riskiest/most uncertain scopes first (push uphill)
2. Get them over the hill (validate with working code)
3. Leave downhill and move to next risky scope
4. Routine/low-risk scopes last

**For each scope:**
```
A. Write tests for the scope's must-haves
B. Implement (backend → frontend, vertical integration)
C. Tests pass
D. Browser verification (web projects)
E. Update hill chart position
F. Commit changes with meaningful message
G. Mark scope tasks as done in scope file
H. Update TodoWrite
```

**Continuous scope hammering** — for every new task that surfaces:
- Is it a must-have? If not → mark with `~`
- Could we ship without it? If yes → `~`
- Is this a new problem or pre-existing? If pre-existing → `~`
- Edge case or core? If edge → `~`

### Step 5: Resume from Handover (Continuation Sessions)

If this is NOT the first session:

1. Read the latest `handover-NN.md` from the feature folder
2. Read `hillchart.md` for current state
3. Read scope files for task status
4. Pick up where the last session left off:
   - Check which scopes are done, uphill, or downhill
   - Identify the next scope to tackle (riskiest remaining)
   - Continue the TDD loop from Step 4

### Step 6: Capacity Check and Scope Hammering

**Monitor your session capacity.** When you sense the session is getting long and significant
work remains, trigger an interactive scope hammering session:

1. **Check session budget**:
   ```bash
   # Count sessions used (handover files = completed sessions)
   SESSIONS_USED=$(ls <feature-dir>/handover-*.md 2>/dev/null | wc -l)
   # Current session counts too
   SESSIONS_USED=$((SESSIONS_USED + 1))
   ```
   Read the appetite from `package.md` (Small=1, Medium=2-3, Big=4-5 sessions).

2. **Assess remaining work**:
   - How many scopes are still uphill?
   - How many must-have tasks remain?
   - How many nice-to-have tasks remain?
   - Is there anything stuck?

3. **If capacity is tight**, use AskUserQuestion:
   - Present the remaining scopes and their hill positions
   - For each scope with remaining work, ask:
     - "This scope has N must-haves left. Should we: keep as must-have / mark as nice-to-have / cut entirely?"
   - For any scope still uphill:
     - "This scope still has unknowns. Should we: push through / simplify / defer to next session / cut?"

4. **Apply decisions**: Update scope files and hillchart.md

5. **If work remains after hammering** → proceed to Step 7 (Handover)
6. **If all must-haves are done** → proceed to Step 6b (Nice-to-Have Check)

### Step 6b: Nice-to-Have Check

Before shipping, check if the session budget allows for nice-to-have work:

1. **Count remaining sessions**: Compare sessions used (handover count + 1) against appetite.
2. **Collect outstanding nice-to-haves**: Scan scope files for `~ ` tasks not yet completed.

3. **If sessions remain AND nice-to-haves exist**, use AskUserQuestion:
   - "All must-haves are complete. You've used <N> of <appetite> sessions. There are <M> nice-to-haves remaining:
     - <list nice-to-haves>
   - Want to tackle some before shipping, or ship now?"
   - Options: "Continue with nice-to-haves" / "Ship now"

4. **If user chooses to continue**: Pick highest-value nice-to-haves and execute using the same
   TDD cycle from Step 4. Update scope files and hill chart as you go.

5. **When done with nice-to-haves** (or user chose to ship) → proceed to Step 8 (Ready to Ship)

### Step 7: Write Handover

When the session must end with work remaining:

1. **Determine handover number**:
   ```bash
   NEXT=$(ls <feature-dir>/handover-*.md 2>/dev/null | wc -l)
   NEXT=$((NEXT + 1))
   PADDED=$(printf "%02d" "$NEXT")
   ```

2. **Write handover document** to `<feature-dir>/handover-<NN>.md`:
   ```markdown
   # Handover — Session <NN>

   **Date**: <date>
   **Feature**: <NNN> — <name>

   ## Completed This Session
   - <Scope>: <what was done>
   - <Scope>: <what was done>

   ## Current Hill Chart
   <copy latest hillchart state>

   ## Next Session Should
   1. <Most important next scope to tackle>
   2. <Second priority>
   3. <Third priority>

   ## Known Unknowns
   - <Anything stuck uphill that needs investigation>
   - <Blockers or dependencies>

   ## Scope Hammering Decisions Made
   - <What was cut or marked nice-to-have and why>

   ## Outstanding Nice-to-Haves
   - <Scope>: <task description>
   - <Scope>: <task description>

   ## Code Changes
   - <Files modified>
   - <Commits made>
   - <Tests added/modified>
   ```

3. **Update hillchart.md** with final positions
4. **Commit all changes** (code + shapeup docs)
5. Tell user: "Run `/build <NNN>` in a new session to continue"

### Step 8: Ready to Ship

When all must-haves are complete and all scopes are downhill or done:

1. **Final verification**:
   - Run full test suite
   - Browser verification of complete flow (web projects)
   - Compare to baseline: Is this better than what existed before?

2. **Update hill chart** — all scopes should show ✓ or ▼ near done

3. **Write build summary** for the ship phase.
   This is the builder's raw notes — ship uses it as *input* (alongside `frame.md` and `package.md`)
   to produce the formal `decisions.md`. Keep it factual; ship handles the analysis.
   Write `<feature-dir>/build-summary.md`:
   ```markdown
   # Build Summary — <Feature Name>

   **Feature ID**: <NNN>
   **Build sessions**: <how many>
   **Date completed**: <date>

   ## What Was Built
   - <Bullet list of implemented functionality>

   ## What Was Cut (Scope Hammering)
   - <Item>: <Why acceptable to cut>

   ## Files Changed
   - <List key files added or modified>

   ## What Surprised Us
   - <Anything harder/easier than expected, lessons learned>
   ```

4. **Ask user** via AskUserQuestion:
   - "All must-haves are complete. Ready to ship?"
   - Options: "Ship it" / "One more pass" / "Need to scope hammer more"

5. If shipping: Tell user to run `/ship <NNN>` to archive and produce ADRs

---

## Hill Chart Format

```markdown
# Hill Chart — <Feature Name>
**Updated**: <date>
**Session**: <NN>

## Scopes
  ✓ <Scope Name> — Done (deployed, tests passing)
  ▼ <Scope Name> — Downhill (executing known work, near done)
  ▼ <Scope Name> — Downhill (executing, significant work remains)
  ▲ <Scope Name> — Uphill (approach validated, some unknowns)
  ▲ <Scope Name> — Uphill (investigating, major unknowns)
  ~ <Scope Name> — Nice-to-have (cut if needed)

## Risk
<The riskiest scope and what's unknown about it>

## Next
<What should be pushed uphill next>
```

---

## Anti-Patterns to Avoid

- **All design then all code**: Horizontal layers fail. Integrate vertically: one piece at a time, UI + backend.
- **Starting with peripheral features**: Login, setup, infrastructure. Start with the CORE.
- **Pre-planning all tasks**: Imagined tasks ≠ discovered tasks. Let real work reveal what's needed.
- **Estimating task duration**: Use hill position (uphill/downhill), not hours.
- **Skipping tests**: TDD is not optional. Tests define "done" and prevent regressions.
- **Pushing through when uphill at session end**: That's a shaping failure. Hand over, don't heroics.
- **Organizing by role**: Not "designer tasks" and "programmer tasks". Organize by scope.
- **Mixing reactive work**: Bugs and incidents are separate. Don't let them eat the build sessions.
- **Organizing scopes by technical layer**: "backend", "frontend", "database" are not scopes — they're horizontal slices. Organize scopes around business capabilities: what can the customer do when this scope is done? Even in a backend-only project, a scope should deliver a complete, verifiable capability (e.g., migration + model + endpoint + validation for a specific customer action), not a technical layer.
- **Re-framing or re-shaping when new requirements surface during build**: Requirements discovered during build are emergent scope. Capture them as tasks in existing or new scopes. Apply scope hammering rules. Never suggest going back to `/frame` or `/shape`.
