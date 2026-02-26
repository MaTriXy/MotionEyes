import SwiftUI
import XCTest
@testable import MotionEyes

final class MotionScrollGeometryPropertyTests: XCTestCase {
    func testScrollGeometryPropertyExtraction() {
        let geometry = ScrollGeometry(
            contentOffset: CGPoint(x: 42, y: 84),
            contentSize: CGSize(width: 900, height: 1500),
            contentInsets: EdgeInsets(top: 12, leading: 16, bottom: 20, trailing: 24),
            containerSize: CGSize(width: 320, height: 640)
        )

        XCTAssertEqual(MotionScrollGeometryProperty.contentOffsetX.extract(from: geometry), Double(geometry.contentOffset.x))
        XCTAssertEqual(MotionScrollGeometryProperty.contentOffsetY.extract(from: geometry), Double(geometry.contentOffset.y))

        XCTAssertEqual(MotionScrollGeometryProperty.visibleRectMinX.extract(from: geometry), Double(geometry.visibleRect.minX))
        XCTAssertEqual(MotionScrollGeometryProperty.visibleRectMinY.extract(from: geometry), Double(geometry.visibleRect.minY))
        XCTAssertEqual(MotionScrollGeometryProperty.visibleRectWidth.extract(from: geometry), Double(geometry.visibleRect.width))
        XCTAssertEqual(MotionScrollGeometryProperty.visibleRectHeight.extract(from: geometry), Double(geometry.visibleRect.height))

        XCTAssertEqual(MotionScrollGeometryProperty.contentSizeWidth.extract(from: geometry), Double(geometry.contentSize.width))
        XCTAssertEqual(MotionScrollGeometryProperty.contentSizeHeight.extract(from: geometry), Double(geometry.contentSize.height))

        XCTAssertEqual(MotionScrollGeometryProperty.containerSizeWidth.extract(from: geometry), Double(geometry.containerSize.width))
        XCTAssertEqual(MotionScrollGeometryProperty.containerSizeHeight.extract(from: geometry), Double(geometry.containerSize.height))

        XCTAssertEqual(MotionScrollGeometryProperty.contentInsetsTop.extract(from: geometry), Double(geometry.contentInsets.top))
        XCTAssertEqual(MotionScrollGeometryProperty.contentInsetsLeading.extract(from: geometry), Double(geometry.contentInsets.leading))
        XCTAssertEqual(MotionScrollGeometryProperty.contentInsetsBottom.extract(from: geometry), Double(geometry.contentInsets.bottom))
        XCTAssertEqual(MotionScrollGeometryProperty.contentInsetsTrailing.extract(from: geometry), Double(geometry.contentInsets.trailing))

        XCTAssertEqual(MotionScrollGeometryProperty.boundsMinX.extract(from: geometry), Double(geometry.bounds.minX))
        XCTAssertEqual(MotionScrollGeometryProperty.boundsMinY.extract(from: geometry), Double(geometry.bounds.minY))
        XCTAssertEqual(MotionScrollGeometryProperty.boundsWidth.extract(from: geometry), Double(geometry.bounds.width))
        XCTAssertEqual(MotionScrollGeometryProperty.boundsHeight.extract(from: geometry), Double(geometry.bounds.height))
    }
}
