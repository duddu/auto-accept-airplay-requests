import AppKit.NSApplication
import AppKit.NSWorkspace
import ApplicationServices.HIServices

public struct AARSecurityManager: AARLoggable {
  @frozen public enum Result: Sendable {
    case success
    case failure(retry: Bool)
  }

  public func ensureAccessibilityPermission(_ isRetry: Bool) async -> Result {
    if AXIsProcessTrusted() {
      Self.logger.debug("accessibility permission granted")
      return .success
    }

    if await promptAccessibilityWarning(isRetry) != .OK {
      Self.logger.error("accessibility permission prompt dismissed")
      return .failure(retry: false)
    }

    if !isRetry,
      let privacyAccessibilityPanelUrl = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
      )
    {
      Self.logger.info("opening accessibility system settings")
      NSWorkspace.shared.open(privacyAccessibilityPanelUrl)
    }

    Self.logger.error("accessibility permission not granted")
    return .failure(retry: true)
  }

  private func promptAccessibilityWarning(_ isRetry: Bool) async -> NSApplication.ModalResponse {
    var message =
      "This app needs permission to interact with the incoming AirPlay requests notifications. "
    message +=
      !isRetry
      ? "Click the button below to open the Accessibility settings and authorize the app."
      : "Please open System Settings > Privacy & Security > Accessibility and authorize the app. Then click the button below to let the app check again and validate."

    return await AARAlert.warning(
      title: "Accessibility permission required",
      message: message,
      okButtonTitle: !isRetry ? "Open System Settings" : "Check again now",
      cancelButtonTitle: "Quit"
    )
  }
}
