public final actor AARBackgroundWorker: GlobalActor, AARLoggable {
  private typealias WorkPauseTimeInterval = Double

  private var work: Task<Void, Never>?

  public static let shared = AARBackgroundWorker()

  private init() {}

  deinit {
    Self.logger.debug("actor deinitialized")
  }

  public func start(onEndCallback: @escaping @Sendable () async -> Void) {
    if let work {
      logger.debug("cancelling work before restart")
      work.cancel()
    }

    logger.debug("starting work task")

    work = Task(priority: .background) {
      do {
        try await runOnIntervalUntilCancelled()
      } catch is CancellationError {
        logger.debug("work task cancelled")
      } catch {
        logger.debug("work task ended with \(type(of: error), privacy: .public)")
        Task.detached(operation: onEndCallback)
      }
    }
  }

  private func runOnIntervalUntilCancelled() async throws {
    while !Task.isCancelled {
      let interval = try await handleAirPlayRequests()

      try await pause(for: interval)
    }
  }

  private func handleAirPlayRequests() async throws -> WorkPauseTimeInterval {
    switch await AARServiceManager().ensureAgentStatus() {
      case .success:
        break

      case .failure(let serviceError):
        throw serviceError
    }

    try Task.checkCancellation()

    switch await AARSecurityManager().ensureAccessibilityPermission() {
      case .success:
        AARNotificationsScanner().scanForAirPlayAlerts()
        return 5

      case .failure(.permissionRequested):
        return 10

      case .failure(let securityError):
        throw securityError
    }
  }

  private func pause(for seconds: WorkPauseTimeInterval) async throws {
    try await Task.sleep(
      for: .seconds(seconds),
      tolerance: .seconds(seconds / 5)
    )
  }
}
