import AppKit.NSApplication
import AppKit.NSRunningApplication
import AppKit.NSWorkspace
import ApplicationServices.HIServices

public struct AARAirPlayManager: AARLoggable {
  static private let notificationCenterBundleId = "com.apple.notificationcenterui"

  private var notificationCenterWindow: AXUIElement? = nil

  private typealias UIElementWithAction = (AXUIElement, CFString)

  public init() {
    self.notificationCenterWindow = getNotificationCenterFirstWindow()
  }

  public func handleRequestNotification() {
    guard
      let notificationCenterWindow,
      let (notification, actionName) = getNotificationAcceptAction(in: notificationCenterWindow),
      AXUIElementPerformAction(notification, actionName) == .success
    else { return }

    Self.logger.info("action performed successfully")
  }

  private func getNotificationAcceptAction(in element: AXUIElement) -> UIElementWithAction? {
    for child in getUIElementChildren(of: element) {
      var actionNamesArray: CFArray?
      AXUIElementCopyActionNames(child, &actionNamesArray)

      guard let actionNames = actionNamesArray as? [CFString] else { continue }

      for name in actionNames {
        guard validateNotificationAction(of: child, name: name) else { continue }
        Self.logger.info("action validation passed")

        guard validateNotificationAttributes(of: child) else { continue }
        Self.logger.info("attributes validation passed")
        return (child, name)
      }

      // @TODO avoid recurse here for known scenarios
      return getNotificationAcceptAction(in: child)
    }

    return nil
  }

  private func validateNotificationAction(of element: AXUIElement, name: CFString) -> Bool {
    guard String(describing: name).lowercased().starts(with: "name:accept") else { return false }
    Self.logger.info("action name matched: \(String(describing: name), privacy: .public)")

    var description: CFString?
    AXUIElementCopyActionDescription(element, name, &description)
    guard let description = description as? String, description.lowercased() == "accept"
    else {
      Self.logger.debug(
        "action description not matched: \(String(describing: description), privacy: .public)"
      )
      return false
    }
    Self.logger.info("action description match")
    return true
  }

  private func validateNotificationAttributes(of element: AXUIElement) -> Bool {
    var description: CFTypeRef?
    AXUIElementCopyAttributeValue(element, kAXDescription as CFString, &description)

    guard let description = description as? String else { return false }
    Self.logger.debug("attribute description: \(description, privacy: .public)")

    // @TODO extract other regexs and strings in static lets
    if (try? (/^airplay.+would like to airplay to this mac\.$/.ignoresCase()).wholeMatch(
      in: description
    )) != nil {
      return true
    }

    guard
      description.lowercased() == "airplay",
      getUIElementChildren(of: element).contains(where: { child in
        var identifierRef: CFTypeRef?
        AXUIElementCopyAttributeValue(child, kAXIdentifierAttribute as CFString, &identifierRef)
        guard
          let identifier = identifierRef as? String,
          identifier.lowercased() == "body"
        else {
          Self.logger.debug(
            "attribute identifier not matched: \(String(describing: identifierRef), privacy: .public)"
          )
          return false
        }

        var valueRef: CFTypeRef?
        AXUIElementCopyAttributeValue(child, kAXValueAttribute as CFString, &valueRef)
        guard
          let value = valueRef as? String,
          let _ = try? (/^.+would like to airplay to this mac\.$/.ignoresCase()).wholeMatch(
            in: value
          )
        else {
          Self.logger.debug(
            "attribute value not matched: \(String(describing: valueRef), privacy: .public)"
          )
          return false
        }

        return true
      })
    else { return false }

    return true
  }

  private func getNotificationCenterFirstWindow() -> AXUIElement? {
    guard
      let notificationCenterUIElement = getApplicationUIElement(
        for: AARAirPlayManager.notificationCenterBundleId)
    else { return nil }

    var windowsRef: CFTypeRef?
    AXUIElementCopyAttributeValue(
      notificationCenterUIElement, kAXWindowsAttribute as CFString, &windowsRef)

    guard
      let windows = windowsRef as? [AXUIElement], !windows.isEmpty
    else {
      Self.logger.debug("notification center has no active windows")
      return nil
    }

    return windows.first
  }

  private func getApplicationUIElement(for bundleId: String) -> AXUIElement? {
    guard
      let runningApp: NSRunningApplication = NSWorkspace.shared.runningApplications.first(
        where: { $0.bundleIdentifier == bundleId }
      )
    else {
      Self.logger.error("app \(bundleId) not running")
      return nil
    }
    return AXUIElementCreateApplication(runningApp.processIdentifier)
  }

  private func getUIElementChildren(of element: AXUIElement) -> [AXUIElement] {
    var children: CFTypeRef?
    AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &children)

    return children as? [AXUIElement] ?? []
  }
}
