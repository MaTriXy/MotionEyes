import CoreGraphics
import XCTest
@testable import MotionEyes

final class MotionGeometryPropertyTests: XCTestCase {
    func testGeometryPropertyExtraction() {
        let frame = CGRect(x: 10, y: 20, width: 30, height: 40)

        XCTAssertEqual(MotionGeometryProperty.minX.extract(from: frame), 10)
        XCTAssertEqual(MotionGeometryProperty.minY.extract(from: frame), 20)
        XCTAssertEqual(MotionGeometryProperty.midX.extract(from: frame), 25)
        XCTAssertEqual(MotionGeometryProperty.midY.extract(from: frame), 40)
        XCTAssertEqual(MotionGeometryProperty.maxX.extract(from: frame), 40)
        XCTAssertEqual(MotionGeometryProperty.maxY.extract(from: frame), 60)
        XCTAssertEqual(MotionGeometryProperty.width.extract(from: frame), 30)
        XCTAssertEqual(MotionGeometryProperty.height.extract(from: frame), 40)
    }
}
