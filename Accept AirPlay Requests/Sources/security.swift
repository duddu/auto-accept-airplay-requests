import AppKit.NSApplication

public struct AARSecurityManager {
  static private let privacyAccessibilityPanelUrl = URL(
    string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
  )

  @MainActor static private var isFirstAttempt: Bool = true

  static private var isAccessibilityAccessGranted: Bool { AXIsProcessTrusted() }

  @MainActor static private func displayAccessibilityWarning() -> AARAlertResult {
    AARAlert(
      style: .warning,
      title: "AARSecurityManager",
      message: isFirstAttempt
        ? "Please enable accessibility access in Privacy & Security Preferences."
        : "Accessibility access is still disabled.",
      okBtnTitle: isFirstAttempt ? "Open System Preferences" : "Check again",
      dismissBtnTitle: "Quit"
    )
    .run()
  }

  @MainActor static public func ensureAccessibilityAccess() {
    if isAccessibilityAccessGranted { return }

    if displayAccessibilityWarning() != .ok {
      return NSApp.terminate(self)
    }

    if isFirstAttempt {
      NSWorkspace.shared.open(privacyAccessibilityPanelUrl!)
      isFirstAttempt = false
    }
  }
}
