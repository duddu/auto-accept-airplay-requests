import AppKit.NSAlert
import AppKit.NSApplication

@frozen public enum AARAlertResult: Sendable {
  case ok
  case dismiss
}

@MainActor public final class AARAlert {
  private let alert = NSAlert()

  public init(
    style: NSAlert.Style = .informational,
    title: String,
    message: String,
    okBtnTitle: String = "OK",
    dismissBtnTitle: String? = nil
  ) {
    self.alert.alertStyle = style
    self.alert.messageText = title
    self.alert.informativeText = message
    self.alert.addButton(withTitle: okBtnTitle)
    if let dismissBtnTitle {
      self.alert.addButton(withTitle: dismissBtnTitle)
    }
  }

  public final func run() -> AARAlertResult {
    let response: NSApplication.ModalResponse = self.alert.runModal()
    return response == .alertSecondButtonReturn || response == .abort
      || response == .cancel || response == .stop
        ? .dismiss
        : .ok
  }
}
