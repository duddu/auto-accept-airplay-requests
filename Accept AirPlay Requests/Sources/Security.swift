import AppKit.NSWorkspace
import ApplicationServices.HIServices

public struct AARSecurityManager: AARLoggable {
  @frozen public enum AccessibilityError: Error {
    case permissionRefused
    case permissionRequested
  }

  public typealias Result = Swift.Result<Void, AccessibilityError>

  public func ensureAccessibilityPermission() async -> Result {
    logger.debug("ensuring accessibility permission")

    if AXIsProcessTrusted() == true {
      logger.debug("accessibility permission granted")
      return .success(())
    }

    if await alertAccessibilityWarning() != .OK {
      logger.error("accessibility permission refused")
      return .failure(.permissionRefused)
    }

    if let privacyAccessibilityPanelUrl = URL(
      string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    ) {
      logger.debug("opening accessibility permission settings")
      NSWorkspace.shared.open(privacyAccessibilityPanelUrl)
    }

    logger.warning("accessibility permission not granted")
    return .failure(.permissionRequested)
  }

  private func alertAccessibilityWarning() async -> AARAlert.Response {
    await AARAlert.display(
      style: .warning,
      title: "Accessibility permission required",
      message: "This app needs your permission to accept the incoming AirPlay requests notifications.\nPlease go to System Settings > Privacy & Security > Accessibility to authorize it.",
      okButtonTitle: "Open Accessibility Settings",
      cancelButtonTitle: "Terminate"
    )
  }
}
