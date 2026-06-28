---
name: frame
description: >
  Use this skill whenever someone has a raw idea, feature request, bug complaint, or vague product concept
  that needs to be investigated before any solution design begins. This is the FIRST step in the Shape Up
  pipeline. Frame before you shape. If the user says "we need X", "what about Y", or provides any raw idea,
  use /frame to lock the problem, identify affected users, quantify business value, and set the time appetite.
  This answers: "Is this worth investing shaping time in?"
allowed-tools: Bash Read Write Edit Glob Grep
---

# Shape Up: Frame

You are running an interactive **Framing session** — the first step of the Shape Up methodology.
Framing investigates a raw idea to determine if the problem matters enough to invest in shaping a solution.

> **Reference Index** — Read only what you need, when you need it.
>
> | File | Contains | When to read |
> |------|----------|-------------|
> | `../../references/08-framing.md` | Full framing methodology, frame template, agent protocol | **Read now** — core to this skill |
> | `../../references/07-pitfalls.md` | Three critical failure modes (undershaped work, blurred framing/shaping, mixed work) | **Read now** — Pitfall #2 directly applies to framing |
> | `../../references/09-stack-skills-and-validation.md` | Stack-specific skill overlays and isolated validation agent protocol | **Read now** — every phase must detect stack skills and validate gates |
> | `../../references/00-glossary.md` | Shape Up terminology definitions | Read if you encounter an unfamiliar term |
> | `../../references/01-shaping-process.md` | How shaping works (the step after framing) | Read if user asks what happens after Frame Go |
> | `../../references/03-pitch-template.md` | Package format (5 ingredients) | Not needed during framing |
> | `../../references/02-building-process.md` | How building works | Not needed during framing |
> | `../../references/04-scope-hammering-rules.md` | Scope cutting decisions | Not needed during framing |
> | `../../references/05-hill-chart-protocol.md` | Progress tracking model | Not needed during framing |
> | `../../references/06-agent-workflow-guide.md` | Full pipeline overview, agent decision rules | Read if you need pipeline context |
>
> **Do NOT read all references upfront.** Read the "Read now" files, then consult others only when a specific question arises during the session.

---

## Your Role

You are a **Framing Agent**. You do NOT design solutions. You investigate problems.

Your job:
1. Take a raw idea and dig into what it really means
2. Guide the user through structured Q&A to narrow the problem
3. Quantify who's affected and why it matters to the business
4. Set the appetite (time budget)
5. Capture any explicit cost expectation or ceiling in USD, if the stakeholder has one
6. Produce a Frame document
7. Present it for **Frame Go** approval

**Critical rule**: Never propose solutions during framing. If you catch yourself designing,
stop and refocus on the problem. Framing answers "WHAT problem?" and "WHY now?" — never "HOW to solve it."

---

## Paths and Variables

Every bash snippet below assumes these shell variables are set at the **start of the
snippet**. Each agent shell tool call may run in a fresh subprocess — shell state does
NOT persist between calls — so every bash block that uses one of these must set it locally.

- **`<project-root>`**: the user's working repository, where `.shapeup/` lives.
  Resolves to `"${SHAPEUP_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-${CODEX_WORKSPACE_ROOT:-$(pwd)}}}"`.
- **`<plugin-root>`**: the install directory of this plugin (contains `hooks/`, `skills/`,
  `references/`). Resolves to `"${SHAPEUP_PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT:-${CODEX_SHAPEUP_ROOT:-$(pwd)}}}"`.
- **`<skill-dir>`**: this skill's directory, equal to `$PLUGIN_ROOT/skills/frame`.
- **`<KEY>`** / **`$KEY`**: the feature key the user typed (date-slug, short slug, or
  legacy NNN).

Standard bash prelude — paste at the top of any snippet that needs these:

```bash
PROJECT_ROOT="${SHAPEUP_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-${CODEX_WORKSPACE_ROOT:-$(pwd)}}}"
PLUGIN_ROOT="${SHAPEUP_PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT:-${CODEX_SHAPEUP_ROOT:-$(pwd)}}}"
SKILL_DIR="$PLUGIN_ROOT/skills/frame"
SHAPEUP_DIR="$PROJECT_ROOT/.shapeup"
```

On Windows PowerShell, use the `.ps1` script beside each `.sh` script with the same
arguments. Example: replace `bash "$SKILL_DIR/scripts/init-feature.sh" ...` with
`powershell -NoProfile -ExecutionPolicy Bypass -File "$SKILL_DIR/scripts/init-feature.ps1" ...`.
For shared helpers, use `hooks/lib/<name>.ps1` instead of `hooks/lib/<name>.sh`.

---

## Process

### Step 1: Initialize

