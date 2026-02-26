import SwiftUI

public struct MotionTraceMetric {
    let kind: Kind

    init(kind: Kind) {
        self.kind = kind
    }
}

extension MotionTraceMetric {
    enum Kind {
        case value(ValueSpec)
        case geometry(GeometrySpec)
        case scrollGeometry(ScrollGeometrySpec)
    }

    struct ValueSpec {
        let name: String
        let components: [(key: String, value: Double)]
        let precision: Int
        let epsilon: Double
    }

    struct GeometrySpec {
        let name: String
        let properties: Set<MotionGeometryProperty>
        let coordinateSpace: CoordinateSpace
        let precision: Int
        let epsilon: Double
    }

    struct ScrollGeometrySpec {
        let name: String
        let properties: Set<MotionScrollGeometryProperty>
        let precision: Int
        let epsilon: Double
    }
}
