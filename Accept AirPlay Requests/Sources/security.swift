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
      logger.debug("accessibility permission granted")
      return .success
    }

    if await promptAccessibilityWarning() != .OK {
      logger.warning("accessibility permission prompt dismissed")
      return .failure(retry: false)
    }

    if
      let privacyAccessibilityPanelUrl = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
      )
    {
      logger.debug("opening accessibility permissions settings")
      NSWorkspace.shared.open(privacyAccessibilityPanelUrl)
    }

    logger.warning("accessibility permission not granted")
    return .failure(retry: true)
  }

  private func promptAccessibilityWarning() async -> NSApplication.ModalResponse {
    return await AARAlert.warning(
      title: "Accessibility permission required",
      message: "This app needs your permission to accept the incoming AirPlay requests notifications.\nPlease go to System Settings > Privacy & Security > Accessibility to authorize it.",
      okButtonTitle: "Open Accessibility Settings",
      cancelButtonTitle: "Quit"
    )
  }
}
