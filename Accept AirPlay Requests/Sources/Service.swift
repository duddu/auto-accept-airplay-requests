import ServiceManagement.SMAppService

public struct AARServiceManager: Sendable, AARLoggable {
  @frozen public enum AgentError: Error {
    case invalidStatus
  }

  public typealias Result = Swift.Result<Void, AgentError>

  private var agentPlist: String { AARBundle().launchAgentLabel + ".plist" }
  private var agent: SMAppService { .agent(plistName: agentPlist) }

  public func ensureAgentStatus() async -> Result {
    logger.debug("ensuring agent status")

    switch agent.status {
      case .enabled:
        logger.debug("service status enabled")
        return .success(())

      case .requiresApproval:
        logger.error("service status disabled")
        await handleAgentDisabled()
        break

      default:
        logger.error("service status \(agent.status.rawValue)")
        await handleAgentRegistration()
        break
    }

    return .failure(.invalidStatus)
  }

  private func handleAgentDisabled() async {
    await alertAgentError(
      error: "Background process not allowed",
      message:
        "This app needs permission to run in the background in order to accept incoming AirPlay notifications on this computer.\nPlease go to System Settings > General > Login Items to allow it."
    )
  }

  private func handleAgentRegistration() async {
    logger.debug("trying agent registration")

    do {
      // @TODO if status != .notRegistered try? await agent.unregister() first
      // @TODO if status = .requiresApproval provide a button way to unregister
      try agent.register()

      logger.info("registration succeeded")
    } catch let error {
      logger.error("registration failed (\(error.localizedDescription, privacy: .public))")

      await alertAgentError(
        error: "Launch Agent registration failed",
        message:
          "This app was unable to register the service to manage the background process.\nPlease check in System Settings > General > Login Items if it's already been registered, or try again after a system reboot.",
        cause: error
      )
    }
  }

  private func alertAgentError(
    error: String,
    message: String,
    cause: (any Error)? = nil
  ) async {
    var details = "Service Status = \(agent.status.rawValue)"
    if let cause {
      details += "; Internal Error = \"\(cause.localizedDescription)\""
    }

    if await AARAlert.display(
      style: .critical,
      title: error,
      message: "\(message)\n[ \(details) ]",
      okButtonTitle: "Open Login Items Settings",
      cancelButtonTitle: "Quit"
    ) == .OK {
      SMAppService.openSystemSettingsLoginItems()
    }
  }

  static public func alertAgentInfo() async {
    if await AARAlert.display(
      style: .informational,
      title: "Application running in the background",
      message: "This app is currently already running as a background process, waiting for AirPlay notifications requests to accept.\nTo manage this process, or prevent it from automatically start when you log in, open System Settings > General > Login Items.",
      okButtonTitle: "Got it",
      cancelButtonTitle: "Open Login Items Settings"
    ) == .cancel {
      SMAppService.openSystemSettingsLoginItems()
    }
  }
}
