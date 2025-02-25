import AppKit.NSApplication
import AppKit.NSRunningApplication

@main
private final class AARApp: NSObject, NSApplicationDelegate, Sendable, AARLoggable {
  static private let delegate = AARApp()

  static private func main() {
    NSApplication.shared.setActivationPolicy(.accessory)
    NSApplication.shared.delegate = delegate
    NSApplication.shared.run()
  }

  private func terminateOtherInstances() {
    guard let bundleId = NSRunningApplication.current.bundleIdentifier else { return }
    let currentProcessId = NSRunningApplication.current.processIdentifier

    NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).forEach { instance in
      let pid = instance.processIdentifier
      guard pid != currentProcessId else { return }

      logger.warning("terminating multiple instance with pid=\(pid, privacy: .public)")

      guard instance.forceTerminate() else {
        logger.error("failed to terminate instance with pid=\(pid, privacy: .public)")
        return
      }
    }
  }

  public func applicationWillFinishLaunching(_: Notification) {
    terminateOtherInstances()
  }

  public func applicationDidFinishLaunching(_: Notification) {
    logger.debug("launched")

    Task {
      await AARWorker().start()
    }
  }

  public func applicationWillTerminate(_: Notification) {
    logger.debug("terminating")

    terminateOtherInstances()
  }

  public func applicationDidUpdate(_: Notification) {
    guard let modal = NSApplication.shared.modalWindow else {
      if NSApplication.shared.activationPolicy() == .regular {
        logger.debug("did update - deactivate")

        NSApplication.shared.deactivate()
        NSApplication.shared.setActivationPolicy(.accessory)
      }

      return
    }

    if NSApplication.shared.activationPolicy() == .accessory {
      logger.debug("did update - activate")

      NSApplication.shared.setActivationPolicy(.regular)
      NSApplication.shared.activate(ignoringOtherApps: true)
      modal.makeKeyAndOrderFront(self)
      modal.collectionBehavior = .moveToActiveSpace
    }
  }

  public func applicationDidResignActive(_: Notification) {
    guard let modal = NSApplication.shared.modalWindow else { return }

    logger.debug("resign active - center modal")

    modal.center()
  }

  public func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows: Bool) -> Bool {
    if !hasVisibleWindows {
      logger.debug("handle reopen - display agent info")

      Task {
        await AARServiceManager.alertAgentInfo()
      }
    }

    return false
  }
}

private final actor AARWorker: AARLoggable {
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
