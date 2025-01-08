import AppKit.NSApplication
//import Foundation

// @TODO update all bundle identifier reference to camelcase dev.duddu.AcceptAirPlayRequests (+ .LaunchAgent)

//@main
@globalActor
public final actor AARMain: GlobalActor, AARLoggable {
  static public let shared = AARMain()

  private init() {}

//  typealias ActorType = AARMain

//  @MainActor
//  private let serviceManager = AARServiceManager()
////  @MainActor
//  private let securityManager = AARSecurityManager()

//  private let serviceManager: AARServiceManager
//  private let securityManager: AARSecurityManager

//  @MainActor
  private var task: Task<Void, Never>?

//  static private let appDelegate = AARAppDelegate()
//  static private let serviceManager = AARServiceManager()
//  static private let securityManager = AARSecurityManager()
////  static private let logger = AARLogger.withLabel("main")
//  static private var task: Task<Void, Never>?

//  @MainActor
//  init() {
//    self.task = Task(
//      priority: .background,
//      operation: operation
//    )
//    serviceManager = AARServiceManager()
//    securityManager = AARSecurityManager()
//  }

  // @TODO ?move back main into app delegate class?
//  static private func main() {
//    logger.debug("main()")
//
//    // @TODO let appDelegate: AARAppDelegate = .init()
//    NSApplication.shared.delegate = appDelegate
//    NSApplication.shared.setActivationPolicy(.accessory)
//    NSApplication.shared.run()
//  }

//  @MainActor
//  static public func initialize() {
//    Self().start()
//  }

//  @MainActor
  public func start() {
//    Self.logger.trace("start")
//    Self.logger.debug("start")
//    Self.logger.info("start")
//    Self.logger.notice("start")
//    Self.logger.warning("start")
//    Self.logger.error("start")
//    Self.logger.critical("start")
//    Self.logger.fault("start")

//    Self.logger
//      .debug(
//        "start() - \(self.task != nil ? "fresh start" : "restart - isCancelled: \(self.task!.isCancelled.description)")"
//      )

    Self.logger.info("starting")

    task = Task(priority: .background) { @AARMain in
      await operation()
    }
  }

//  @MainActor
  public func stop() async {
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

//  @MainActor
  private func operation() async {
//    let serviceManager = AARServiceManager()
//    let securityManager = AARSecurityManager()
//    let airPlayManager = AARAirPlayManager()

    guard await AARServiceManager().ensureAgentStatus() == .success else {
      return await stop()
    }

    var isRetry = false
    while !Task.isCancelled {
      switch await AARSecurityManager().ensureAccessibilityPermission(isRetry) {
        case .success:
          AARAirPlayManager().handleRequestNotification()
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

//@main
//public struct AARApp {
//  static private let logger = AARLogger.withLabel("app")
//
//  static private func main() {
//    logger.debug("main()")
//
////    let appDelegate: Self.Delegate = .init(main: AARMain())
////    NSApplication.shared.delegate = appDelegate
////    NSApplication.shared.setActivationPolicy(.accessory)
////    NSApplication.shared.run()
//  }
//
////  static public func quit() {
////    Task {
////      await NSApplication.shared.terminate(nil)
////    }
////  }
//
//  // @TODO maybe try to extract in Actor
////  private var onLaunchTask: Task<Void, Never>?
//
////  private mutating func lauoinch() {
////    onLaunchTask?.cancel()
//////    onLaunchTask = Task.detached(priority: .background) {
////    onLaunchTask = Task {
//////      await MainActor.run {
////        //        guard self.agentManager.ensureServiceStatus() == .success else { return }
////        //              guard await AARAgentManager.ensureServiceStatus() == .success else { return }
////        repeat {
////          if await AARSecurityManager.ensureAccessibilityAccess() == .success {
////            AARAirPlayManager.inspectAirPlayRequestNotifications()
////          }
////          try? await Task.sleep(
////            for: .seconds(5),
////            tolerance: .seconds(1)
////          )
////        } while !Task.isCancelled
//////      }
////    }
////  }
//
////  @MainActor static private let appDelegate = AARAppDelegate(
////    onApplicationDidFinishLaunching: onLaunchCallback,
////    onApplicationWillTerminate: onTerminateCallback
////  )
//
////  @MainActor static private var onLaunchTask: Task<Void, Never>?
//
//
//  // @TODO re-extract the @main struct and leave appdelegate with only relevant methods
//  //@main
//  private final class Delegate: NSObject, NSApplicationDelegate {
//    private let main: AARMain
//
//    init(main: AARMain) {
//      self.main = main
//    }
//
//    func applicationDidFinishLaunching(_: Notification) {
//      AARApp.logger.debug("applicationDidFinishLaunching()")
//
////      onLaunchTask?.cancel()
////      onLaunchTask = Task.detached(priority: .background) {
//////        guard self.agentManager.ensureServiceStatus() == .success else { return }
//////              guard await AARAgentManager.ensureServiceStatus() == .success else { return }
////        repeat {
////          if await AARSecurityManager.ensureAccessibilityAccess() == .success {
////            AARAirPlayManager.inspectAirPlayRequestNotifications()
////          }
////          try? await Task.sleep(
////            for: .seconds(5),
////            tolerance: .seconds(1)
////          )
////        } while !Task.isCancelled
////      }
//    }
//
//    func applicationWillTerminate(_: Notification) {
//      AARApp.logger.debug("applicationWillTerminate()")
//
////      onLaunchTask?.cancel()
//    }
//
//    func applicationDidResignActive(_: Notification) {
//      if NSApplication.shared.windows.contains(where: { !$0.isOnActiveSpace }) {
//        NSApplication.shared.activate(ignoringOtherApps: true)
//      }
//    }
//
//    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows: Bool) -> Bool { false }
//
//    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool { false }
//  }
//}


@main
private final class AARApp: NSObject, NSApplicationDelegate, AARLoggable {
//  static private let logger = AARLogger.withLabel("app")

//  let main: AARMain
//
//  init(main: AARMain) {
//    self.main = main
//  }

  private static func main() {
//    logger.debug("main()")
//    let main: AARMain = AARMain()
    let appDelegate = AARApp()
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
      Self.logger.debug("reactivate after window resign")
      NSApplication.shared.activate(ignoringOtherApps: true)
    }
  }

  func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows: Bool) -> Bool { false }

  func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool { false }
}
