# MotionEyes

`MotionEyes` is a SwiftUI tracing toolkit for debugging animation and layout behavior over time.

## Repository Structure

This file documents the Swift package only. For the repository overview and skill documentation, see `../README.md`.

It provides:
- A single, low-friction `View` modifier
- A result-builder DSL for tracing multiple metrics
- Configurable sampling FPS (default `15`)
- Changed-only log emission
- Geometry tracing (`minX`, `minY`, `width`, `height`, etc.)
- `Logger` output filterable by subsystem/category

## Installation

Add this package to your app and import `MotionEyes`.

## Quick Start

```swift
import MotionEyes
import SwiftUI

struct DemoView: View {
    @State private var opacity = 0.0

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.orange)
            .frame(width: 200, height: 120)
            .opacity(opacity)
            .motionTrace("Input Field View", fps: 15) {
                Trace.value("opacity", opacity)
                Trace.geometry("frame", properties: [.minX, .minY, .width, .height])
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 1.0)) {
                    opacity = opacity == 0 ? 1 : 0
                }
            }
    }
}
```

## API

```swift
public extension View {
    func motionTrace(
        _ viewName: String,
        fps: Int = 15,
        engine: MotionTraceEngine = .displayLink,
        enabled: Bool = MotionTraceDefaults.enabled,
        logger: Logger = MotionTraceDefaults.logger,
        @MotionTraceBuilder _ metrics: () -> [MotionTraceMetric]
    ) -> some View
}
```

## Logging

Default logger:
- `subsystem: "MotionEyes"`
- `category: "Trace"`

Console filtering examples:
- `subsystem == "MotionEyes"`
- `category == "Trace"`

Log line format:

```text
[MotionEyes][<View Name>][<Metric Name>] key=value key=value ...
[MotionEyes][<View Name>][<Metric Name>] -- Start <timestamp> --
[MotionEyes][<View Name>][<Metric Name>] -- End <timestamp> --
```

Behavior details:
- First sample prints a baseline value line.
- When a metric begins changing, MotionEyes prints `Start` with timestamp.
- While changing, it prints sampled values at the configured FPS.
- On the first stable tick after a change burst (or when tracing stops), MotionEyes prints `End` with timestamp.

## Demo App

A sample iOS app is available at:

`Examples/MotionEyesDemo/`

Open and run:

1. `Examples/MotionEyesDemo/MotionEyesDemo.xcodeproj`
2. Run the `MotionEyesDemo` scheme in iOS Simulator

The app includes:
- Opacity animation tracing
- Offset/position tracing
- Geometry frame tracing
- Shared controls for FPS, tracing enabled, animation enabled, and view label
