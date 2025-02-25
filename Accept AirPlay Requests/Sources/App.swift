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

    Task { @AARMain in
      await AARMain.shared.start()
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
        await AARServiceManager.displayAgentInfo()
      }
    }

    return false
  }
}

@globalActor
private final actor AARMain: GlobalActor, AARLoggable {
  static public let shared = AARMain()

  private init() {}

  private var task: Task<Void, Never>?

  public func start() {
    logger.info("starting")

    task = Task(priority: .background) { @AARMain in
      await operation()
    }
  }

  private func stop() async {
    logger.info("stopping")

    await withTaskCancellationHandler {
      task?.cancel()
    } onCancel: {
      logger.debug("task cancelled")

      Task { @AARMain in
        await NSApplication.shared.terminate(self)
      }
    }
  }

  private func operation() async {
    guard await AARServiceManager().ensureAgentStatus() == .success else {
      return await stop()
    }

    var isRetry = false
    while !Task.isCancelled {
      switch await AARSecurityManager().ensureAccessibilityPermission(isRetry) {
        case .success:
          AARNotificationsScanner().scanForAirPlayAlerts()
          await sleep(5)
          break
        case .failure(retry: true):
          isRetry = true
          await sleep(10)
          break
        case .failure(retry: false):
          return await stop()
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
