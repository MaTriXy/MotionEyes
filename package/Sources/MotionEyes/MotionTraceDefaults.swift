import OSLog

public enum MotionTraceDefaults {
    #if DEBUG
    public static let enabled = true
    #else
    public static let enabled = false
    #endif

    public static let logger = Logger(subsystem: "MotionEyes", category: "Trace")
}
