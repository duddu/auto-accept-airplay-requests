import AppKit.NSAlert
import AppKit.NSApplication
import Foundation.NSBundle

@MainActor
public struct AARAlert {
  static private let bundleName = Bundle.main.infoDictionary![kCFBundleNameKey as String]!

  private let alert: NSAlert

  private init(
    style: NSAlert.Style,
    title: String,
    message: String,
    okButtonTitle: String?,
    cancelButtonTitle: String?
  ) {
    alert = NSAlert()
    alert.alertStyle = style
    alert.messageText = "\(Self.bundleName)\n\(title)"
    alert.informativeText = message
    alert.addButton(withTitle: okButtonTitle ?? "OK")
    if let cancelButtonTitle {
      alert.addButton(withTitle: cancelButtonTitle)
    }
  }

  private func run() -> NSApplication.ModalResponse {
    return alert.runModal() == .alertFirstButtonReturn ? .OK : .cancel
  }

  static private func display(
    style: NSAlert.Style,
    title: String,
    message: String,
    okButtonTitle: String? = nil,
    cancelButtonTitle: String? = nil
  ) -> NSApplication.ModalResponse {
    Self.init(
      style: style,
      title: title,
      message: message,
      okButtonTitle: okButtonTitle ?? nil,
      cancelButtonTitle: cancelButtonTitle
    ).run()
  }

  static private func display(
    style: NSAlert.Style,
    title: String,
    message: String,
    okButtonTitle: String? = nil
  ) {
    _ = Self.init(
      style: style,
      title: title,
      message: message,
      okButtonTitle: okButtonTitle,
      cancelButtonTitle: nil
    ).run()
  }

  static public func info(
    title: String,
    message: String,
    okButtonTitle: String? = nil
  ) {
    Self.display(
      style: .informational,
      title: title,
      message: message,
      okButtonTitle: okButtonTitle
    )
  }

  static public func warning(
    title: String,
    message: String,
    okButtonTitle: String? = nil,
    cancelButtonTitle: String? = nil
  ) -> NSApplication.ModalResponse {
    Self.display(
      style: .warning,
      title: title,
      message: message,
      okButtonTitle: okButtonTitle,
      cancelButtonTitle: cancelButtonTitle
    )
  }

  static public func error(
    title: String,
    message: String,
    okButtonTitle: String? = nil
  ) {
    Self.display(
      style: .critical,
      title: title,
      message: message,
      okButtonTitle: okButtonTitle
    )
  }
}