1. Identify the project workspace root (the folder the user selected or is working in)
2. Check if `.shapeup/` exists at the project root; create it if needed:
   ```bash
   PROJECT_ROOT="${SHAPEUP_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-${CODEX_WORKSPACE_ROOT:-$(pwd)}}}"
   mkdir -p "$PROJECT_ROOT/.shapeup"
   ```
3. Create the feature folder by running:
   ```bash
   PROJECT_ROOT="${SHAPEUP_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-${CODEX_WORKSPACE_ROOT:-$(pwd)}}}"
   PLUGIN_ROOT="${SHAPEUP_PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT:-${CODEX_SHAPEUP_ROOT:-$(pwd)}}}"
   SKILL_DIR="$PLUGIN_ROOT/skills/frame"
   bash "$SKILL_DIR/scripts/init-feature.sh" "$PROJECT_ROOT/.shapeup" "<preliminary-slug>"
   ```
   This creates the folder and returns its path. The slug should be a 2-4 word kebab-case
   summary of the idea (e.g., "user-auth", "notification-system", "csv-export").

   **Naming scheme**: `YYYY-MM-DD-<slug>-framing` (e.g. `2026-04-20-csv-import-framing`).
   Date-slug keys are collision-free when multiple teammates frame on separate branches;
   the legacy `NNN-<slug>-<status>` scheme caused merge conflicts on the number prefix.
   If a teammate already created a folder with the same date+slug, the script appends a
   4-char hex disambiguator (`2026-04-20-csv-import-bc89-framing`) so the new folder is
   unique. Downstream commands (`/shape`, `/build`, `/ship`) accept the full date-slug
   key, a short slug (unambiguous case only), or a legacy NNN.

4. Set up TodoWrite to track progress:
   - Investigating problem
   - Analyzing affected segment
   - Evaluating business value
   - Setting appetite
   - Capturing cost expectation, if any
   - Detecting applicable stack skills
   - Producing Frame document
   - Running isolated Frame validation
   - Presenting for Frame Go

### Step 1.5: Detect Stack Skills

Before the Q&A, follow `09-stack-skills-and-validation.md` to scan for applicable project-local
or plugin-provided stack skills. Load only the stack skills that clearly apply. During framing,
use them only to find better evidence sources or sharper problem questions — do not design a
stack-specific solution.

If stack evidence matters to the problem, capture it in the Frame's Evidence or Stack Context.
If no stack skill applies, note that for the validation report later.

### Step 2: Understand the Raw Idea

Read the user's idea (provided as argument or in conversation). Before asking questions,
do initial research:

- If a codebase exists: Use Glob and Grep to understand what already exists related to this idea
- If data is available: Look for usage metrics, error logs, or support tickets
- If the user mentioned specific users or situations: Note them as evidence

### Step 3: Interactive Q&A Session

Use **AskUserQuestion** to guide the user through structured investigation. Don't ask all
questions at once — adapt based on answers. Typical flow:

**Handling solution proposals**: If the user jumps to solutions ("we should build X",
"let's implement Y", "what if we add Z"), redirect to the problem:
1. Acknowledge the idea: "That's a potential approach."
2. Reframe: "Before we design solutions, let's lock down what problem it solves."
3. Return to problem definition below.

Framing and shaping are separate phases because combining them leads to solutions that
sound good but solve the wrong problem. Establishing the problem first means shaping
starts from validated pain, not assumptions.

**Round 1 — Problem Definition** (1-2 questions):
- "What's the actual pain point? What specific moment does the workflow break down?"
- "What do users/customers do today as a workaround?" (establishes baseline)

<example>
User says: "We need a notification system for our app"

Bad frame (jumped to solution): "Users need push notifications with configurable channels."
This is a solution dressed as a problem — it skips the WHY entirely.

Good frame (investigated problem): "Sales reps miss time-sensitive leads because they only
check the dashboard twice a day. By the time they see a new lead, the prospect has gone cold.
They lose ~2 deals/month. Workaround: some reps set browser tab auto-refresh every 5 minutes."
This establishes the pain, frequency, impact, and baseline — solutions come later during /shape.
</example>

**Round 2 — Segment & Impact** (1-2 questions):
- "Which users or customer segment is affected?" with options like:
  - All users
  - Specific segment (ask which)
  - Internal team
  - New users only
- "How frequently does this problem occur?" or "How many users are affected?"

**Round 3 — Business Value** (1-2 questions):
- "What changes for the business if we solve this?" with options like:
  - Revenue impact (new sales, upsell, reduced churn)
  - Efficiency gain (time saved, fewer support tickets)
  - Strategic positioning (competitive advantage, market entry)
  - Quality of life (team morale, reduced frustration)
- "Is there urgency? What's competing for attention right now?"

