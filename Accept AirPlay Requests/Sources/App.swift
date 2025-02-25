import AppKit.NSApplication
import AppKit.NSRunningApplication
import AppKit.NSWorkspace

@main
private final class AARApp: NSObject, NSApplicationDelegate, AARLoggable {
  static private func main() {
    let appDelegate: Self = .init()
    NSApplication.shared.delegate = appDelegate
    NSApplication.shared.setActivationPolicy(.accessory)
    NSApplication.shared.run()
  }

  func applicationWillFinishLaunching(_: Notification) {
    let currentInstance = NSRunningApplication.current
    let multipleInstances = NSWorkspace.shared.runningApplications.filter { instance in
      instance.bundleIdentifier == currentInstance.bundleIdentifier &&
      instance.processIdentifier != currentInstance.processIdentifier
    }

    for instance in multipleInstances {
      let pid = instance.processIdentifier
      logger.warning("terminating multiple instance with pid=\(pid, privacy: .public)")
      guard instance.terminate() else {
        logger.warning(
          "failed to terminate instance with pid=\(pid, privacy: .public), forcing termination"
        )
        guard instance.forceTerminate() else {
          logger.error("failed to force terminate instance with pid=\(pid, privacy: .public)")
          continue
        }
        continue
      }
    }
  }

  func applicationDidFinishLaunching(_: Notification) {
    logger.debug("did finish launching")

    Task { @AARMain in
      await AARMain.shared.start()
    }
  }

  func applicationWillTerminate(_: Notification) {
    logger.debug("will terminate")
  }

  func applicationDidUpdate(_: Notification) {
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
      modal.makeKeyAndOrderFront(nil)
      modal.collectionBehavior = .moveToActiveSpace
    }
  }

  func applicationDidResignActive(_ n: Notification) {
    logger.debug("did resign active")

    guard let modal = NSApplication.shared.modalWindow else { return }

    modal.center()
  }

  func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows: Bool) -> Bool {
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
