import OSLog
@preconcurrency import SwiftUI

#if canImport(AppKit)
import AppKit
#endif
#if canImport(QuartzCore)
import QuartzCore
#endif
#if canImport(UIKit)
import UIKit
#endif

private struct UncheckedGeometrySpace: @unchecked Sendable {
    let value: MotionGeometrySpace
}

private struct UncheckedCoordinateSpace: @unchecked Sendable {
    let value: CoordinateSpace
}

public extension View {
    /// Attaches runtime motion tracing to the receiving view.
    ///
    /// Add one or more metrics using the `metrics` builder.
    /// For geometry tracing, use ``Trace/geometry(_:properties:space:source:precision:epsilon:)``
    /// to choose between layout geometry and presentation geometry.
    @ViewBuilder
    func motionTrace(
        _ viewName: String,
        fps: Int = 15,
        engine: MotionTraceEngine = .displayLink,
        enabled: Bool = MotionTraceDefaults.enabled,
        logger: Logger = MotionTraceDefaults.logger,
        @MotionTraceBuilder _ metrics: () -> [MotionTraceMetric]
    ) -> some View {
        if enabled {
            modifier(
                MotionTraceModifier(
                    viewName: viewName,
                    fps: fps,
                    engine: engine,
                    logger: logger,
                    metrics: metrics()
                )
            )
        } else {
            self
        }
    }
}

private struct MotionTraceModifier: ViewModifier {
    let viewName: String
    let fps: Int
    let engine: MotionTraceEngine
    let logger: Logger
    let metrics: [MotionTraceMetric]

    func body(content: Content) -> some View {
        content.background {
            MotionTraceRuntimeOverlay(
                viewName: viewName,
                fps: fps,
                engine: engine,
                logger: logger,
                metrics: metrics
            )
        }
    }
}

private struct MotionTraceRuntimeOverlay: View {
    private struct ValueProbeInput: Identifiable {
        let id: String
        let metricID: String
        let metricName: String
        let componentName: String
        let value: CGFloat
        let precision: Int
        let epsilon: Double
    }

    private struct GeometryProbeInput: Identifiable {
        let id: String
        let metricID: String
        let metricName: String
        let properties: Set<MotionGeometryProperty>
        let space: UncheckedGeometrySpace
        let source: MotionGeometrySource
        let precision: Int
        let epsilon: Double
    }

    private struct ScrollGeometryProbeInput: Identifiable {
        let id: String
        let metricID: String
        let metricName: String
        let properties: Set<MotionScrollGeometryProperty>
        let precision: Int
        let epsilon: Double
    }

    let viewName: String
    let fps: Int
    let engine: MotionTraceEngine
    let logger: Logger
    let metrics: [MotionTraceMetric]

    @State private var coordinator = MotionTraceCoordinator()

    private var valueProbes: [ValueProbeInput] {
        metrics.enumerated().flatMap { index, metric in
            switch metric.kind {
            case let .value(spec):
                let metricID = "value-\(index)"
                return spec.components.map { component in
                    ValueProbeInput(
                        id: "\(metricID).\(component.key)",
                        metricID: metricID,
                        metricName: spec.name,
                        componentName: component.key,
                        value: CGFloat(component.value),
                        precision: spec.precision,
                        epsilon: spec.epsilon
                    )
                }
            case .geometry, .scrollGeometry:
                return []
            }
        }
    }

    private var geometryProbes: [GeometryProbeInput] {
        metrics.enumerated().compactMap { index, metric in
            switch metric.kind {
            case .value, .scrollGeometry:
                return nil
            case let .geometry(spec):
                return GeometryProbeInput(
                    id: "geometry-\(index)",
                    metricID: "geometry-\(index)",
                    metricName: spec.name,
                    properties: spec.properties,
                    space: UncheckedGeometrySpace(value: spec.space),
                    source: spec.source,
                    precision: spec.precision,
                    epsilon: spec.epsilon
                )
            }
        }
    }