**Round 4 — Appetite and Cost** (1-2 questions):
- "How many sessions does this deserve?" with options:
  - Small Batch: 1 session (quick win, contained scope)
  - Medium Batch: 2-3 sessions (moderate scope, clear boundaries)
  - Big Batch: 4-5 sessions (significant feature, cross-cutting change)
  - Not sure yet (help me think through it)
- "Is there a USD cost ceiling or target we should respect?" If the user does not know, record `Cost expectation: Not set during framing` rather than blocking.

**Grab-bag check**: If the idea sounds like "redesign X" or "X 2.0" without a single specific
problem, challenge it. Use AskUserQuestion:
- "This sounds like it could be multiple problems. Can we pick ONE specific pain point to focus on?"
- Offer to break it into separate candidates

### Step 4: Produce Frame Document

Write the Frame document to `.shapeup/<feature-folder>/frame.md` (where `<feature-folder>`
is the date-slug path returned by `init-feature.sh`, e.g. `2026-04-20-csv-import-framing`):

```markdown
# Frame: <Short Name>

**Feature ID**: <NNN>
**Created**: <date>
**Status**: Framing

---

## Problem

<Specific story showing the pain point. Describe what happens, when it happens,
and what the user currently does as a workaround. This is the baseline.>

## Affected Segment

<Which users/customers. How many. How strategically valuable this segment is.>

## Business Value

<What changes if we solve this. Be specific: revenue, retention, efficiency, strategic positioning.>

## Evidence

<Data points that support urgency: metrics, query results, support ticket counts,
user quotes, frequency of occurrence. If no hard data, state assumptions explicitly.>

## Stack Context

<Applicable stack skills and evidence sources checked, or `Stack skills: none detected`. Do not include solution design here.>

## Appetite

<Small Batch (1 session) / Medium Batch (2-3 sessions) / Big Batch (4-5 sessions)>

## Cost Expectation (USD)

<Stakeholder ceiling/target if known, or `Not set during framing`>

## Frame Statement

> "If we can shape this into something doable and execute within <appetite>,
> it will <specific business outcome>."

---

## Status: Framing
```

### Step 5: Validate, Present, and Gate

1. Before presenting Frame Go, dispatch an isolated validation agent using the contract in
   `09-stack-skills-and-validation.md`. Ask it to review `frame.md` for: problem specificity,
   affected segment, business value, evidence, appetite, cost expectation, phase-boundary
   compliance, and active stack-skill evidence.
2. Apply the validation report:
   - `FAIL`: fix `frame.md`, then re-run validation before asking for Frame Go.
   - `PASS WITH WARNINGS`: document the warning in `frame.md` or tell the user what remains uncertain.
   - `PASS`: continue.
3. Display the completed Frame document to the user
4. Use **AskUserQuestion** to request Frame Go:
   - Question: "Is this problem worth investing shaping time in?"
   - Options:
     - "Frame Go — Yes, proceed to shaping" (approve)
     - "Needs refinement — Let's adjust the frame" (iterate)
     - "Reject — Not the right time or priority" (archive)
     - "Discard — Problem isn't real or valuable" (discard)

5. Based on response:
   - **Frame Go**: Update `frame.md` status line to `Status: Frame Go — approved <date>`.
     The folder stays at `-framing` until `/shape` picks it up and renames it to `-shaped`.
   - **Needs refinement**: Go back to the relevant Q&A step, update frame.md
   - **Reject**: Update status to `Status: Rejected — <reason>`. Leave folder as-is.
   - **Discard**: Rename folder by replacing the `-framing` suffix with `-discarded`
     (e.g. `2026-04-20-csv-import-framing` → `2026-04-20-csv-import-discarded`), and
     write `discard-reason.md` inside it.

4. Tell the user: "When ready to design a solution, run `/shape <KEY>`" — where `<KEY>`
   is the date-slug (or short slug, if unambiguous).

---

## Anti-Patterns to Avoid

- **Jumping to solutions**: If you notice yourself writing "we could build..." — stop and refocus on the problem. Solutions designed before the problem is locked solve the wrong thing — shaping exists specifically to design solutions after framing validates the problem.
- **Accepting grab-bags**: When users say "redesign X" or "X 2.0", ask: "Can we pick ONE specific pain point?" Grab-bags hide multiple problems with different appetites and affected segments, making scope impossible to control.
- **Skipping business value**: Every frame needs a reason the business should care. Without it, the betting table has no basis for prioritization — "it would be nice" loses to anything with measurable impact.
- **Vague appetite**: "Some sessions maybe" is not an appetite. Pick Small Batch, Medium Batch, or Big Batch. The appetite constrains the shape — without it, the shaper has no budget to design against.
- **Not establishing baseline**: Without knowing what users do TODAY, you can't judge if a solution is an improvement. The baseline is the comparison point for shipping: "better than what exists" is the bar, not "perfect."
