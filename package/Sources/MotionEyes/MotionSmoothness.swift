public struct MotionSmoothnessResult: Sendable, Equatable {
    /// Aggregate smoothness score in the range `0...1`.
    ///
    /// `1` means the sampled trace had no abrupt local step outliers at the captured resolution.
    /// Lower values indicate one or more steps jumped sharply relative to nearby steps.
    public let score: Double

    /// How consistent frame-to-frame step sizes were within their local neighborhood.
    ///
    /// `1` means all non-zero steps were locally consistent. Lower values mean one or more steps were much
    /// larger than the steps immediately around them.
    public let jumpConsistency: Double

    /// Largest ratio between any step and the median of its local neighbors.
    ///
    /// `1` means every step matched its surrounding context. Values above `2` usually indicate a visible jump.
    public let worstLocalStepRatio: Double

    /// Largest observed absolute step between adjacent samples.
    public let largestStep: Double

    /// Median absolute step across non-zero samples.
    public let typicalStep: Double

    /// Number of samples that were evaluated.
    public let sampleCount: Int

    public func passes(minimumSmoothness: Double) -> Bool {
        score >= MotionSmoothness.clamp(minimumSmoothness)
    }
}

public enum MotionSmoothness {
    /// Evaluates whether a sampled scalar trace is smooth enough for the requested threshold.
    ///
    /// This is a continuity heuristic for sampled values, not a render-time frame pacing metric.
    /// It works best when the trace captures at least 4-5 moving samples.
    ///
    /// - Parameters:
    ///   - values: Ordered scalar samples from the beginning to the end of the motion segment.
    ///   - minimumSmoothness: Required score in the range `0...1`.
    ///   - epsilon: Values smaller than this are treated as unchanged noise.
    /// - Returns: `true` when the computed score meets `minimumSmoothness`.
    public static func isSmooth(
        _ values: [Double],
        minimumSmoothness: Double = 0.8,
        epsilon: Double = 0.0001
    ) -> Bool {
        evaluate(values, epsilon: epsilon).passes(minimumSmoothness: minimumSmoothness)
    }

    /// Computes a smoothness score for sampled scalar motion.
    ///
    /// The score penalizes single-frame outlier jumps relative to the trace's local step context.
    ///
    /// A score of `1` represents perfect local continuity at the sampled resolution.
    /// This heuristic intentionally ignores direction changes. If a test needs to reject reversals or
    /// backtracking, that should be a separate assertion.
    public static func evaluate(
        _ values: [Double],
        epsilon: Double = 0.9
    ) -> MotionSmoothnessResult {
        let epsilon = max(0, epsilon)

        guard values.count > 1 else {
            return MotionSmoothnessResult(
                score: 1,
                jumpConsistency: 1,
                worstLocalStepRatio: 1,
                largestStep: 0,
                typicalStep: 0,
                sampleCount: values.count
            )
        }

        let steps = zip(values, values.dropFirst()).map { abs($1 - $0) }
        let activeSteps = steps.filter { $0 > epsilon }

        guard !activeSteps.isEmpty else {
            return MotionSmoothnessResult(
                score: 1,
                jumpConsistency: 1,
                worstLocalStepRatio: 1,
                largestStep: 0,
                typicalStep: 0,
                sampleCount: values.count
            )
        }

        let largestStep = activeSteps.max() ?? 0
        let typicalStep = median(activeSteps)
        let worstLocalStepRatio = localOutlierRatio(in: steps, epsilon: epsilon, windowRadius: 2)
        let normalizedJump = max(0, worstLocalStepRatio - 2) / 4
        let jumpConsistency = 1 / (1 + (normalizedJump * normalizedJump))
        let score = clamp(jumpConsistency)

        return MotionSmoothnessResult(
            score: score,
            jumpConsistency: jumpConsistency,
            worstLocalStepRatio: worstLocalStepRatio,
            largestStep: largestStep,
            typicalStep: typicalStep,
            sampleCount: values.count
        )
    }

    static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }

    private static func median(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        let middle = sorted.count / 2

        if sorted.count.isMultiple(of: 2) {
            return (sorted[middle - 1] + sorted[middle]) / 2
        }

        return sorted[middle]
    }

    private static func localOutlierRatio(
        in steps: [Double],
        epsilon: Double,
        windowRadius: Int
    ) -> Double {
        var worstRatio = 1.0

        for index in steps.indices {
            let step = steps[index]
            guard step > epsilon else { continue }

            let lowerBound = max(0, index - windowRadius)
            let upperBound = min(steps.count - 1, index + windowRadius)

            var neighbors: [Double] = []
            neighbors.reserveCapacity((upperBound - lowerBound) + 1)

            for neighborIndex in lowerBound...upperBound where neighborIndex != index {
                let neighbor = steps[neighborIndex]
                if neighbor > epsilon {
                    neighbors.append(neighbor)
                }
            }

            guard !neighbors.isEmpty else { continue }

            let localMedian = median(neighbors)
            guard localMedian > epsilon else { continue }

            worstRatio = max(worstRatio, step / localMedian)
        }

        return worstRatio
    }
}
