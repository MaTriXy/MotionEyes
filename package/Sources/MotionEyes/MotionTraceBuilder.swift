@resultBuilder
public enum MotionTraceBuilder {
    /// Combines multiple builder outputs into a single array of metrics.
    public static func buildBlock(_ components: [MotionTraceMetric]...) -> [MotionTraceMetric] {
        components.flatMap { $0 }
    }

    /// Lifts a single metric into the builder output.
    public static func buildExpression(_ expression: MotionTraceMetric) -> [MotionTraceMetric] {
        [expression]
    }

    /// Passes through an array of metrics in the builder.
    public static func buildExpression(_ expression: [MotionTraceMetric]) -> [MotionTraceMetric] {
        expression
    }

    /// Handles optional metric arrays in the builder.
    public static func buildOptional(_ component: [MotionTraceMetric]?) -> [MotionTraceMetric] {
        component ?? []
    }

    /// Selects the first branch in conditional builder logic.
    public static func buildEither(first component: [MotionTraceMetric]) -> [MotionTraceMetric] {
        component
    }

    /// Selects the second branch in conditional builder logic.
    public static func buildEither(second component: [MotionTraceMetric]) -> [MotionTraceMetric] {
        component
    }

    /// Flattens nested metric arrays produced by loops in the builder.
    public static func buildArray(_ components: [[MotionTraceMetric]]) -> [MotionTraceMetric] {
        components.flatMap { $0 }
    }
}
