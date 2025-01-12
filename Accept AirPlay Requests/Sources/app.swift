import AppKit.NSApplication

@globalActor
public final actor AARMain: GlobalActor, AARLoggable {
  static public let shared = AARMain()

  private init() {}

  private var task: Task<Void, Never>?

  public func start() {
    Self.logger.info("starting")

    task = Task(priority: .background) { @AARMain in
      await operation()
    }
  }

  private func stop() async {
    Self.logger.info("stopping")

    await withTaskCancellationHandler {
      task?.cancel()
    } onCancel: {
      Self.logger.info("task cancelled")
      Task {
        await NSApp.terminate(self)
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
          AARAirPlayRequestsHandler().scanNotificationCenter()
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

@main
private final class AARApp: NSObject, NSApplicationDelegate, AARLoggable {
  private static func main() {
    let appDelegate: Self = .init()
    NSApplication.shared.delegate = appDelegate
    NSApplication.shared.setActivationPolicy(.accessory)
    NSApplication.shared.run()
  }

  func applicationDidFinishLaunching(_: Notification) {
    Self.logger.debug("finish launching")
    Task { @AARMain in
      await AARMain.shared.start()
    }
  }

  func applicationWillTerminate(_: Notification) {
    Self.logger.debug("will terminate")
  }

  func applicationDidResignActive(_: Notification) {
    if NSApplication.shared.windows.contains(where: { !$0.isOnActiveSpace }) {
      Self.logger.debug("reactivate after resign")
      NSApplication.shared.activate(ignoringOtherApps: true)
    }
  }

  func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows: Bool) -> Bool { false }

  func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool { false }
}
