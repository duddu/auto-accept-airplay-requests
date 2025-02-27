import Foundation.NSBundle
import Foundation.NSDictionary

public struct AARBundle: AARLoggable {
  private let infoDictionary: [String: Any]?

  init(infoDictionary: [String: Any]? = Bundle.main.infoDictionary.self) {
    self.infoDictionary = infoDictionary
  }

  public var name: String { value(for: kCFBundleNameKey) }
  public var version: String { value(for: "CFBundleShortVersionString") }
  public var buildNumber: String { value(for: kCFBundleVersionKey) }
  public var launchAgentPlist: String { value(for: "AARLaunchAgentPlist") }
  public var docsUrl: String { value(for: "AARDocumentationUrl") }

  private func value(for keyPath: String) -> String {
    guard
      let info = infoDictionary as? NSDictionary,
      let value = info.value(forKeyPath: keyPath) as? String,
      !value.isEmpty
    else {
      logger.error("failed to get info dictionary value for \(keyPath)")
      return "unknown"
    }
    return value
  }

  private func value(for key: CFString) -> String {
    value(for: key as String)
  }
}
