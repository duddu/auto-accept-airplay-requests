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
        await handleBackgroundItem()
        return .failure

      default:
        await handleRegistration()
        return .failure
    }
  }

  private func handleBackgroundItem() async {
    logger.error("background item disabled")

    await displayAgentError(
      error: "Background item not allowed",
      message:
        "This app needs to run in the background in order to accept incoming AirPlay requests on this computer.\nPlease enable this app's background item in System Settings > General > Login Items."
    )

    SMAppService.openSystemSettingsLoginItems()
  }

  private func handleRegistration() async {
    logger.debug("try registration")

    do {
      // @TODO try? await agent.unregister() first if status != .notRegistered
      // @TODO provide a way to easily unregister (e.g. an alert button if status = .requiresApproval)
      try agent.register()

      logger.info("registration succeeded")
    } catch let error {
      logger.error("registration failed (\(error.localizedDescription, privacy: .public))")

      await displayAgentError(
        error: "Service registration failed",
        message:
          "Unable to register the launch agent for managing this app in the background. Please check if it’s already registered or try again after restarting your computer.",
        cause: error
      )
    }
  }

  private func displayAgentError(
    error: String,
    message: String,
    cause: (any Error)? = nil
  ) async {
    var details: [String] = []
    if let cause { details.append("Internal Error: \"\(cause.localizedDescription)\"") }
    details.append("Service Status: \(agent.status.rawValue)")

    await AARAlert.error(
      title: "Error: \(error)",
      message: "\(message)\n\n( \(details.joined(separator: ", ")) )"
    )
  }
}
