import AppKit
import Foundation

@main public struct AARApp {
  @MainActor static private let delegate = AARAppDelegate()

  static private func main() {
    NSApplication.shared.setActivationPolicy(.accessory)
    NSApplication.shared.delegate = delegate
    NSApplication.shared.run()
  }
}

private final class AARAppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_: Notification) {
    Task {
      AARAgentManager.initialize()
      AARSecurityManager.initialize()
      AARActionManager.initialize()
    }
  }

  func applicationDidResignActive(_: Notification) {
    if NSApplication.shared.windows.contains(where: { !$0.isOnActiveSpace }) {
      NSApplication.shared.activate(ignoringOtherApps: true)
    }
  }

  func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows: Bool) -> Bool { false }

  func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool { false }
}
