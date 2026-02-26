import SwiftUI

public enum Trace {
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

    public static func geometry(
        _ name: String = "geometry",
        properties: Set<MotionGeometryProperty> = [.minX, .minY, .width, .height],
        in coordinateSpace: CoordinateSpace = .global,
        precision: Int = 2,
        epsilon: Double = 0.1
    ) -> MotionTraceMetric {
        MotionTraceMetric(
            kind: .geometry(
                .init(
                    name: name,
                    properties: properties,
                    coordinateSpace: coordinateSpace,
                    precision: max(0, precision),
                    epsilon: max(0, epsilon)
                )
            )
        )
    }
}
