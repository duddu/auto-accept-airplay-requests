import AppKit.NSApplication
import ServiceManagement.SMAppService

@MainActor public struct AARAgentManager {
  static private var service: SMAppService { .agent(plistName: "LaunchAgent.plist") }

  static private func displayErrorAndExit(
    title: String = "SMAppService agent status error",
    message: String,
    onBeforeExit: (() -> Void)? = nil
  ) {
    _ = AARAlert(style: .critical, title: title, message: message).run()
    if let onBeforeExit { onBeforeExit() }
    return NSApp.terminate(self)
  }

  static private func tryServiceRegistration(errorMessage: String) {
    do {
      try service.register()
      return NSApp.terminate(self)
    } catch let registrationError {
      return displayErrorAndExit(
        title: "tryServiceRegistration() - \(registrationError)",
        message: errorMessage
      )
    }
  }

  static public func ensureServiceStatus() {
    // @TODO handle manual opening outside launchd
    switch service.status {
      case .enabled: break

      case .requiresApproval:
        return displayErrorAndExit(
          message: "requiresApproval",
          onBeforeExit: SMAppService.openSystemSettingsLoginItems
        )

      case .notRegistered:
        return tryServiceRegistration(
          errorMessage: "notRegistered"
        )

      case .notFound:
        return tryServiceRegistration(
          errorMessage: "notFound"
        )

      default:
        return tryServiceRegistration(
          errorMessage: "unknown"
        )
    }
  }
}
