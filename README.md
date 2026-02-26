# MotionEyes

This repository contains two related projects:

- `package/`: the `MotionEyes` Swift package
- `skill/`: the `motioneyes-animation-debug` Codex skill

## Repository Layout

- `package/`
  - `Package.swift`
  - `Sources/`
  - `Tests/`
  - `Examples/MotionEyesDemo/`
- `skill/motioneyes-animation-debug/`
  - `SKILL.md`
  - `agents/openai.yaml`
  - `references/motioneyes-observability-patterns.md`

## Swift Package

Package documentation and usage are in `package/README.md`.

From repo root:

```bash
swift build --package-path package
swift test --package-path package
```

## Skill

The MotionEyes skill lives at `skill/motioneyes-animation-debug/`.

- Skill name: `motioneyes-animation-debug`
- Main file: `skill/motioneyes-animation-debug/SKILL.md`
- Invocation: `$motioneyes-animation-debug`

Use this skill to diagnose and fix SwiftUI animation behavior by temporarily instrumenting views with MotionEyes traces and analyzing motion logs over time.
