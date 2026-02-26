---
name: motioneyes-animation-debug
description: Diagnose and fix SwiftUI animation behavior by temporarily instrumenting views with MotionEyes, capturing console traces over time, and comparing motion data to user intent. Use when users report animation bugs such as wrong direction, premature fade, timing or easing mismatch, unexpected movement, missing movement, or incorrect relative movement between views. Prefer XcodeBuildMCP log capture first and fallback to CLI log streaming; remove only agent-added MotionEyes instrumentation after validation.
---

# MotionEyes Animation Debug

## Overview

Use MotionEyes as temporary observability for SwiftUI animation debugging. Instrument targeted values and geometry, capture time-series logs, compare observed motion against expected motion, apply fixes, re-validate, and clean up all agent-added tracing.

## Workflow

Follow this exact order:

1. Confirm the complaint and expected behavior in measurable terms.
2. Locate the target view and the state values that drive the animation.
3. Ensure MotionEyes availability; if missing, auto-integrate the MotionEyes package into the app target before continuing.
4. Add temporary `.motionTrace(...)` instrumentation with `Trace.value` and `Trace.geometry` metrics named after user intent.
5. Run the app and reproduce the issue.
6. Capture logs with XcodeBuildMCP first; fallback to CLI log streaming if MCP is unavailable.
7. Analyze how values evolve over time versus expected behavior.
8. Implement a fix, rerun, and verify the motion now matches intent.
9. Remove only agent-added MotionEyes imports/modifiers/trace metrics from this run; never remove user-authored pre-existing MotionEyes code.

## Instrumentation Rules

Add instrumentation only to the minimum set of views needed to test the complaint.

- Use stable, semantic trace names that match the user complaint.
- Set the values to the same name as the property, so it's easier to identify.
- Use geometry tracing when motion is relative to container or sibling layout.

Example template:

```swift
import MotionEyes
import SwiftUI

struct CardMotionExample: View {
    @State private var opacity = 1.0
    @State private var offset = CGSize.zero

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.orange)
            .frame(width: 180, height: 120)
            .opacity(opacity)
            .offset(offset)
            .motionTrace("Card Motion", fps: 30) {
                Trace.value("opacity", opacity)
                Trace.value("offset", CGPoint(x: offset.width, y: offset.height))
                Trace.geometry(
                    "cardFrame",
                    properties: [.minX, .minY, .width, .height],
                    in: .global
                )
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.6)) {
                    opacity = opacity == 1 ? 0.4 : 1
                    offset = offset == .zero ? CGSize(width: 0, height: 36) : .zero
                }
            }
    }
}
```

## Log Capture

Prefer XcodeBuildMCP:

1. Call `mcp__XcodeBuildMCP__session_show_defaults`.
2. Set missing defaults with `mcp__XcodeBuildMCP__session_set_defaults`.
3. Build and run with `mcp__XcodeBuildMCP__build_run_sim` if needed.
4. Start capture with `mcp__XcodeBuildMCP__start_sim_log_cap`:
   - `captureConsole: true`
   - `subsystemFilter: "MotionEyes"` (or broader `"all"` when needed)
5. Reproduce the animation.
6. Stop capture with `mcp__XcodeBuildMCP__stop_sim_log_cap` and inspect returned logs.

Fallback CLI if MCP is unavailable:

```bash
xcrun simctl spawn booted log stream \
  --style compact \
  --level debug \
  --predicate 'subsystem == "MotionEyes"'
```

## MotionEyes Log Analysis

Use these signatures:

- Value samples: `[MotionEyes][View][Metric] key=value ...`
- Change burst start: `[MotionEyes][View][Metric] -- Start timestamp --`
- Change burst end: `[MotionEyes][View][Metric] -- End timestamp --`

Analyze:

- Direction: sign and trend of sampled values.
- Timing: time delta from intent trigger to first `Start` and to `End`.
- Shape: monotonic change, overshoot, reversals, oscillation, flat segments.
- Relationship: compare two traces over the same time window when behavior is relative.

Do not force fixed thresholds globally; evaluate against the user’s stated expectation.

## Cleanup Rules

At the end of every run:

- Remove all MotionEyes instrumentation introduced by the agent during this debugging run.
- Keep all MotionEyes instrumentation that already existed before the run.
- Remove agent-added `import MotionEyes` only if it was added solely for temporary tracing and is no longer needed.
- Confirm code compiles after cleanup.

## Scenarios to Support

- Fade timing bug: trace `opacity` and verify fade begins/ends when expected.
- Wrong direction bug: trace Y-related value and confirm sign/trend match expected motion.
- Relative motion bug: trace two objects and verify their positional relationship over time.
- No motion desired: if something is meant to remain static during transition.
- Existing instrumentation safety: preserve user-authored MotionEyes traces.
- MCP unavailable: use CLI log stream and continue analysis.
- Missing package: auto-integrate MotionEyes, then execute normal workflow.

## Reference

Load [references/motioneyes-observability-patterns.md](references/motioneyes-observability-patterns.md) when choosing metrics or interpreting trace behavior.
