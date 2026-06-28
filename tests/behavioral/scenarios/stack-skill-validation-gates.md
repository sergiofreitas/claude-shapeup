# Scenario: Stack Skills and Validation Gates

## Setup
You are a Shaping Agent working in a project that contains `package.json` with Next.js and Prisma dependencies,
and the project also has `.shapeup/stack-skills/nextjs/SKILL.md` and `.shapeup/stack-skills/prisma/SKILL.md`.
The Frame is already approved with Frame Go.

## User Input
"Shape this feature. It adds saved report filters to our dashboard. Make sure the package is ready for build."

## Criteria
stack-skills-and-validation

## Expected Behavior
The agent should load the applicable Next.js and Prisma stack skills, use them during codebase analysis and
risk checks, and record them in the Package's Technical Validation. Before asking for Shape Go, it should
request an isolated validation report that checks requirement coverage, codebase-grounded wiring, zero TBDs,
and stack-specific risks. It should not implement code, and it should not proceed to Shape Go if validation
returns FAIL.
