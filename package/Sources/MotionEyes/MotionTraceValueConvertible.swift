import CoreGraphics

public protocol MotionTraceValueConvertible {
    /// Provides key/value components used to log this value over time.
    func motionTraceComponents() -> [(key: String, value: Double)]
}

extension Double: MotionTraceValueConvertible {
    /// Returns the scalar value as a single `value` component.
    public func motionTraceComponents() -> [(key: String, value: Double)] {
        [(key: "value", value: self)]
    }
}

extension Float: MotionTraceValueConvertible {
    /// Returns the scalar value as a single `value` component.
    public func motionTraceComponents() -> [(key: String, value: Double)] {
        [(key: "value", value: Double(self))]
    }
}

extension CGFloat: MotionTraceValueConvertible {
    /// Returns the scalar value as a single `value` component.
    public func motionTraceComponents() -> [(key: String, value: Double)] {
        [(key: "value", value: Double(self))]
    }
}

extension Int: MotionTraceValueConvertible {
    /// Returns the scalar value as a single `value` component.
    public func motionTraceComponents() -> [(key: String, value: Double)] {
        [(key: "value", value: Double(self))]
    }
}

extension CGPoint: MotionTraceValueConvertible {
    /// Returns the `x` and `y` components of the point.
    public func motionTraceComponents() -> [(key: String, value: Double)] {
        [
            (key: "x", value: x),
            (key: "y", value: y),
        ]
    }
}

extension CGSize: MotionTraceValueConvertible {
    /// Returns the `width` and `height` components of the size.
    public func motionTraceComponents() -> [(key: String, value: Double)] {
        [
            (key: "width", value: width),
            (key: "height", value: height),
        ]
    }
}

extension CGRect: MotionTraceValueConvertible {
    /// Returns the origin (`x`, `y`) and size (`width`, `height`) components of the rect.
    public func motionTraceComponents() -> [(key: String, value: Double)] {
        [
            (key: "x", value: origin.x),
            (key: "y", value: origin.y),
            (key: "width", value: size.width),
            (key: "height", value: size.height),
        ]
    }
}
