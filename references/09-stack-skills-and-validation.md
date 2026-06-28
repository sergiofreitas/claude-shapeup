# Stack Skills and Isolated Validation

> Reference for AI agents extending Shape Up with stack-specific expertise and independent gate checks.

Shape Up stays agent-neutral and stack-neutral by default. Stack skills add framework-specific judgment
without changing the core phase boundaries: framing still investigates the problem, shaping still designs
the solution, building still implements scoped behaviors, and shipping still archives decisions.

---

## Stack Skills

A stack skill is an optional, narrow instruction pack for a specific technology, framework, library, or
runtime. Examples: Next.js, Playwright, Prisma ORM, Rails, Laravel, React Native, Terraform.

Stack skills are advisory overlays. They can add stack-specific checks, commands, conventions, risk
questions, and verification expectations, but they must not replace the Shape Up phase protocol.
They also do not replace the technical principles in `10-technical-principles.md`: YAGNI, DRY,
KISS, and TDD remain mandatory across all stacks.

### Location and Naming

Host tools can expose stack skills differently, so the framework recognizes either form:

- Project-local stack skills under `.shapeup/stack-skills/<stack>/SKILL.md`
- Plugin-provided stack skills under `skills/stacks/<stack>/SKILL.md`

Use lowercase kebab-case stack names, such as `nextjs`, `playwright`, `prisma`, `react-native`, or
`terraform`.

### Stack Skill Format

Each stack skill should define:

```markdown
# Stack Skill: <stack>

## Applies When
- <Files, manifests, dependencies, or user request signals that activate this skill>

## Phase Guidance

### Frame
- <Problem-framing questions or evidence sources specific to this stack>

### Shape
- <Architecture, data model, migration, routing, deployment, or security concerns to de-risk>

### Build
- <Implementation conventions, TDD commands, browser/API verification, and common pitfalls>

### Ship
- <ADRs, operational notes, migration rollback notes, or observability lessons to capture>

## Validation Checklist
- <Independent checks the validation agent should run or inspect for this stack>
```

Keep stack skills small and factual. Prefer commands already present in the user's project over generic
commands. If a stack skill recommends a command that may not exist, phrase it as a discovery step first
("look for a script such as...").

### Activation Protocol

At the start of each phase, the phase agent must scan for applicable stack skills:

1. Inspect obvious stack signals in the project: package manifests, lockfiles, config files, dependency
   names, framework directories, generated clients, test framework config, and deployment files.
2. Check project-local stack skills first, then plugin-provided stack skills.
3. Load only the skills that clearly apply to the current project and phase.
4. Record the active stack skills in the phase artifact:
   - `frame.md`: under `## Evidence` or a short `## Stack Context` section if stack evidence matters.
   - `package.md`: under `## Technical Validation`.
   - scope files / handovers / `build-summary.md`: under `## Notes` or verification notes.
   - `decisions.md` / ADRs: when a stack-specific decision should guide future work.

If no stack skill applies, continue with the base Shape Up protocol and state "Stack skills: none
detected" in the relevant validation notes when a gate is reached.

### Boundaries

Stack skills must not:

- Turn framing into solution design.
- Let shaping skip codebase analysis.
- Let building switch to horizontal layers like "all Prisma first, all UI later."
- Let shipping perform new implementation work.
- Override appetite, cost tracking, or scope hammering rules.

---

## Isolated Validation Agents

Every phase gate needs an independent validation pass. The validation agent is isolated from the main
phase agent's reasoning: it receives the relevant artifacts, reads the current codebase state when needed,
and reports findings without editing files.

Use the host's best available isolation mechanism: a subagent, reviewer agent, separate model call, or
separate verification task. If the host has no true subagent support, simulate isolation by starting a new
bounded review pass with only the artifacts and checks listed below, and explicitly label it as a fallback.

### Validation Agent Contract

The phase agent must ask the validation agent for a bounded, structured report:

```markdown
## Validation Report

**Phase**: Frame | Shape | Build | Ship
**Stack skills checked**: <list or "none detected">
**Technical principles checked**: YAGNI | DRY | KISS | TDD
**Verdict**: PASS | PASS WITH WARNINGS | FAIL

## Findings
- <severity>: <issue> (<artifact path or code citation when available>)

## Required fixes before gate
- <fix or "None">
```

The validation agent must:

- Stay read-only.
- Cite artifact paths and code paths when possible.
- Keep the report short enough for the phase agent to act on it.
- Treat stack-skill checklist failures as findings, not as automatic scope expansion.
- Mark `FAIL` only when the gate would approve an invalid phase artifact or a broken implementation claim.

### Phase Gates

| Phase | Run validation before | Required focus |
|-------|-----------------------|----------------|
| Frame | Frame Go | Problem specificity, affected segment, business value, evidence, appetite, cost expectation, phase boundary, active stack evidence if relevant |
| Shape | Shape Go | Frame Go status, R coverage, codebase-grounded wiring, stack-skill de-risking, YAGNI/DRY/KISS/TDD fit, fit check, zero TBDs/unknowns, cost estimate |
| Build | Handover and Ready to Ship | Behavior state vs implementation, TDD evidence, stack-specific verification, YAGNI/DRY/KISS fit, hill chart consistency, scope hammering decisions |
| Ship | Archive/rename to `-shipped` | Build completeness, ADR-worthy decisions, cost actuals, architecture documentation, stack-specific operational lessons |

### Applying Findings

- `FAIL`: Stop the gate. Fix the artifact or implementation, then re-run validation.
- `PASS WITH WARNINGS`: Continue only if the warning is documented in the phase artifact or handed to the next phase.
- `PASS`: Continue to the gate approval step.

The main phase agent remains accountable for changes. Validation agents report; phase agents decide and
apply fixes within the Shape Up boundaries.