    private var scrollGeometryProbes: [ScrollGeometryProbeInput] {
        metrics.enumerated().compactMap { index, metric in
            switch metric.kind {
            case .value, .geometry:
                return nil
            case let .scrollGeometry(spec):
                return ScrollGeometryProbeInput(
                    id: "scroll-geometry-\(index)",
                    metricID: "scroll-geometry-\(index)",
                    metricName: spec.name,
                    properties: spec.properties,
                    precision: spec.precision,
                    epsilon: spec.epsilon
                )
            }
        }
    }

    private var activeMetricIDs: [String] {
        let ids = valueProbes.map(\.metricID) + geometryProbes.map(\.metricID) + scrollGeometryProbes.map(\.metricID)
        return Array(Set(ids)).sorted()
    }

    var body: some View {
        ZStack {
            ForEach(valueProbes) { probe in
                MotionTraceValueProbe(value: probe.value) { sampledValue in
                    coordinator.recordValueComponent(
                        metricID: probe.metricID,
                        metricName: probe.metricName,
                        componentName: probe.componentName,
                        value: sampledValue,
                        precision: probe.precision,
                        epsilon: probe.epsilon
                    )
                }
            }

            ForEach(geometryProbes) { probe in
                MotionGeometryProbeView(space: probe.space, source: probe.source) { frame in
                    var components: [String: Double] = [:]

                    for property in probe.properties.sorted(by: { $0.rawValue < $1.rawValue }) {
                        components[property.rawValue] = property.extract(from: frame)
                    }

                    coordinator.recordGeometry(
                        metricID: probe.metricID,
                        metricName: probe.metricName,
                        components: components,
                        precision: probe.precision,
                        epsilon: probe.epsilon
                    )
                }
            }

            ForEach(scrollGeometryProbes) { probe in
                MotionScrollGeometryProbeView(properties: probe.properties) { components in
                    coordinator.recordGeometry(
                        metricID: probe.metricID,
                        metricName: probe.metricName,
                        components: components,
                        precision: probe.precision,
                        epsilon: probe.epsilon
                    )
                }
            }
        }
        .frame(width: 0, height: 0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            coordinator.configure(
                viewName: viewName,
                fps: fps,
                engine: engine,
                logger: logger
            )
            coordinator.setActiveMetricIDs(Set(activeMetricIDs))
            coordinator.start()
        }
        .onDisappear {
            coordinator.stop()
        }
        .onChange(of: fps) { _, newFPS in
            coordinator.updateSampling(fps: newFPS, engine: engine)
        }
        .onChange(of: engine) { _, newEngine in
            coordinator.updateSampling(fps: fps, engine: newEngine)
        }
        .onChange(of: viewName) { _, newViewName in
            coordinator.updateViewName(newViewName)
        }
        .onChange(of: activeMetricIDs) { _, newIDs in
            coordinator.setActiveMetricIDs(Set(newIDs))
        }
    }
}

private struct MotionTraceValueProbe: View {
    let value: CGFloat
    let onSample: (Double) -> Void

    var body: some View {
        Color.clear
            .modifier(MotionTraceSampleEffect(value: value, onSample: onSample))
            .frame(width: 0, height: 0)
            .onAppear {
                onSample(Double(value))
            }
    }
}

private struct MotionTraceSampleEffect: GeometryEffect {
    var value: CGFloat
    let onSample: (Double) -> Void

    var animatableData: CGFloat {
        get { value }
        set {
            value = newValue
            onSample(Double(newValue))
        }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform.identity)
    }
}

private struct MotionGeometryProbeView: View {
    let space: UncheckedGeometrySpace
    let source: MotionGeometrySource
    let onFrameChange: (CGRect) -> Void

    @ViewBuilder
    var body: some View {
        switch source {
        case .layout:
            switch space.value {
            case let .swiftUI(coordinateSpace):
                MotionSwiftUILayoutGeometryProbeView(
                    coordinateSpace: UncheckedCoordinateSpace(value: coordinateSpace),
                    onFrameChange: onFrameChange
                )
            #if !os(watchOS)
            case .window, .screen:
                MotionPlatformGeometryProbeView(
                    space: space.value,
                    source: source,
                    onFrameChange: onFrameChange
                )
            #endif
            }
        #if !os(watchOS)
        case .presentation:
            MotionPlatformGeometryProbeView(
                space: space.value,
                source: source,
                onFrameChange: onFrameChange
            )
        #endif
        }
    }
}

