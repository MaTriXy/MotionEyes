# Contributing to MotionEyes

Thanks for helping improve MotionEyes. This repo ships both a Swift package and an agent skill, and contributions to either are welcome.

## How to Propose Changes

1. Explain the problem and the expected outcome in your PR description.
2. Keep scope tight and focused on the skill workflow or documentation.
3. Include before and after behavior or example output when relevant.

## Scope Guardrails

- Keep changes focused and explain the impact clearly.
- If you touch both the package and the skill, call out the coupling in your PR description.

## Skill Update Standards

- Write evidence-first instructions that rely on MotionEyes logs rather than visual guesses.
- Keep instrumentation minimal and remove only agent-added traces after validation.
- Use current MotionEyes APIs in examples, including `space` and `source` for `Trace.geometry`.
- Prefer MCP-driven log capture and provide CLI fallback.
- Preserve the front matter schema at the top of `SKILL.md`.
## Visual Analysis Scripts

- The visual analysis scripts live under `skill/motioneyes-visual-analysis/scripts/`.
- Python dependencies should be declared in `skill/motioneyes-visual-analysis/requirements.txt`.

## Package Update Standards

- Keep public APIs stable unless the change is intentional and documented.
- Add or update tests in `Tests/` when behavior changes.
- Prefer minimal, well-scoped changes over broad refactors.

## PR Checklist

- README sections follow the expected order and have no broken links.
- `skill/motioneyes-animation-debug/SKILL.md` front matter remains valid YAML.
- Any added JSON manifests are valid JSON.
- Package changes are tested or justified when tests are not feasible.
