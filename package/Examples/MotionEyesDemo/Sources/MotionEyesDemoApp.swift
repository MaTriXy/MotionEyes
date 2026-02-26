import Foundation
import MotionEyes
import SwiftUI

@main
struct MotionEyesDemoApp: App {
    var body: some Scene {
        WindowGroup {
            DemoRootView()
        }
    }
}

private func formatNumber<T: BinaryFloatingPoint>(_ value: T, digits: Int) -> String {
    String(format: "%.*f", digits, Double(value))
}

private struct DemoRootView: View {
    @State private var viewLabel = "Input Field View"
    @State private var fps = 15
    @State private var tracingEnabled = true
    @State private var animateChanges = true

    var body: some View {
        TabView {
            OpacityDemoView(
                viewLabel: $viewLabel,
                fps: $fps,
                tracingEnabled: $tracingEnabled,
                animateChanges: $animateChanges
            )
            .tabItem {
                Label("Opacity", systemImage: "circle.lefthalf.filled")
            }

            OffsetDemoView(
                viewLabel: $viewLabel,
                fps: $fps,
                tracingEnabled: $tracingEnabled,
                animateChanges: $animateChanges
            )
            .tabItem {
                Label("Offset", systemImage: "arrow.up.left.and.arrow.down.right")
            }

            GeometryDemoView(
                viewLabel: $viewLabel,
                fps: $fps,
                tracingEnabled: $tracingEnabled,
                animateChanges: $animateChanges
            )
            .tabItem {
                Label("Geometry", systemImage: "viewfinder")
            }

            ScrollGeometryDemoView(
                viewLabel: $viewLabel,
                fps: $fps,
                tracingEnabled: $tracingEnabled,
                animateChanges: $animateChanges
            )
            .tabItem {
                Label("Scroll", systemImage: "arrow.up.and.down.text.horizontal")
            }
        }
    }
}

private struct DemoControls: View {
    @Binding var viewLabel: String
    @Binding var fps: Int
    @Binding var tracingEnabled: Bool
    @Binding var animateChanges: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trace Controls")
                .font(.headline)

            TextField("View label", text: $viewLabel)
                .textFieldStyle(.roundedBorder)

            HStack {
                Text("FPS: \(fps)")
                Spacer()
                Stepper("", value: $fps, in: 1...120)
                    .labelsHidden()
            }

            Toggle("Tracing enabled", isOn: $tracingEnabled)
            Toggle("Animate changes", isOn: $animateChanges)
        }
        .padding()
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct OpacityDemoView: View {
    @Binding var viewLabel: String
    @Binding var fps: Int
    @Binding var tracingEnabled: Bool
    @Binding var animateChanges: Bool

    @State private var opacity = 0.0

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                DemoControls(
                    viewLabel: $viewLabel,
                    fps: $fps,
                    tracingEnabled: $tracingEnabled,
                    animateChanges: $animateChanges
                )

                RoundedRectangle(cornerRadius: 16)
                    .fill(.orange.gradient)
                    .frame(width: 220, height: 140)
                    .opacity(opacity)
                    .motionTrace(viewLabel, fps: fps, enabled: tracingEnabled) {
                        Trace.value("opacity", opacity)
                    }

                Text("Current opacity: \(formatNumber(opacity, digits: 2))")
                    .font(.subheadline)
                    .monospacedDigit()

                Button("Toggle Opacity") {
                    applyChange {
                        opacity = opacity == 0 ? 1 : 0
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    private func applyChange(_ updates: () -> Void) {
        if animateChanges {
            withAnimation(.easeInOut(duration: 1.0)) {
                updates()
            }
        } else {
            updates()
        }
    }
}

private struct OffsetDemoView: View {
    @Binding var viewLabel: String
    @Binding var fps: Int
    @Binding var tracingEnabled: Bool
    @Binding var animateChanges: Bool

    @State private var offset = CGSize.zero

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                DemoControls(
                    viewLabel: $viewLabel,
                    fps: $fps,
                    tracingEnabled: $tracingEnabled,
                    animateChanges: $animateChanges
                )

                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                        .frame(width: 260, height: 220)

                    Circle()
                        .fill(.mint.gradient)
                        .frame(width: 56, height: 56)
                        .offset(offset)
                        .motionTrace(viewLabel, fps: fps, enabled: tracingEnabled) {
                            Trace.value("offset", CGPoint(x: offset.width, y: offset.height))
                        }
                }

                Text(
                    "Offset x: \(formatNumber(offset.width, digits: 1)) y: \(formatNumber(offset.height, digits: 1))"
                )
                    .font(.subheadline)
                    .monospacedDigit()

                Button("Move Dot") {
                    let next = CGSize(
                        width: .random(in: -80...80),
                        height: .random(in: -70...70)
                    )

                    applyChange {
                        offset = next
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    private func applyChange(_ updates: () -> Void) {
        if animateChanges {
            withAnimation(.spring(duration: 0.9, bounce: 0.25)) {
                updates()
            }
        } else {
            updates()
        }
    }
}

private struct GeometryDemoView: View {
    @Binding var viewLabel: String
    @Binding var fps: Int
    @Binding var tracingEnabled: Bool
    @Binding var animateChanges: Bool

    @State private var boxSize: CGFloat = 120
    @State private var boxOffset = CGSize.zero

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                DemoControls(
                    viewLabel: $viewLabel,
                    fps: $fps,
                    tracingEnabled: $tracingEnabled,
                    animateChanges: $animateChanges
                )

                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                        .frame(width: 290, height: 260)

                    RoundedRectangle(cornerRadius: 18)
                        .fill(.blue.gradient)
                        .frame(width: boxSize, height: boxSize)
                        .offset(boxOffset)
                        .motionTrace(viewLabel, fps: fps, enabled: tracingEnabled) {
                            Trace.value("size", boxSize)
                            Trace.value("offset", CGPoint(x: boxOffset.width, y: boxOffset.height))
                            Trace.geometry(
                                "cardFrame",
                                properties: [.minX, .minY, .width, .height],
                                in: .global
                            )
                        }
                }

                VStack(spacing: 10) {
                    HStack {
                        Text("Size")
                        Slider(value: $boxSize, in: 60...180)
                    }

                    HStack {
                        Text("Offset X")
                        Slider(value: $boxOffset.width, in: -80...80)
                    }

                    HStack {
                        Text("Offset Y")
                        Slider(value: $boxOffset.height, in: -80...80)
                    }
                }

                Button("Randomize") {
                    applyChange {
                        boxSize = .random(in: 60...180)
                        boxOffset = CGSize(
                            width: .random(in: -80...80),
                            height: .random(in: -80...80)
                        )
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    private func applyChange(_ updates: () -> Void) {
        if animateChanges {
            withAnimation(.easeInOut(duration: 1.1)) {
                updates()
            }
        } else {
            updates()
        }
    }
}

private struct ScrollGeometryDemoView: View {
    @Binding var viewLabel: String
    @Binding var fps: Int
    @Binding var tracingEnabled: Bool
    @Binding var animateChanges: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                DemoControls(
                    viewLabel: $viewLabel,
                    fps: $fps,
                    tracingEnabled: $tracingEnabled,
                    animateChanges: $animateChanges
                )

                Text("Scroll to generate Trace.scrollGeometry samples.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(0..<60, id: \.self) { index in
                    HStack {
                        Text("Row \(index)")
                            .font(.body.monospacedDigit())
                        Spacer()
                        Text("Offset probe")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .motionTrace(viewLabel, fps: fps, enabled: tracingEnabled) {
            Trace.scrollGeometry("scrollMetrics")
        }
    }
}
