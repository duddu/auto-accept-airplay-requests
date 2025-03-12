import AppKit.NSAlert
import AppKit.NSApplication
import AppKit.NSWorkspace

public final actor AARAlert: Actor, Sendable {
  private let style: NSAlert.Style
  private let title: String
  private let message: String
  private let buttons: [String]
  private let delegate = AARAlertDelegate()

  init(
    style: NSAlert.Style,
    title: String,
    message: String,
    buttons: [String]
  ) {
    self.style = style
    self.title = title
    self.message = message
    self.buttons = buttons
  }

  public func run() async -> Response {
    let text = message + getFooterText()

    let runModal = Task { @MainActor in
      let alert = NSAlert()

      alert.alertStyle = style
      alert.messageText = title
      alert.informativeText = text
      alert.showsHelp = true
      alert.delegate = delegate

      buttons.forEach { buttonTitle in
        alert.addButton(withTitle: buttonTitle)
      }

      return alert.runModal()
    }

    let modalResponse = await runModal.result.get()

    return Response(from: modalResponse)
  }

  public struct Response: Hashable, Equatable, RawRepresentable, Sendable {
    public typealias RawValue = NSApplication.ModalResponse.RawValue

    static let button1 = Self(from: .alertFirstButtonReturn)
    static let button2 = Self(from: .alertSecondButtonReturn)
    static let button3 = Self(from: .alertThirdButtonReturn)

    public let rawValue: RawValue

    public init(from modalResponse: NSApplication.ModalResponse) {
      self.init(rawValue: modalResponse.rawValue)
    }

    public init(rawValue: RawValue) {
      switch NSApplication.ModalResponse(rawValue) {
        case .alertFirstButtonReturn, .alertSecondButtonReturn, .alertThirdButtonReturn:
          self.rawValue = rawValue
        default:
          self.rawValue = NSApplication.ModalResponse.cancel.rawValue
      }
    }
  }

  private func getFooterText() -> String {
    let bundle = AARBundle()
    return "\n\n\(bundle.name)\nv\(bundle.version) (\(bundle.buildNumber))"
  }
}

private final class AARAlertDelegate: NSObject, NSAlertDelegate, Sendable, AARLoggable {
  public func alertShowHelp(_: NSAlert) -> Bool {
    logger.debug("show help button pressed")

    if let docsUrl = URL(string: "https://\(AARBundle().docsUrl)/#usage-configuration") {
      logger.debug("opening docs url")
      NSWorkspace.shared.open(docsUrl)
    } else {
      logger.error("failed to open docs url")
    }

    return true
  }
}
