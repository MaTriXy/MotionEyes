import CoreGraphics
import XCTest
@testable import MotionEyes

final class MotionGeometryFrameSelectorTests: XCTestCase {
    func testLayoutSourceUsesLayoutFrame() {
        let candidates = MotionGeometryFrameCandidates(
            layoutInWindow: CGRect(x: 10, y: 20, width: 120, height: 44),
            presentationInWindow: CGRect(x: 10, y: 23, width: 120, height: 44)
        )

        let selected = MotionGeometryFrameSelector.selectInWindow(
            source: .layout,
            candidates: candidates
        )

        XCTAssertEqual(selected.minY, 20)
        XCTAssertEqual(selected.height, 44)
    }

    #if !os(watchOS)
    func testPresentationSourceUsesPresentationFrameWhenAvailable() {
        let candidates = MotionGeometryFrameCandidates(
            layoutInWindow: CGRect(x: 10, y: 20, width: 120, height: 44),
            presentationInWindow: CGRect(x: 10, y: 23, width: 120, height: 44)
        )

        let selected = MotionGeometryFrameSelector.selectInWindow(
            source: .presentation,
            candidates: candidates
        )

        XCTAssertEqual(selected.minY, 23)
        XCTAssertEqual(selected.height, 44)
    }

    func testPresentationSourceFallsBackToLayoutWhenPresentationIsMissing() {
        let candidates = MotionGeometryFrameCandidates(
            layoutInWindow: CGRect(x: 10, y: 20, width: 120, height: 44),
            presentationInWindow: nil
        )

        let selected = MotionGeometryFrameSelector.selectInWindow(
            source: .presentation,
            candidates: candidates
        )

        XCTAssertEqual(selected.minY, 20)
        XCTAssertEqual(selected.height, 44)
    }

    func testPresentationSourceRevealsMovementNotVisibleInLayoutSource() {
        let before = MotionGeometryFrameCandidates(
            layoutInWindow: CGRect(x: 10, y: 20, width: 120, height: 44),
            presentationInWindow: CGRect(x: 10, y: 20, width: 120, height: 44)
        )
        let after = MotionGeometryFrameCandidates(
            layoutInWindow: CGRect(x: 10, y: 20, width: 120, height: 44),
            presentationInWindow: CGRect(x: 10, y: 23, width: 120, height: 44)
        )

        let layoutDeltaY = MotionGeometryFrameSelector
            .selectInWindow(source: .layout, candidates: after).minY
            - MotionGeometryFrameSelector
            .selectInWindow(source: .layout, candidates: before).minY

        let presentationDeltaY = MotionGeometryFrameSelector
            .selectInWindow(source: .presentation, candidates: after).minY
            - MotionGeometryFrameSelector
            .selectInWindow(source: .presentation, candidates: before).minY

        XCTAssertEqual(layoutDeltaY, 0)
        XCTAssertEqual(presentationDeltaY, 3)
    }
    #endif
}
