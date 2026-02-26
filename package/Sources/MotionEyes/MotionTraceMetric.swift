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
}
