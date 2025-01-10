import Foundation.NSBundle
import os.log

// > log stream --predicate 'subsystem CONTAINS "dev.duddu.AcceptAirPlayRequests"' --level debug --style compact

public protocol AARLoggable {
  static var logger: Logger { get }
}

extension AARLoggable {
  public static var logger: Logger {
    .init(
      subsystem: Bundle.main.bundleIdentifier!,
      category: String(String(describing: self).trimmingPrefix(/^AAR/))
    )
  }
}
