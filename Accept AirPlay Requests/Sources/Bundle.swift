import Foundation.NSBundle
import Foundation.NSDictionary

public struct AARBundle: Sendable, AARLoggable {
  private let bundle: Bundle
  private let unknownValueFallback: String

  init(
    for bundle: Bundle = Bundle.main,
    unknownValueFallback: String = "unknown"
  ) {
    self.bundle = bundle
    self.unknownValueFallback = unknownValueFallback
  }

  public var name: String { value(for: kCFBundleNameKey) }
  public var version: String { value(for: "CFBundleShortVersionString") }
  public var buildNumber: String { value(for: kCFBundleVersionKey) }
  public var launchAgentLabel: String { value(for: "AARLaunchAgentLabel") }
  public var docsUrl: String { value(for: "AARDocumentationUrl") }

  private func value(for keyPath: String) -> String {
    guard
      let info = bundle.infoDictionary as? NSDictionary,
      let value = info.value(forKeyPath: keyPath) as? String,
      !value.isEmpty
    else {
      logger.error("failed to get info dictionary value for \(keyPath)")
      return unknownValueFallback
    }
    return value
  }

  private func value(for key: CFString) -> String {
    value(for: key as String)
  }
}
