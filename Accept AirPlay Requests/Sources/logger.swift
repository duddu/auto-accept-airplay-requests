import Foundation.NSBundle
import os.log

/*
 log stream --predicate 'subsystem CONTAINS "dev.duddu."' --level debug --style compact
 */

//public struct AARLogger {
//  private static let bundleId: String = Bundle.main.bundleIdentifier!
//
//  private init() {}
//
//  public static func withLabel(_ label: String) -> Logger {
//    .init(
//       subsystem: bundleId,
//       category: label
//    )
//  }
//}

public protocol AARLoggable {
  static var logger: Logger { get }
//  var logger: Logger { get }

//  init(logger: Logger)
}

public extension AARLoggable {
  static var logger: Logger { .init(
    subsystem: Bundle.main.bundleIdentifier!,
    category: String(String(describing: self).trimmingPrefix(/^AAR/))
  )}

//  init() {
////    self.init(logger: r)
////    self.init(logger: AARLogger()).logger = logger
////    self.logger = AARLogger()
//  }
}

// @TODO loggers dictionary
//public struct AARLogger {}


//struct qewrw: AARLoggable {
//  static func egrh() {
//    logger.debug("egrh")
//  }
//}
//
//class kejrn: AARLoggable {
//  func egrh() {
//    Self.logger.debug("egrh")
//  }
//}
