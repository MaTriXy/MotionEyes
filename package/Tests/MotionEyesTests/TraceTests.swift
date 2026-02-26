import XCTest
@testable import MotionEyes

final class TraceTests: XCTestCase {
    func testScrollGeometryUsesExpectedDefaults() {
        let metric = Trace.scrollGeometry()

        guard case let .scrollGeometry(spec) = metric.kind else {
            XCTFail("Expected scrollGeometry metric kind")
            return
        }

        XCTAssertEqual(spec.name, "scrollGeometry")
        XCTAssertEqual(
            spec.properties,
            [
                .contentOffsetX,
                .contentOffsetY,
                .visibleRectMinY,
                .visibleRectHeight,
            ]
        )
        XCTAssertEqual(spec.precision, 2)
        XCTAssertEqual(spec.epsilon, 0.1)
    }

    func testScrollGeometryAppliesCustomValuesAndClamps() {
        let metric = Trace.scrollGeometry(
            "chatScroll",
            properties: [.contentOffsetY, .contentSizeHeight],
            precision: -4,
            epsilon: -1
        )

        guard case let .scrollGeometry(spec) = metric.kind else {
            XCTFail("Expected scrollGeometry metric kind")
            return
        }

        XCTAssertEqual(spec.name, "chatScroll")
        XCTAssertEqual(spec.properties, [.contentOffsetY, .contentSizeHeight])
        XCTAssertEqual(spec.precision, 0)
        XCTAssertEqual(spec.epsilon, 0)
    }
}
