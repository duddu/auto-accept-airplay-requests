import AppKit.NSWorkspace
import ApplicationServices.HIServices
import ServiceManagement.SMAppService

public struct AARSecurityManager: Sendable, AARLoggable {
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

    let alertResponse = await displayAccessibilityWarning()

    if alertResponse == .button2 {
      logger.error("accessibility permission refused")
      SMAppService.openSystemSettingsLoginItems()
      return .failure(.permissionRefused)
    }

    if
      alertResponse == .button1,
      let privacyAccessibilityPanelUrl = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
      )
    {
      logger.debug("opening accessibility settings")
      NSWorkspace.shared.open(privacyAccessibilityPanelUrl)
    }

    logger.debug("accessibility permission requested")
    return .failure(.permissionRequested)
  }

  private func displayAccessibilityWarning() async -> AARAlert.Response {
    await AARAlert(
      style: .warning,
      title: "Accessibility permission required",
      message: "This app needs your approval to accept the incoming AirPlay requests notifications. Please use the first button below to open System Settings > Privacy & Security > Accessibility, where you can toggle on this app.\nIf instead you changed your mind and prefer to disable this app from running, the second button will open for you System Settings > General > Login Items, where you can completely disable this app from running in the background.",
      buttons: ["Open Accessibility Settings", "Open Login Items Settings"]
    ).run()
  }
}
