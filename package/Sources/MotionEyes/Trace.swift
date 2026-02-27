import SwiftUI

public enum Trace {
    /// Traces a scalar or structured value over time.
    public static func value<V: MotionTraceValueConvertible>(
        _ propertyName: String,
        _ value: V,
        precision: Int = 3,
        epsilon: Double = 0.0001
    ) -> MotionTraceMetric {
        MotionTraceMetric(
            kind: .value(
                .init(
                    name: propertyName,
                    components: value.motionTraceComponents(),
                    precision: max(0, precision),
                    epsilon: max(0, epsilon)
                )
            )
        )
    }

    /// Traces view geometry in a selected coordinate `space` and `source`.
    ///
    /// - Parameters:
    ///   - name: Metric label used in log output.
    ///   - properties: Geometry components to emit (for example, `minY`, `height`).
    ///   - space: Coordinate target for emitted values.
    ///   - source: Layout (`.layout`) or visible presentation (`.presentation`) geometry.
    ///   - precision: Decimal precision for logged values.
    ///   - epsilon: Minimum delta required before values are emitted as changed.
#if os(watchOS)
    public static func geometry(
        _ name: String = "geometry",
        properties: Set<MotionGeometryProperty> = [.minX, .minY, .width, .height],
        space: MotionGeometrySpace = .swiftUI(.global),
        source: MotionGeometrySource = .layout,
        precision: Int = 2,
        epsilon: Double = 0.1
    ) -> MotionTraceMetric {
        geometryMetric(
            name: name,
            properties: properties,
            space: space,
            source: source,
            precision: precision,
            epsilon: epsilon
        )
    }
#else
    public static func geometry(
        _ name: String = "geometry",
        properties: Set<MotionGeometryProperty> = [.minX, .minY, .width, .height],
        space: MotionGeometrySpace = .screen,
        source: MotionGeometrySource = .presentation,
        precision: Int = 2,
        epsilon: Double = 0.1
    ) -> MotionTraceMetric {
        geometryMetric(
            name: name,
            properties: properties,
            space: space,
            source: source,
            precision: precision,
            epsilon: epsilon
        )
    }
#endif

    private static func geometryMetric(
        name: String,
        properties: Set<MotionGeometryProperty>,
        space: MotionGeometrySpace,
        source: MotionGeometrySource,
        precision: Int,
        epsilon: Double
    ) -> MotionTraceMetric {
        MotionTraceMetric(
            kind: .geometry(
                .init(
                    name: name,
                    properties: properties,
                    space: space,
                    source: source,
                    precision: max(0, precision),
                    epsilon: max(0, epsilon)
                )
            )
        )
    }

    /// Traces `ScrollView` runtime geometry values (offset, visible rect, insets, size).
    public static func scrollGeometry(
        _ name: String = "scrollGeometry",
        properties: Set<MotionScrollGeometryProperty> = [
            .contentOffsetX,
            .contentOffsetY,
            .visibleRectMinY,
            .visibleRectHeight,
        ],
        precision: Int = 2,
        epsilon: Double = 0.1
    ) -> MotionTraceMetric {
        MotionTraceMetric(
            kind: .scrollGeometry(
                .init(
                    name: name,
                    properties: properties,
                    precision: max(0, precision),
                    epsilon: max(0, epsilon)
                )
            )
        )
    }
}
