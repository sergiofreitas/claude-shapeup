# Build Artifact Quality Evaluation

You are evaluating Shape Up build artifacts produced by a Builder Agent during a dry-run.
The agent received a shaped Package and was asked to produce planning artifacts
(orientation.md, scopes/, hillchart.md) without writing actual code.

Score each criterion 0-2:
- **0** = Missing or boilerplate (generic text that could apply to any project)
- **1** = Present but superficial (project-specific but lacks depth or reasoning)
- **2** = Substantive and specific (clear reasoning tied to this project's unique characteristics)

---

## Orientation Quality

### 1. Problem Restated (0-2)
Is the problem restated in the builder's own words, not copy-pasted from the Package?
- 0: Missing or verbatim copy of Package problem section
- 1: Present but mostly paraphrasing the Package
- 2: Genuine restatement showing comprehension — different structure, focuses on what matters for building

### 2. First Piece Reasoning (0-2)
Does the first piece reasoning explain the dependency chain, not just claim "it's core"?
- 0: Missing or just "starting with X because it's core"
- 1: Names the first piece with a reason but doesn't explain what depends on it
- 2: Explains WHY this piece enables other work — "X must come first because Y and Z both depend on X being established, and X has the most uncertainty around..."

### 3. Imagined vs. Discovered (0-2)
Does the Imagined vs. Discovered section identify real tensions between Package elements and what the builder found?
- 0: Missing or just lists Package elements
- 1: Lists Package elements and notes codebase observations but doesn't contrast them
- 2: Identifies specific tensions — "Package assumes X but the codebase reveals Y" or "Package element Z maps to an area that's more complex than shaped because..."

---

## Scope Quality

### 4. Vertical Slices (0-2)
Are scopes genuine vertical slices (not horizontal layers like "backend"/"frontend")?
- 0: Scopes are organized by layer (backend, frontend, database, testing)
- 1: Scopes mix some layers with some vertical concerns
- 2: Every scope delivers an integrated, end-to-end piece of functionality a user could interact with

### 5. Project-Specific Names (0-2)
Are scope names unique to this project (not generic like "UI changes" or "data layer")?
- 0: Generic names (Setup, Backend, Frontend, Polish, Testing)
- 1: Mix of generic and specific names
- 2: All names are project-specific vocabulary — you could tell what project this is from scope names alone

### 6. Prioritization Reasoning (0-2)
Does each scope have explicit reasoning about risk AND dependencies?
- 0: No prioritization reasoning or just "High/Medium/Low" without explanation
- 1: Risk levels stated but dependencies not explained, or vice versa
- 2: Each scope explains its risk level (what's uncertain), what it depends on, what it blocks, and WHY it should be tackled in the stated order

### 7. Vocabulary Difference (0-2)
Do scopes differ meaningfully from Package elements?
- 0: Scopes are 1:1 renamed Package elements
- 1: Some scopes combine or split Package elements but names are similar
- 2: Scopes use building vocabulary that emerged from work analysis — clearly different decomposition from the Package's shaping vocabulary

---

## Hill Chart Quality

### 8. Sequencing Rationale (0-2)
Does the sequencing rationale explain inverted pyramid reasoning?
- 0: Missing or just "riskiest first"
- 1: Names which scope is riskiest but doesn't explain the inverted pyramid logic
- 2: Explains what would happen if time runs out — which scopes MUST be done vs. which could be cut — and why the chosen order minimizes risk of late-cycle surprises

### 9. History Shows Movement (0-2)
Does the hill chart history show uphill→peak→downhill progression, not just "Done"?
- 0: No history section, or all entries show "Done"
- 1: History exists but all entries are the same state (no visible progression)
- 2: Multiple snapshots showing scopes moving through different stages — you can see the work progressing through uncertainty resolution

### 10. Movement Notes (0-2)
Do movement notes explain WHY transitions happened?
- 0: No movement notes
- 1: Notes describe WHAT changed ("moved to downhill") but not WHY
- 2: Notes explain the trigger — "crossed the hill after validating that the API returns data in the expected format" or "split into two scopes after discovering the UI and auth concerns move at different speeds"

---

## Multi-Session Quality (if applicable — skip for single-session)

### 11. Handover Reasoning (0-2)
Does "Next Session Should" include risk and dependency reasoning?
- 0: Flat list of scope names without reasoning
- 1: Scopes listed with brief notes but no risk/dependency context
- 2: Each next-session item explains WHY it's priority, what risk it carries, and what this session unblocked for it

### 12. Fresh Eyes Re-evaluation (0-2)
Does the continuation entry re-evaluate scope definitions rather than blindly continuing?
- 0: No re-evaluation — just picks up where last session left off
- 1: Acknowledges previous work but doesn't question scope validity
- 2: Explicitly assesses whether scopes still make sense, flags any stuck scopes, considers whether any scope should be split or redefined

---

## Scoring

**Single-session features** (criteria 1-10): Total ___/20
- Pass threshold: **14/20** (70%)

**Multi-session features** (criteria 1-12): Total ___/24
- Pass threshold: **16/24** (67%)

---

## Output Format

For each criterion, output:
```
[N] <Criterion Name>: <score>/2
    <one-sentence justification>
```

Then:
```
TOTAL: <score>/<max>
RESULT: PASS | FAIL
```
