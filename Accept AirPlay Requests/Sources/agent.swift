import AppKit.NSApplication
import ServiceManagement.SMAppService

@MainActor public struct AARAgentManager {
  static private var service: SMAppService { .agent(plistName: "LaunchAgent.plist") }

  static public func initialize() {
    ensureServiceStatus()
  }

  static private func displayErrorAndExit(
    title: String, message: String, onBeforeExit block: (() -> Void)? = nil
  ) {
    _ = AARAlert(style: .critical, title: title, message: message).run()
    if let block { block() }
    return NSApp.terminate(self)
  }

  static private func tryRegisterService(errorTitle: String, errorMessage: String) {
    do {
      try service.register()
      return NSApp.terminate(self)
    } catch let error {
      return displayErrorAndExit(
        title: errorTitle,
        message: "\(errorMessage) -- Registration Error: \(error)"
      )
    }
  }

  static private func ensureServiceStatus() {
    switch service.status {
      case .enabled: break
      case .requiresApproval:
        return displayErrorAndExit(
          title: "SMAppService agent status error",
          message: "requiresApproval",
          onBeforeExit: SMAppService.openSystemSettingsLoginItems
        )
      case .notRegistered:
        return tryRegisterService(
          errorTitle: "SMAppService registration error",
          errorMessage: "notRegistered"
        )
      case .notFound:
        return tryRegisterService(
          errorTitle: "SMAppService agent status error",
          errorMessage: "notFound"
        )
      default:
        return tryRegisterService(
          errorTitle: "SMAppService agent status error",
          errorMessage: "unknown"
        )
    }
  }
}
