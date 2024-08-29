import AppKit.NSApplication

@MainActor public struct AARSecurityManager {
  static private var accessibilityAccessRetryTask: Task<Void, Never>?

  static private let privacyAccessibilityPanelUrl = URL(
    string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
  )

  static public var hasAccessibilityAccess: Bool { AXIsProcessTrusted() }

  static public var isBusy: Bool = false

  static public func initialize() {
    ensureAccessibilityAccess()
  }

  static private func displayWarningRetryOrExit(isRetry: Bool = false) -> AARAlertResult {
    let result = AARAlert(
      style: .warning,
      title: "#ensureAccessibilityAccess()#",
      message: !isRetry
        ? "Please enable accessibility access in Privacy & Security Preferences."
        : "Accessibility access is still disabled.",
      okBtnTitle: !isRetry ? "Open System Preferences" : "Check again",
      dismissBtnTitle: "Quit"
    ).run()
    if result != .ok { NSApp.terminate(self) }
    return result
  }

  static private func startAccessibilityAccessRetryTask() {
    accessibilityAccessRetryTask = Task {
      repeat {
        if hasAccessibilityAccess || displayWarningRetryOrExit(isRetry: true) != .ok {
          accessibilityAccessRetryTask?.cancel()
          isBusy = false
          return
        }
        try? await Task.sleep(for: .seconds(2))
      } while !Task.isCancelled
    }
  }

  static public func ensureAccessibilityAccess() {
    isBusy = true
    Task {
      if hasAccessibilityAccess {
        isBusy = false
        return
      }
      if displayWarningRetryOrExit() == .ok {
        NSWorkspace.shared.open(privacyAccessibilityPanelUrl!)
        try? await Task.sleep(for: .seconds(5))
        return startAccessibilityAccessRetryTask()
      }
    }
  }
}
