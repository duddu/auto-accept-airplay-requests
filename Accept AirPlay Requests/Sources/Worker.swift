import AppKit.NSApplication

public final actor AARWorker: AARLoggable {
  private var task: Task<Void, Never>?

  public func start() {
    logger.info("starting")

    task = Task(
      priority: .background,
      operation: operation
    )
  }

  private func stop() {
    logger.info("stopping")

    task?.cancel()

    Task {
      await NSApplication.shared.terminate(self)
    }
  }

  private func operation() async {
    switch await AARServiceManager().ensureAgentStatus() {
      case .success:
        break

      case .failure(.invalidStatus):
        return stop()
    }

    while task?.isCancelled == false {
      switch await AARSecurityManager().ensureAccessibilityPermission() {
        case .success:
          AARNotificationsScanner().scanForAirPlayAlerts()
          await sleep(5)
          break

        case .failure(.permissionRequested):
          await sleep(10)
          break

        case .failure(.permissionRefused):
          return stop()
      }
    }
  }

  private func sleep(_ seconds: Double) async {
    try? await Task.sleep(
      for: .seconds(seconds),
      tolerance: .seconds(seconds / 5)
    )
  }
}
