import AppKit.NSRunningApplication
import Foundation.NSProcessInfo
import os.log

public protocol AARLoggable {
  static var logger: Logger { get }
  var logger: Logger { get }
}

extension AARLoggable {
  static public var logger: Logger {
    .init(
      subsystem: NSRunningApplication.current.bundleIdentifier ?? ProcessInfo.processInfo.processName,
      category: String(String(describing: self).trimmingPrefix("AAR"))
    )
  }

  public var logger: Logger { Self.logger.self }
}
