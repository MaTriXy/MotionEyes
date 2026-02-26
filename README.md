# 👀 MotionEyes

![MotionEyes banner](https://raw.githubusercontent.com/edwardsanchez/MotionEyes/assets/.github/assets/motioneyes-banner.jpg)


MotionEyes is an agent-first SwiftUI motion observability system.

It combines:
- `package/`: runtime tracing primitives that emit motion data over time (`.motionTrace`, `Trace.value`, `Trace.geometry`, `Trace.scrollGeometry`)
- `skill/`: an agent workflow (`motioneyes-animation-debug`) that can install/integrate the package, add targeted traces, capture logs, and validate behavior against intent

The goal is to let agents read real motion, geometry, and scroll values from logs instead of guessing from code.

## What MotionEyes Is

MotionEyes turns animation behavior into structured, timestamped evidence.

The skill orchestrates debugging end-to-end. The package provides the instrumentation surface inside the app.

## How It Works End-to-End

1. Define expected behavior in measurable terms.
2. Locate the views and state values that drive the behavior.
3. If MotionEyes is missing, the skill can integrate the package into the target project.
4. Add temporary, focused traces to values/geometry/scroll state.
5. Reproduce the issue and capture motion logs over time.
6. Compare observed traces against expected motion relationships and timing.
7. Apply fixes, re-run validation, then remove only the temporary instrumentation added for that run.

## Example Use Cases

- Detect unintended movement in UI that should remain still.
- Confirm expected motion actually happens when a state change should animate.
- Verify movement direction on each axis (for example, up vs down, left vs right).
- Confirm two animations are truly staggered instead of firing together.
- Check that relative positioning between two moving elements stays correct.
- Detect timing drift, including late starts, early stops, or incorrect duration.
- Catch easing/path issues such as overshoot or reversal when smooth one-way motion is expected.
- Diagnose scroll jumps, failed restoration, and content-offset desynchronization.

## Limitations

- `.transition` visual behavior is not directly observable when no measurable underlying value is exposed.

## Tooling and Runtime Requirements

MotionEyes works best alongside `XcodeBuildMCP` for simulator control and log capture, but it is not strictly required.

If MCP is unavailable, agents can still capture and read simulator logs directly:

```bash
xcrun simctl spawn booted log stream \
  --style compact \
  --level debug \
  --predicate 'subsystem == "MotionEyes"'
```

## Repository Layout

- `package/`: MotionEyes Swift package
- `skill/motioneyes-animation-debug/`: MotionEyes agent skill

Primary docs:
- [Package README](package/README.md)
- [Skill Workflow (`SKILL.md`)](skill/motioneyes-animation-debug/SKILL.md)

## Quick Start

From repo root:

```bash
swift build --package-path package
swift test --package-path package
```

Skill invocation:

```text
$motioneyes-animation-debug
```
