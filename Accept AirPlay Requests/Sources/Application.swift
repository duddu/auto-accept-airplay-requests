import AppKit.NSApplication
import AppKit.NSRunningApplication
import Foundation.NSProcessInfo

@main
public struct AARApplication: Sendable, AARLoggable {
  static private let delegate = AARApplicationDelegate()

  static private func main() {
    NSApplication.shared.delegate = delegate
    NSApp.setActivationPolicy(.accessory)
    NSApp.run()
  }

  private init() {}
}

public final class AARApplicationDelegate: NSObject, NSApplicationDelegate, Sendable, AARLoggable {
  private func startBackgroundWork() {
    Task(priority: .background) {
      await AARBackgroundWorker.shared.start(
        onEndCallback: {
          Self.logger.debug("background worker onEnd callback")
          await NSApp.terminate(nil)
        }
      )
    }
  }

  public func applicationDidFinishLaunching(_: Notification) {
    logger.debug("finished launching")
    startBackgroundWork()
  }

  public func applicationDidUpdate(_: Notification) {
    guard let modal = NSApp.modalWindow else {
      if NSApp.activationPolicy() != .accessory {
        logger.debug("deactivating while modal closed")
        NSApp.deactivate()
        NSApp.setActivationPolicy(.accessory)
      }
      return
    }

    if NSApp.activationPolicy() != .regular {
      logger.debug("activating while modal opened")
      NSApp.setActivationPolicy(.regular)
      NSApp.activate(ignoringOtherApps: true)
      modal.makeKeyAndOrderFront(nil)
      modal.collectionBehavior = .moveToActiveSpace
    }
  }

  public func applicationDidResignActive(_: Notification) {
    guard let modal = NSApp.modalWindow else { return }
    logger.debug("centering modal while without focus")
    modal.center()
  }

  public func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows: Bool) -> Bool {
    if !hasVisibleWindows && NSApp.modalWindow == nil {
      let service = AARServiceManager()
      logger.debug("handling reopen while no windows visible")

      if service.isAgentRunningEnabled {
        logger.debug("displaying info on running enabled agent")
        Task { await service.displayAgentRunningEnabledInfo() }
      } else {
        logger.debug("restarting worker on non-agent instance")
        startBackgroundWork()
      }
    }
    return false
  }

  public func applicationWillTerminate(_: Notification) {
    logger.debug("terminating")
  }
}

extension NSRunningApplication {
  public var duplicateInstances: [NSRunningApplication] {
    guard let currentBundleId = bundleIdentifier else { return [] }

    return NSRunningApplication
      .runningApplications(withBundleIdentifier: currentBundleId)
      .filter { instance in
        !instance.isTerminated &&
        !instance.isEqual(to: self)
      }
  }

  public func terminateDuplicateInstances(_ sender: any AARLoggable) -> Void {
    let duplicates = duplicateInstances
    guard !duplicates.isEmpty else { return }
    sender.logger.debug("found \(duplicates.count) duplicate running instances")

    for instance in duplicates {
      let pid = instance.processIdentifier

      if instance.activationPolicy == .regular {
        sender.logger.debug("terminating instance with pid=\(pid)")
        if instance.terminate() { continue }
        sender.logger.warning("failed to terminate instance with pid=\(pid), will force")
      }

      sender.logger.debug("force-terminating instance with pid=\(pid)")
      if !instance.forceTerminate() {
        sender.logger.error("failed to force-terminate instance with pid=\(pid)")
      }
    }
  }
}
