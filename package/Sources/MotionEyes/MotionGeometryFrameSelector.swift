import CoreGraphics

struct MotionGeometryFrameCandidates {
    let layoutInWindow: CGRect
    let presentationInWindow: CGRect?
}

enum MotionGeometryFrameSelector {
    static func selectInWindow(
        source: MotionGeometrySource,
        candidates: MotionGeometryFrameCandidates
    ) -> CGRect {
        switch source {
        case .layout:
            return candidates.layoutInWindow
        #if !os(watchOS)
        case .presentation:
            return candidates.presentationInWindow ?? candidates.layoutInWindow
        #endif
        }
    }
}
