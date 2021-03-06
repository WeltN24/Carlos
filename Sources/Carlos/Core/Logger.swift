import Foundation

/// A simple logger to use instead of println with configurable output closure
public final class Logger {
  /// The level of the logged message
  public enum Level: String {
    case debug = "Debug"
    case info = "Info"
    case warning = "Warning"
    case error = "Error"
  }

  private static let queue = DispatchQueue(label: CarlosGlobals.queueNamePrefix + "logger")

  /**
   Called to output the log message. Override for custom logging.
   */
  public static var output: (String, Level) -> Void = { msg, level in
    queue.async {
      print("[Carlos][\(level.rawValue)]: \(msg)")
    }
  }

  /**
   Logs a message on the console

   - parameter message: The message to log

   This method uses the output closure internally to output the message. The closure is always dispatched on the main queue
   */
  public static func log(_ message: String, _ level: Level = Level.debug) {
    DispatchQueue.main.async {
      self.output(message, level)
    }
  }
}
