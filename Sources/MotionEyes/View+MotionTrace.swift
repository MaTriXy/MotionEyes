import OSLog
@preconcurrency import SwiftUI

private struct UncheckedCoordinateSpace: @unchecked Sendable {
    let value: CoordinateSpace
}

public extension View {
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
        let coordinateSpace: UncheckedCoordinateSpace
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
            case .geometry:
                return []
            }
        }
    }

    private var geometryProbes: [GeometryProbeInput] {
        metrics.enumerated().compactMap { index, metric in
            switch metric.kind {
            case .value:
                return nil
            case let .geometry(spec):
                return GeometryProbeInput(
                    id: "geometry-\(index)",
                    metricID: "geometry-\(index)",
                    metricName: spec.name,
                    properties: spec.properties,
                    coordinateSpace: UncheckedCoordinateSpace(value: spec.coordinateSpace),
                    precision: spec.precision,
                    epsilon: spec.epsilon
                )
            }
        }
    }

    private var activeMetricIDs: [String] {
        let ids = valueProbes.map(\.metricID) + geometryProbes.map(\.metricID)
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
                MotionGeometryProbeView(coordinateSpace: probe.coordinateSpace) { frame in
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
