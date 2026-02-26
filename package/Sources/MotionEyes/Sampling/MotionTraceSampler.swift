import Foundation

#if canImport(QuartzCore)
import QuartzCore
#endif

protocol MotionTraceSampler: AnyObject {
    var fps: Int { get set }
    var onTick: (() -> Void)? { get set }

    func start()
    func stop()
}

enum MotionTraceFPS {
    static func clamp(_ fps: Int) -> Int {
        min(max(fps, 1), 120)
    }

    static func interval(for fps: Int) -> TimeInterval {
        1.0 / Double(clamp(fps))
    }
}

final class TimerSampler: NSObject, MotionTraceSampler {
    var fps: Int {
        didSet {
            fps = MotionTraceFPS.clamp(fps)
            restartIfNeeded()
        }
    }

    var onTick: (() -> Void)?

    private var timer: Timer?
    private var isRunning = false

    init(fps: Int) {
        self.fps = MotionTraceFPS.clamp(fps)
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        scheduleTimer()
    }

    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func restartIfNeeded() {
        guard isRunning else { return }
        timer?.invalidate()
        timer = nil
        scheduleTimer()
    }

    private func scheduleTimer() {
        let interval = MotionTraceFPS.interval(for: fps)
        let timer = Timer(
            timeInterval: interval,
            target: self,
            selector: #selector(handleTick),
            userInfo: nil,
            repeats: true
        )

        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    @objc
    private func handleTick() {
        onTick?()
    }
}

#if canImport(QuartzCore) && (os(iOS) || os(tvOS) || os(visionOS))
final class DisplayLinkSampler: NSObject, MotionTraceSampler {
    var fps: Int {
        didSet {
            fps = MotionTraceFPS.clamp(fps)
            updatePreferredFrameRate()
        }
    }

    var onTick: (() -> Void)?

    private var displayLink: CADisplayLink?
    private var lastFireTimestamp: CFTimeInterval = 0

    init(fps: Int) {
        self.fps = MotionTraceFPS.clamp(fps)
        super.init()
    }

    func start() {
        guard displayLink == nil else { return }

        let displayLink = CADisplayLink(target: self, selector: #selector(step(_:)))
        self.displayLink = displayLink
        updatePreferredFrameRate()
        displayLink.add(to: .main, forMode: .common)
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        lastFireTimestamp = 0
    }

    private func updatePreferredFrameRate() {
        guard let displayLink else { return }

        if #available(iOS 15.0, tvOS 15.0, visionOS 1.0, *) {
            let value = Float(fps)
            displayLink.preferredFrameRateRange = CAFrameRateRange(
                minimum: value,
                maximum: value,
                preferred: value
            )
        } else {
            displayLink.preferredFramesPerSecond = fps
        }
    }

    @objc
    private func step(_ displayLink: CADisplayLink) {
        let requiredDelta = MotionTraceFPS.interval(for: fps)
        let timestamp = displayLink.timestamp

        if lastFireTimestamp == 0 || (timestamp - lastFireTimestamp) >= (requiredDelta - 0.0005) {
            lastFireTimestamp = timestamp
            onTick?()
        }
    }
}
#endif

enum MotionTraceSamplerFactory {
    static func make(engine: MotionTraceEngine, fps: Int) -> any MotionTraceSampler {
        switch engine {
        case .timer:
            return TimerSampler(fps: fps)
        case .displayLink:
            #if canImport(QuartzCore) && (os(iOS) || os(tvOS) || os(visionOS))
            return DisplayLinkSampler(fps: fps)
            #else
            return TimerSampler(fps: fps)
            #endif
        }
    }

    static var supportsNativeDisplayLink: Bool {
        #if canImport(QuartzCore) && (os(iOS) || os(tvOS) || os(visionOS))
        true
        #else
        false
        #endif
    }
}
