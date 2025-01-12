import Foundation.NSBundle
import os.log

public protocol AARLoggable {
  static var logger: Logger { get }
  var logger: Logger { get }
}

extension AARLoggable {
  public static var logger: Logger {
    .init(
      subsystem: Bundle.main.bundleIdentifier!,
      category: String(String(describing: self).trimmingPrefix(/^AAR/))
    )
  }

  public var logger: Logger { Self.logger }
}

/*
 Command line logs streaming:
 > log stream --predicate 'subsystem CONTAINS "dev.duddu.AcceptAirPlayRequests"' --level debug --style compact
 */
