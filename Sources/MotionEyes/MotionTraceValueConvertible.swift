import CoreGraphics

public protocol MotionTraceValueConvertible {
    func motionTraceComponents() -> [(key: String, value: Double)]
}

extension Double: MotionTraceValueConvertible {
    public func motionTraceComponents() -> [(key: String, value: Double)] {
        [(key: "value", value: self)]
    }
}

extension Float: MotionTraceValueConvertible {
    public func motionTraceComponents() -> [(key: String, value: Double)] {
        [(key: "value", value: Double(self))]
    }
}

extension CGFloat: MotionTraceValueConvertible {
    public func motionTraceComponents() -> [(key: String, value: Double)] {
        [(key: "value", value: Double(self))]
    }
}

extension Int: MotionTraceValueConvertible {
    public func motionTraceComponents() -> [(key: String, value: Double)] {
        [(key: "value", value: Double(self))]
    }
}

extension CGPoint: MotionTraceValueConvertible {
    public func motionTraceComponents() -> [(key: String, value: Double)] {
        [
            (key: "x", value: x),
            (key: "y", value: y),
        ]
    }
}

extension CGSize: MotionTraceValueConvertible {
    public func motionTraceComponents() -> [(key: String, value: Double)] {
        [
            (key: "width", value: width),
            (key: "height", value: height),
        ]
    }
}

extension CGRect: MotionTraceValueConvertible {
    public func motionTraceComponents() -> [(key: String, value: Double)] {
        [
            (key: "x", value: origin.x),
            (key: "y", value: origin.y),
            (key: "width", value: size.width),
            (key: "height", value: size.height),
        ]
    }
}
