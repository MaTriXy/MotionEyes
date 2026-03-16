import XCTest
@testable import MotionEyes

final class MotionSmoothnessTests: XCTestCase {
    func testLinearMotionScoresPerfectlySmooth() {
        let result = MotionSmoothness.evaluate([0, 0.25, 0.5, 0.75, 1.0])

        XCTAssertEqual(result.score, 1, accuracy: 0.0001)
        XCTAssertEqual(result.jumpConsistency, 1, accuracy: 0.0001)
        XCTAssertEqual(result.worstLocalStepRatio, 1, accuracy: 0.0001)
        XCTAssertTrue(result.passes(minimumSmoothness: 1))
    }

    func testSmoothStepCurvePassesHighThreshold() {
        let values = stride(from: 0.0, through: 1.0, by: 1.0 / 6.0).map { sample in
            sample * sample * (3 - (2 * sample))
        }

        let result = MotionSmoothness.evaluate(values)

        XCTAssertGreaterThan(result.score, 0.95)
        XCTAssertTrue(MotionSmoothness.isSmooth(values, minimumSmoothness: 0.9))
    }

    func testIntentionalOvershootStillScoresAsSmoothWhenLocalStepsAreConsistent() {
        let values = [0.0, 0.14, 0.31, 0.52, 0.76, 0.98, 1.11, 1.08, 1.03, 1.0]
        let result = MotionSmoothness.evaluate(values)

        XCTAssertGreaterThan(result.score, 0.9)
        XCTAssertTrue(MotionSmoothness.isSmooth(values, minimumSmoothness: 0.85))
    }

    func testSingleLocalJumpFailsStrictThreshold() {
        let values = [0.0, 0.05, 0.12, 0.21, 0.62, 0.71, 0.79, 0.86, 0.92, 0.97, 1.0]
        let result = MotionSmoothness.evaluate(values)

        XCTAssertGreaterThan(result.worstLocalStepRatio, 4)
        XCTAssertLessThan(result.score, 0.7)
        XCTAssertFalse(MotionSmoothness.isSmooth(values, minimumSmoothness: 0.8))
    }

    func testDirectionChangesDoNotFailSmoothnessByThemselves() {
        let values = [0.0, 0.18, 0.36, 0.52, 0.61, 0.58, 0.54, 0.57, 0.63, 0.68]
        let result = MotionSmoothness.evaluate(values)

        XCTAssertGreaterThan(result.score, 0.85)
        XCTAssertTrue(MotionSmoothness.isSmooth(values, minimumSmoothness: 0.8))
    }

    func testStaticAndShortTracesAreTreatedAsSmooth() {
        XCTAssertEqual(MotionSmoothness.evaluate([]).score, 1, accuracy: 0.0001)
        XCTAssertEqual(MotionSmoothness.evaluate([0.4]).score, 1, accuracy: 0.0001)
        XCTAssertEqual(MotionSmoothness.evaluate([0.4, 0.4, 0.4]).score, 1, accuracy: 0.0001)
    }

    func testMinimumSmoothnessIsClamped() {
        let values = [0.0, 0.1, 0.2, 0.8, 0.9, 1.0]

        XCTAssertTrue(MotionSmoothness.isSmooth(values, minimumSmoothness: -1))
        XCTAssertFalse(MotionSmoothness.isSmooth(values, minimumSmoothness: 2))
    }
}