private struct MotionSwiftUILayoutGeometryProbeView: View {
    let coordinateSpace: UncheckedCoordinateSpace
    let onFrameChange: (CGRect) -> Void

    var body: some View {
        Color.clear
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: coordinateSpace.value)
            } action: { newFrame in
                onFrameChange(newFrame)
            }
            .frame(width: 0, height: 0)
    }
}

#if !os(watchOS)
private struct MotionPlatformGeometryProbeView: View {
    let space: MotionGeometrySpace
    let source: MotionGeometrySource
    let onFrameChange: (CGRect) -> Void

    @ViewBuilder
    var body: some View {
        #if canImport(UIKit) && (os(iOS) || os(tvOS) || os(visionOS))
        MotionUIKitGeometryProbeRepresentable(
            space: space,
            source: source,
            onFrameChange: onFrameChange
        )
        .frame(width: 0, height: 0)
        #elseif canImport(AppKit) && os(macOS)
        MotionAppKitGeometryProbeRepresentable(
            space: space,
            source: source,
            onFrameChange: onFrameChange
        )
        .frame(width: 0, height: 0)
        #else
        Color.clear.frame(width: 0, height: 0)
        #endif
    }
}
#endif

#if canImport(UIKit) && (os(iOS) || os(tvOS) || os(visionOS))
private struct MotionUIKitGeometryProbeRepresentable: UIViewRepresentable {
    let space: MotionGeometrySpace
    let source: MotionGeometrySource
    let onFrameChange: (CGRect) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            space: space,
            source: source,
            onFrameChange: onFrameChange
        )
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        context.coordinator.attach(to: view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.update(
            space: space,
            source: source,
            onFrameChange: onFrameChange
        )
        context.coordinator.attach(to: uiView)
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.detach()
    }

    @MainActor
    final class Coordinator: NSObject {
        private var space: MotionGeometrySpace
        private var source: MotionGeometrySource
        private var onFrameChange: (CGRect) -> Void

        private weak var view: UIView?
        private var displayLink: CADisplayLink?

        init(
            space: MotionGeometrySpace,
            source: MotionGeometrySource,
            onFrameChange: @escaping (CGRect) -> Void
        ) {
            self.space = space
            self.source = source
            self.onFrameChange = onFrameChange
            super.init()
        }

        func attach(to view: UIView) {
            self.view = view
            startSamplingIfNeeded()
            sampleFrame()
        }

        func update(
            space: MotionGeometrySpace,
            source: MotionGeometrySource,
            onFrameChange: @escaping (CGRect) -> Void
        ) {
            self.space = space
            self.source = source
            self.onFrameChange = onFrameChange
            sampleFrame()
        }

        func detach() {
            displayLink?.invalidate()
            displayLink = nil
            view = nil
        }

        private func startSamplingIfNeeded() {
            guard displayLink == nil else { return }
            let displayLink = CADisplayLink(target: self, selector: #selector(step))
            self.displayLink = displayLink
            displayLink.add(to: .main, forMode: .common)
        }

        @objc
        private func step() {
            sampleFrame()
        }

        private func sampleFrame() {
            guard let view, let window = view.window else {
                return
            }

            let layoutInWindow = view.convert(view.bounds, to: window)
            let presentationInWindow = Self.presentationFrameInWindow(for: view, window: window)
            let selectedInWindow = MotionGeometryFrameSelector.selectInWindow(
                source: source,
                candidates: MotionGeometryFrameCandidates(
                    layoutInWindow: layoutInWindow,
                    presentationInWindow: presentationInWindow
                )
            )

            let resolvedFrame: CGRect
            switch space {
            case .swiftUI:
                resolvedFrame = selectedInWindow
            case .window:
                resolvedFrame = selectedInWindow
            case .screen:
                resolvedFrame = window.convert(selectedInWindow, to: window.screen.coordinateSpace)
            }

            onFrameChange(resolvedFrame)
        }

        private static func presentationFrameInWindow(
            for view: UIView,
            window: UIWindow
        ) -> CGRect? {
            guard let presentationLayer = view.layer.presentation() else {
                return nil
            }

            if let superlayer = presentationLayer.superlayer {
                return superlayer.convert(presentationLayer.frame, to: window.layer)
            }

            return view.convert(view.bounds, to: window)
        }
    }
}
#endif

