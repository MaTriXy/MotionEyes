import XCTest
@testable import MotionEyes

final class TraceTests: XCTestCase {
    func testGeometryUsesExpectedDefaults() {
        let metric = Trace.geometry()

        guard case let .geometry(spec) = metric.kind else {
            XCTFail("Expected geometry metric kind")
            return
        }

        XCTAssertEqual(spec.name, "geometry")
        XCTAssertEqual(spec.properties, [.minX, .minY, .width, .height])
        XCTAssertEqual(spec.precision, 2)
        XCTAssertEqual(spec.epsilon, 0.1)

#if os(watchOS)
        XCTAssertEqual(spec.source, .layout)

        guard case .swiftUI(.global) = spec.space else {
            XCTFail("Expected default geometry space to be .swiftUI(.global)")
            return
        }
#else
        XCTAssertEqual(spec.source, .presentation)

        guard case .screen = spec.space else {
            XCTFail("Expected default geometry space to be .screen")
            return
        }
#endif
    }

    func testGeometryAppliesCustomValuesAndClamps() {
        let metric = Trace.geometry(
            "onScreen",
            properties: [.minY, .height],
            space: .screen,
            source: .presentation,
            precision: -4,
            epsilon: -1
        )

        guard case let .geometry(spec) = metric.kind else {
            XCTFail("Expected geometry metric kind")
            return
        }

        XCTAssertEqual(spec.name, "onScreen")
        XCTAssertEqual(spec.properties, [.minY, .height])
        XCTAssertEqual(spec.source, .presentation)
        XCTAssertEqual(spec.precision, 0)
        XCTAssertEqual(spec.epsilon, 0)

        guard case .screen = spec.space else {
            XCTFail("Expected geometry space to be .screen")
            return
        }
    }

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
