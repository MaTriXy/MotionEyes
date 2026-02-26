import OSLog
import XCTest
@testable import MotionEyes

@MainActor
final class MotionTraceCoordinatorTests: XCTestCase {
    func testEmitsMarkersAndChangedValues() {
        var lines: [String] = []
        let logger = Logger(subsystem: "MotionEyesTests", category: "Coordinator")

        let coordinator = MotionTraceCoordinator(
            logger: logger,
            sink: { _, message in
                lines.append(message)
            }
        )

        coordinator.configure(viewName: "Input Field View", fps: 15, engine: .timer, logger: logger)

        coordinator.recordValueComponent(
            metricID: "value-0",
            metricName: "opacity",
            componentName: "value",
            value: 0,
            precision: 2,
            epsilon: 0.0001
        )

        coordinator.processTick()
        coordinator.processTick()

        coordinator.recordValueComponent(
            metricID: "value-0",
            metricName: "opacity",
            componentName: "value",
            value: 0.5,
            precision: 2,
            epsilon: 0.0001
        )

        coordinator.processTick()
        coordinator.processTick()

        XCTAssertEqual(lines.count, 4)
        XCTAssertTrue(lines[0].contains("value=0.00"))
        XCTAssertTrue(lines[1].contains("-- Start "))
        XCTAssertTrue(lines[2].contains("value=0.50"))
        XCTAssertTrue(lines[3].contains("-- End "))
    }

    func testLoggerPayloadContainsViewAndMetricNames() {
        var lines: [String] = []
        let logger = Logger(subsystem: "MotionEyesTests", category: "Payload")

        let coordinator = MotionTraceCoordinator(
            logger: logger,
            sink: { _, message in
                lines.append(message)
            }
        )

        coordinator.configure(viewName: "Input Field View", fps: 15, engine: .timer, logger: logger)

        coordinator.recordValueComponent(
            metricID: "value-0",
            metricName: "opacity",
            componentName: "value",
            value: 1,
            precision: 2,
            epsilon: 0.0001
        )

        coordinator.processTick()

        XCTAssertEqual(lines.count, 1)
        XCTAssertTrue(lines[0].contains("[MotionEyes][Input Field View][opacity]"))
    }

    func testStopEmitsEndMarkerForActiveMetric() {
        var lines: [String] = []
        let logger = Logger(subsystem: "MotionEyesTests", category: "Stop")

        let coordinator = MotionTraceCoordinator(
            logger: logger,
            sink: { _, message in
                lines.append(message)
            }
        )

        coordinator.configure(viewName: "Input Field View", fps: 15, engine: .timer, logger: logger)
        coordinator.start()

        coordinator.recordValueComponent(
            metricID: "value-0",
            metricName: "opacity",
            componentName: "value",
            value: 0,
            precision: 2,
            epsilon: 0.0001
        )
        coordinator.processTick() // baseline

        coordinator.recordValueComponent(
            metricID: "value-0",
            metricName: "opacity",
            componentName: "value",
            value: 1,
            precision: 2,
            epsilon: 0.0001
        )
        coordinator.processTick() // start + value
        coordinator.stop() // should emit end

        XCTAssertTrue(lines.contains(where: { $0.contains("-- Start ") }))
        XCTAssertTrue(lines.contains(where: { $0.contains("-- End ") }))
    }
}
