import SwiftUI

/// Selects the coordinate space used when tracing geometry.
public enum MotionGeometrySpace {
    /// Measures using a SwiftUI layout coordinate space.
    ///
    /// This matches SwiftUI's layout model and does not include transient
    /// presentation-layer movement.
    case swiftUI(CoordinateSpace)

    /// Measures relative to the containing window in points.
    ///
    /// Use with ``MotionGeometrySource/presentation`` to detect visible
    /// movement driven by Core Animation.
    @available(watchOS, unavailable, message: "Window geometry tracing is unavailable on watchOS.")
    case window

    /// Measures relative to the physical screen in points.
    ///
    /// This is the closest measurement to "did this move on screen?".
    @available(watchOS, unavailable, message: "Screen geometry tracing is unavailable on watchOS.")
    case screen
}

/// Selects whether geometry is read from layout state or presentation state.
public enum MotionGeometrySource: Sendable, Equatable {
    /// Reads layout/model geometry from the view hierarchy.
    case layout

    /// Reads the Core Animation presentation geometry (visible rendered state).
    @available(watchOS, unavailable, message: "Presentation geometry tracing is unavailable on watchOS.")
    case presentation
}
