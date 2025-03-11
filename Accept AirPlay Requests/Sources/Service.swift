import AppKit.NSRunningApplication
import Foundation.NSProcessInfo
import ServiceManagement.SMAppService

public struct AARServiceManager: Sendable, AARLoggable {
  @frozen public enum AgentError: Error {
    case running(SMAppService.Status)
    case notRunning(SMAppService.Status)
  }

  public typealias Result = Swift.Result<Void, AgentError>

  private var agentPlist: String { AARBundle().launchAgentLabel + ".plist" }
  private var agent: SMAppService { .agent(plistName: agentPlist) }
  private var isAgentEnabled: Bool { agent.status == .enabled }

  public var isAgentRunningEnabled: Bool {
    ProcessInfo.processInfo.isLaunchAgent && isAgentEnabled
  }

  public func ensureAgentStatus() async -> Result {
    logger.debug("ensuring launch agent status")

    let initialStatus = agent.status

    guard !ProcessInfo.processInfo.isLaunchAgent else {
      logger.debug("instance running as agent")

      switch initialStatus {
        case .enabled:
          logger.debug("agent status enabled")
          NSRunningApplication.current.terminateDuplicateInstances(self)
          return .success(())

        default:
          logger.error("agent status not enabled")
          do { try handleAgentRegister() } catch { break }
          if isAgentEnabled {
            logger.debug("agent re-registered and enabled")
            return .success(())
          }
      }

      return .failure(.running(agent.status))
    }

    logger.debug("instance not running as agent")

    switch initialStatus {
      case .requiresApproval:
        logger.debug("agent status disabled")
        await displayAgentDisabledError()
        break

      case .enabled:
        logger.debug("agent status enabled")
        fallthrough

      case .notRegistered:
        logger.debug("agent status not registered")
        fallthrough

      case .notFound:
        logger.debug("agent status not found")
        fallthrough

      default:
        try? await handleAgentUnregister()

        do {
          try handleAgentRegister()
        } catch let registrationError {
          if !isAgentEnabled {
            await displayAgentRegistrationError(cause: registrationError)
          }
        }

        if isAgentEnabled {
          await displayAgentEnabledRegisteredInfo()
        }
    }

    return .failure(.notRunning(agent.status))
  }

  private func handleAgentRegister() throws {
    do {
      logger.debug("attempting agent register")
      try agent.register()
    } catch let error {
      logger.error("failed registering agent: \(error.localizedDescription, privacy: .public)")
      throw error
    }
  }

  private func handleAgentUnregister() async throws {
    do {
      logger.debug("attempting agent unregister")
      try await agent.unregister()
    } catch let error {
      logger.warning("failed unregistering agent: \(error.localizedDescription, privacy: .public)")
      throw error
    }
  }

  public func displayAgentRunningEnabledInfo() async {
    await displayAgentInfo(
      info: "App running in the background",
      message: "This application is currently already running as a background process, waiting for AirPlay requests to accept.\nTo manage it go to System Settings > General > Login Items."
    )
  }

  private func displayAgentEnabledRegisteredInfo() async {
    await displayAgentInfo(
      info: "Background process registered",
      message: "This application will now run in the background, waiting for AirPlay requests to accept.\nTo manage it, and turn off the auto-launch at login, go to System Settings > General > Login Items."
    )
  }

  private func displayAgentInfo(info: String, message: String) async {
    if
      await AARAlert.display(
        style: .informational,
        title: info,
        message: message,
        okButtonTitle: "OK",
        cancelButtonTitle: "Open Login Items Settings"
      ) == .cancel
    {
      SMAppService.openSystemSettingsLoginItems()
    }
  }

  private func displayAgentDisabledError() async {
    await displayAgentError(
      error: "Background process disabled",
      message: "This app needs permission to run in the background in order to accept incoming AirPlay requests.\nPlease go to System Settings > General > Login Items to allow it."
    )
  }

  private func displayAgentRegistrationError(cause: any Error) async {
    await displayAgentError(
      error: "Background process registration failed",
      message: "This app was unable to register the service to run as a background process.\nPlease check in System Settings > General > Login Items if it's already been registered, or try again after a system reboot.",
      cause: cause
    )
  }

  private func displayAgentError(
    error: String,
    message: String,
    cause: (any Error)? = nil
  ) async {
    var message = message
    if let cause {
      message += "\n[ Error: \"\(cause.localizedDescription)\" ]"
    }

    if await AARAlert.display(
      style: .critical,
      title: error,
      message: message,
      okButtonTitle: "Open Login Items Settings",
      cancelButtonTitle: "Cancel"
    ) == .OK {
      SMAppService.openSystemSettingsLoginItems()
    }
  }
}
