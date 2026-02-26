# MotionEyes Observability Patterns

Use this reference to choose trace metrics and interpret logs for animation debugging.

## Metric Selection

Pick metrics that represent the user complaint directly.

- Fade/visibility issues:
  - `Trace.value("opacity", opacity)`
- Scale/size issues:
  - `Trace.value("scale", scale)`
  - `Trace.value("size", size)`
- Translation/path issues:
  - `Trace.value("offset", CGPoint(x: offset.width, y: offset.height))`
  - `Trace.value("position", CGPoint(x: position.x, y: position.y))`
- Layout/frame-driven issues:
  - `Trace.geometry("frame", properties: [.minX, .minY, .width, .height], in: .global)`

Prefer one to three focused metrics first; expand only if root cause remains unclear.

## Direction and Coordinate Conventions

iOS coordinate space conventions:

- Increasing `x` means moving right.
- Increasing `y` means moving down.
- Decreasing `y` means moving up.

Interpret direction by checking the sign and trend of sampled values between `Start` and `End`.

## Timing Interpretation

Use MotionEyes markers to reason about timing:

- `Start` marks first detected change in a burst.
- `End` marks first stable tick after the burst.

Useful checks:

- Delay to motion: time from interaction trigger to first `Start`.
- Motion duration: time from `Start` to `End`.
- Early/late fade: compare `opacity` change window with expected interaction timeline.

## Relative Motion Comparisons

For "A should track B" issues:

1. Trace both objects using either `Trace.value` offsets or `Trace.geometry`.
2. Compare values at similar timestamps.
3. Validate expected relationship:
   - fixed delta (e.g., badge is always 12pt above card),
   - same direction and similar slope,
   - synchronized start and end windows.

Common mismatch signatures:

- Diverging deltas: follower drift.
- Opposite sign trend: moves in opposite direction.
- Delayed `Start`: lagging follower.
- Early `End`: follower stops too soon.

## Log Reading Quick Guide

MotionEyes output patterns:

- Value line:
  - `[MotionEyes][View][Metric] key=value key=value`
- Marker line:
  - `[MotionEyes][View][Metric] -- Start timestamp --`
  - `[MotionEyes][View][Metric] -- End timestamp --`

Read logs in sequence for each metric:

1. Baseline value before change.
2. `Start`.
3. Sample evolution at configured FPS.
4. `End`.

## Minimal Instrumentation Template

```swift
import MotionEyes

AnimatedView()
    .motionTrace("Target Motion", fps: 30) {
        Trace.value("opacity", opacity)
        Trace.value("offset", CGPoint(x: offset.width, y: offset.height))
        Trace.geometry(
            "targetFrame",
            properties: [.minX, .minY, .width, .height],
            in: .global
        )
    }
```

Use semantic metric names so logs remain easy to map back to intent.