#if canImport(AppKit) && os(macOS)
private struct MotionAppKitGeometryProbeRepresentable: NSViewRepresentable {
    let space: MotionGeometrySpace
    let source: MotionGeometrySource
    let onFrameChange: (CGRect) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            space: space,
            source: source,
            onFrameChange: onFrameChange
        )
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        view.wantsLayer = true
        context.coordinator.attach(to: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.update(
            space: space,
            source: source,
            onFrameChange: onFrameChange
        )
        context.coordinator.attach(to: nsView)
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.detach()
    }

    @MainActor
    final class Coordinator: NSObject {
        private var space: MotionGeometrySpace
        private var source: MotionGeometrySource
        private var onFrameChange: (CGRect) -> Void

        private weak var view: NSView?
        private var timer: Timer?

        init(
            space: MotionGeometrySpace,
            source: MotionGeometrySource,
            onFrameChange: @escaping (CGRect) -> Void
        ) {
            self.space = space
            self.source = source
            self.onFrameChange = onFrameChange
            super.init()
        }

        func attach(to view: NSView) {
            self.view = view
            startSamplingIfNeeded()
            sampleFrame()
        }

        func update(
            space: MotionGeometrySpace,
            source: MotionGeometrySource,
            onFrameChange: @escaping (CGRect) -> Void
        ) {
            self.space = space
            self.source = source
            self.onFrameChange = onFrameChange
            sampleFrame()
        }

        func detach() {
            timer?.invalidate()
            timer = nil
            view = nil
        }

        private func startSamplingIfNeeded() {
            guard timer == nil else { return }

            let timer = Timer(
                timeInterval: 1.0 / 60.0,
                target: self,
                selector: #selector(step),
                userInfo: nil,
                repeats: true
            )
            self.timer = timer
            RunLoop.main.add(timer, forMode: .common)
        }

        @objc
        private func step() {
            sampleFrame()
        }

        private func sampleFrame() {
            guard let view, let window = view.window else {
                return
            }

            let layoutInWindow = view.convert(view.bounds, to: nil)
            let presentationInWindow = Self.presentationFrameInWindow(for: view)
            let selectedInWindow = MotionGeometryFrameSelector.selectInWindow(
                source: source,
                candidates: MotionGeometryFrameCandidates(
                    layoutInWindow: layoutInWindow,
                    presentationInWindow: presentationInWindow
                )
            )

            let resolvedFrame: CGRect
            switch space {
            case .swiftUI:
                resolvedFrame = selectedInWindow
            case .window:
                resolvedFrame = selectedInWindow
            case .screen:
                resolvedFrame = window.convertToScreen(selectedInWindow)
            }

            onFrameChange(resolvedFrame)
        }

        private static func presentationFrameInWindow(for view: NSView) -> CGRect? {
            guard
                let presentationLayer = view.layer?.presentation(),
                let superview = view.superview
            else {
                return nil
            }

            let originInSuperview = CGPoint(
                x: presentationLayer.frame.minX,
                y: presentationLayer.frame.minY
            )
            let originInWindow = superview.convert(originInSuperview, to: nil)
            return CGRect(origin: originInWindow, size: presentationLayer.frame.size)
        }
    }
}
#endif

private struct MotionScrollGeometryProbeView: View {
    let properties: Set<MotionScrollGeometryProperty>
    let onComponentsChange: ([String: Double]) -> Void

    var body: some View {
        Color.clear
            .onScrollGeometryChange(for: [String: Double].self) { geometry in
                var components: [String: Double] = [:]
                components.reserveCapacity(properties.count)

                for property in properties.sorted(by: { $0.rawValue < $1.rawValue }) {
                    components[property.rawValue] = property.extract(from: geometry)
                }

                return components
            } action: { _, newComponents in
                onComponentsChange(newComponents)
            }
            .frame(width: 0, height: 0)
    }
}
