import AppKit.NSApplication
import ServiceManagement.SMAppService

public struct AARServiceManager: AARLoggable {
  private let agent: SMAppService = .agent(plistName: "LaunchAgent.plist")

  @frozen public enum Result: Sendable {
    case success
    case failure
  }

  public func ensureAgentStatus() async -> Result {
    logger.debug("service status \(agent.status.rawValue)")

    switch agent.status {
      case .enabled:
        return .success

      case .requiresApproval:
        await handleBackgroundItemDisabled()
        return .failure

      default:
        await handleAgentRegistration()
        return .failure
    }
  }

  private func handleBackgroundItemDisabled() async {
    logger.error("background item disabled")

    await displayAgentError(
      error: "Background process not allowed",
      message:
        "This app needs to run in the background in order to accept incoming AirPlay notifications on this computer.\nPlease go to System Settings > General > Login Items to allow it."
    )
  }

  private func handleAgentRegistration() async {
    logger.debug("try registration")

    do {
      // @TODO if status != .notRegistered try? await agent.unregister() first
      // @TODO if status = .requiresApproval provide a button way to unregister
      try agent.register()

      logger.info("registration succeeded")
    } catch let error {
      logger.error("registration failed (\(error.localizedDescription, privacy: .public))")

      await displayAgentError(
        error: "Launch Agent registration failed",
        message:
          "This app was unable to register the service to manage the background process.\nPlease check in System Settings > General > Login Items if it's already been registered, or try again after a system reboot.",
        cause: error
      )
    }
  }

  private func displayAgentError(
    error: String,
    message: String,
    cause: (any Error)? = nil
  ) async {
    var details = "Service Status = \(agent.status.rawValue)"
    if let cause {
      details += "; Internal Error = \"\(cause.localizedDescription)\""
    }

    let response: NSApplication.ModalResponse = await AARAlert.error(
      title: error,
      message: "\(message)\n[ \(details) ]",
      okButtonTitle: "Open Login Items Settings",
      cancelButtonTitle: "Quit"
    )

    if response == .OK {
      SMAppService.openSystemSettingsLoginItems()
    }
  }
}
