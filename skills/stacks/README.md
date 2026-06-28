# Stack Skills

Stack skills are optional overlays for technology-specific guidance. Add plugin-provided stack skills here
when the convention should travel with the Shape Up skill pack, for example:

- `skills/stacks/nextjs/SKILL.md`
- `skills/stacks/playwright/SKILL.md`
- `skills/stacks/prisma/SKILL.md`

Project-specific stack skills should live in the consuming project under `.shapeup/stack-skills/<stack>/SKILL.md`.
Project-local skills take precedence over plugin-provided skills.

Each stack skill should follow the format in `references/09-stack-skills-and-validation.md` and stay advisory:
it can add stack checks, commands, risks, and conventions, but it must not replace the phase protocol in
`skills/frame`, `skills/shape`, `skills/build`, or `skills/ship`.
