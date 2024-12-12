import AppKit
import Foundation

@main public struct AARApp {
  static private let logger = AARLogger.withCategory("app")

  @MainActor static private let appDelegate = AARAppDelegate(
    onApplicationDidFinishLaunching: onLaunchCallback,
    onApplicationWillTerminate: onTerminateCallback
  )

  @MainActor static private var onLaunchTask: Task<Void, Never>?

  static private func main() {
    logger.debug("main()")
    NSApplication.shared.setActivationPolicy(.accessory)
    NSApplication.shared.delegate = appDelegate
    NSApplication.shared.run()
  }

  @MainActor static private func onLaunchCallback() {
    Self.onLaunchTask = Task {
      AARAgentManager.ensureServiceStatus()
      repeat {
        AARSecurityManager.ensureAccessibilityAccess()
        AARActionManager.inspectAirPlayRequestNotifications()
        await AARTimer.sleep(5)
      } while !Task.isCancelled
    }
  }

  @MainActor static private func onTerminateCallback() {
    Self.onLaunchTask?.cancel()
  }
}

private final class AARAppDelegate: NSObject, NSApplicationDelegate {
  private let onApplicationDidFinishLaunching: () -> Void
  private let onApplicationWillTerminate: () -> Void

  static private let logger = AARLogger.withCategory("app-delegate")

  init(
    onApplicationDidFinishLaunching: @escaping () -> Void,
    onApplicationWillTerminate: @escaping () -> Void
  ) {
    self.onApplicationDidFinishLaunching = onApplicationDidFinishLaunching
    self.onApplicationWillTerminate = onApplicationWillTerminate
  }

  func applicationDidFinishLaunching(_: Notification) {
    Self.logger.debug("applicationDidFinishLaunching()")
    onApplicationDidFinishLaunching()
  }

  func applicationWillTerminate(_: Notification) {
    Self.logger.debug("applicationWillTerminate()")
    onApplicationWillTerminate()
  }

  func applicationDidResignActive(_: Notification) {
    if NSApplication.shared.windows.contains(where: { !$0.isOnActiveSpace }) {
      NSApplication.shared.activate(ignoringOtherApps: true)
    }
  }

  func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows: Bool) -> Bool { false }

  func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool { false }
}
