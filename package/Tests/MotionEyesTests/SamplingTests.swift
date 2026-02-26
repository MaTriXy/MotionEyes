import XCTest
@testable import MotionEyes

final class SamplingTests: XCTestCase {
    func testFPSClampBounds() {
        XCTAssertEqual(MotionTraceFPS.clamp(-10), 1)
        XCTAssertEqual(MotionTraceFPS.clamp(15), 15)
        XCTAssertEqual(MotionTraceFPS.clamp(500), 120)
    }

    func testFPSIntervalUsesClampedValue() {
        XCTAssertEqual(MotionTraceFPS.interval(for: 15), 1.0 / 15.0, accuracy: 0.000001)
        XCTAssertEqual(MotionTraceFPS.interval(for: 0), 1.0, accuracy: 0.000001)
    }

    @MainActor
    func testDisplayLinkFactoryFallbackBehavior() {
        let sampler = MotionTraceSamplerFactory.make(engine: .displayLink, fps: 15)

        #if canImport(QuartzCore) && (os(iOS) || os(tvOS) || os(visionOS))
        XCTAssertTrue(sampler is DisplayLinkSampler)
        #else
        XCTAssertTrue(sampler is TimerSampler)
        #endif
    }
}
