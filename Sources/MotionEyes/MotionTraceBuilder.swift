@resultBuilder
public enum MotionTraceBuilder {
    public static func buildBlock(_ components: [MotionTraceMetric]...) -> [MotionTraceMetric] {
        components.flatMap { $0 }
    }

    public static func buildExpression(_ expression: MotionTraceMetric) -> [MotionTraceMetric] {
        [expression]
    }

    public static func buildExpression(_ expression: [MotionTraceMetric]) -> [MotionTraceMetric] {
        expression
    }

    public static func buildOptional(_ component: [MotionTraceMetric]?) -> [MotionTraceMetric] {
        component ?? []
    }

    public static func buildEither(first component: [MotionTraceMetric]) -> [MotionTraceMetric] {
        component
    }

    public static func buildEither(second component: [MotionTraceMetric]) -> [MotionTraceMetric] {
        component
    }

    public static func buildArray(_ components: [[MotionTraceMetric]]) -> [MotionTraceMetric] {
        components.flatMap { $0 }
    }
}
