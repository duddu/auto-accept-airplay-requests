import AppKit.NSApplication
import Foundation.NSBundle


@globalActor
public final actor AARMain: GlobalActor, AARLoggable {
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

@main
private final class AARApp: NSObject, NSApplicationDelegate, AARLoggable {
  static private func main() {
    let appDelegate: Self = .init()
    NSApplication.shared.delegate = appDelegate
    NSApplication.shared.setActivationPolicy(.accessory)
    NSApplication.shared.run()
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
    if NSApplication.shared.windows.count > 0 {
      NSApplication.shared.setActivationPolicy(.regular)
      NSApplication.shared.activate(ignoringOtherApps: true)
      NSApplication.shared.modalWindow?.makeKeyAndOrderFront(nil)
      NSApplication.shared.modalWindow?.collectionBehavior = .moveToActiveSpace
    } else {
      NSApplication.shared.deactivate()
      NSApplication.shared.setActivationPolicy(.accessory)
    }
  }

  func applicationDidResignActive(_: Notification) {
    logger.debug("reactivate after resign")
    if NSApplication.shared.windows.count > 0 {
      NSApplication.shared.activate(ignoringOtherApps: true)
    }
  }

  func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows: Bool) -> Bool {
    logger.debug("handle reopen")
    // @TODO present user with info/options while process is already running
    // (same to show when app is launched first time without launch agent registered)
    if !hasVisibleWindows {
      AARAlert.info(title: "", message: "This app is already running in the background")
    }

    return false
  }
}

public struct AARBundle {
  static public let identifier: String = Bundle.main.bundleIdentifier!
  static public let name: String = getInfoDictionaryString(for: kCFBundleNameKey as String)
  static public let version: String = getInfoDictionaryString(for: "CFBundleShortVersionString")
  static public let buildNumber: String = getInfoDictionaryString(for: kCFBundleVersionKey as String)

  static private func getInfoDictionaryString(for key: String) -> String {
    Bundle.main.object(forInfoDictionaryKey: key) as! String
  }
}
