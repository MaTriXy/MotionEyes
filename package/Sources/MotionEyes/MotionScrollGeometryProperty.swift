import SwiftUI

public enum MotionScrollGeometryProperty: String, CaseIterable, Sendable {
    case contentOffsetX
    case contentOffsetY
    case visibleRectMinX
    case visibleRectMinY
    case visibleRectWidth
    case visibleRectHeight
    case contentSizeWidth
    case contentSizeHeight
    case containerSizeWidth
    case containerSizeHeight
    case contentInsetsTop
    case contentInsetsLeading
    case contentInsetsBottom
    case contentInsetsTrailing
    case boundsMinX
    case boundsMinY
    case boundsWidth
    case boundsHeight
}

extension MotionScrollGeometryProperty {
    func extract(from geometry: ScrollGeometry) -> Double {
        switch self {
        case .contentOffsetX:
            return Double(geometry.contentOffset.x)
        case .contentOffsetY:
            return Double(geometry.contentOffset.y)
        case .visibleRectMinX:
            return Double(geometry.visibleRect.minX)
        case .visibleRectMinY:
            return Double(geometry.visibleRect.minY)
        case .visibleRectWidth:
            return Double(geometry.visibleRect.width)
        case .visibleRectHeight:
            return Double(geometry.visibleRect.height)
        case .contentSizeWidth:
            return Double(geometry.contentSize.width)
        case .contentSizeHeight:
            return Double(geometry.contentSize.height)
        case .containerSizeWidth:
            return Double(geometry.containerSize.width)
        case .containerSizeHeight:
            return Double(geometry.containerSize.height)
        case .contentInsetsTop:
            return Double(geometry.contentInsets.top)
        case .contentInsetsLeading:
            return Double(geometry.contentInsets.leading)
        case .contentInsetsBottom:
            return Double(geometry.contentInsets.bottom)
        case .contentInsetsTrailing:
            return Double(geometry.contentInsets.trailing)
        case .boundsMinX:
            return Double(geometry.bounds.minX)
        case .boundsMinY:
            return Double(geometry.bounds.minY)
        case .boundsWidth:
            return Double(geometry.bounds.width)
        case .boundsHeight:
            return Double(geometry.bounds.height)
        }
    }
}
