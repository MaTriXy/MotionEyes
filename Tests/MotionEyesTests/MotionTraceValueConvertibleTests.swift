import CoreGraphics
import XCTest
@testable import MotionEyes

final class MotionTraceValueConvertibleTests: XCTestCase {
    func testCGPointComponents() {
        let value = CGPoint(x: 4, y: 8)
        let components = Dictionary(uniqueKeysWithValues: value.motionTraceComponents())

        XCTAssertEqual(components["x"], 4)
        XCTAssertEqual(components["y"], 8)
    }

    func testCGRectComponents() {
        let value = CGRect(x: 1, y: 2, width: 3, height: 4)
        let components = Dictionary(uniqueKeysWithValues: value.motionTraceComponents())

        XCTAssertEqual(components["x"], 1)
        XCTAssertEqual(components["y"], 2)
        XCTAssertEqual(components["width"], 3)
        XCTAssertEqual(components["height"], 4)
    }
}
