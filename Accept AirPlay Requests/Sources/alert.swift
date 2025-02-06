import AppKit.NSAlert
import AppKit.NSApplication
import Foundation.NSBundle

@MainActor
public struct AARAlert {
  private let alert: NSAlert
  private let footerText = "\(AARBundle.name)\nv\(AARBundle.version) (\(AARBundle.buildNumber))"

  private init(
    style: NSAlert.Style,
    title: String,
    message: String,
    okButtonTitle: String?,
    cancelButtonTitle: String?
  ) {
    alert = NSAlert()
    alert.alertStyle = style
    alert.messageText = title
    alert.informativeText = "\(message)\n\n\(footerText)"
    alert.addButton(withTitle: okButtonTitle ?? "OK")
    if let cancelButtonTitle {
      alert.addButton(withTitle: cancelButtonTitle)
    }
  }

  private func run() -> NSApplication.ModalResponse {
    NSApplication.shared.setActivationPolicy(.regular)
    return alert.runModal() == .alertFirstButtonReturn ? .OK : .cancel
  }

  static public func display(
    style: NSAlert.Style,
    title: String,
    message: String,
    okButtonTitle: String? = nil,
    cancelButtonTitle: String? = nil
  ) -> NSApplication.ModalResponse {
    Self
      .init(
        style: style,
        title: title,
        message: message,
        okButtonTitle: okButtonTitle,
        cancelButtonTitle: cancelButtonTitle
      )
      .run()
  }
}
