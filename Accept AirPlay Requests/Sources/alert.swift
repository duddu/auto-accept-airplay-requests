import AppKit.NSAlert
import AppKit.NSWorkspace

@MainActor
public struct AARAlert {
  private let alert = NSAlert()
  private lazy var delegate = AARAlertDelegate()

  @frozen public enum Response: Sendable {
    case OK
    case cancel
  }

  private init(
    style: NSAlert.Style,
    title: String,
    message: String,
    okButtonTitle: String?,
    cancelButtonTitle: String?
  ) {
    alert.alertStyle = style
    alert.messageText = title
    alert.informativeText = message + getFooterText()
    alert.addButton(withTitle: okButtonTitle ?? "OK")
    if let cancelButtonTitle {
      alert.addButton(withTitle: cancelButtonTitle)
    }
    alert.showsHelp = true
    alert.delegate = delegate
  }

  private func getFooterText() -> String {
    let bundle = AARBundle()
    return "\n\n\(bundle.name)\nv\(bundle.version) (\(bundle.buildNumber))"
  }

  private func run() -> Response {
    return alert.runModal() == .alertFirstButtonReturn ? .OK : .cancel
  }

  static public func display(
    style: NSAlert.Style,
    title: String,
    message: String,
    okButtonTitle: String? = nil,
    cancelButtonTitle: String? = nil
  ) -> Response {
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

private final class AARAlertDelegate: NSObject, NSAlertDelegate, AARLoggable {
  public func alertShowHelp(_: NSAlert) -> Bool {
    logger.debug("alert show help")

    if let docsUrl = URL(string: "https://\(AARBundle().docsUrl)/#usage-configuration") {
      logger.debug("opening docs url")

      NSWorkspace.shared.open(docsUrl)
    }

    return true
  }
}
