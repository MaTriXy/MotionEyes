import CoreGraphics

public enum MotionGeometryProperty: String, CaseIterable, Sendable {
    case minX
    case minY
    case midX
    case midY
    case maxX
    case maxY
    case width
    case height
}

extension MotionGeometryProperty {
    func extract(from frame: CGRect) -> Double {
        switch self {
        case .minX:
            return frame.minX
        case .minY:
            return frame.minY
        case .midX:
            return frame.midX
        case .midY:
            return frame.midY
        case .maxX:
            return frame.maxX
        case .maxY:
            return frame.maxY
        case .width:
            return frame.width
        case .height:
            return frame.height
        }
    }
}
