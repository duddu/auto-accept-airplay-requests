import AppKit.NSApplication
import AppKit.NSRunningApplication
import AppKit.NSWorkspace
import ApplicationServices.HIServices

public struct AARAirPlayRequestsHandler: AARLoggable {
  static private let notificationCenterBundleId = "com.apple.notificationcenterui"

  public func scanNotificationCenter() {
    if let notificationCenterWindow = getNotificationCenterFirstWindow() {
      findAndActionAirPlayNotification(in: notificationCenterWindow)
    }
  }

  private func findAndActionAirPlayNotification(in element: AXUIElement) {
    for child in getUIElementChildren(of: element) {
      var actionNamesArray: CFArray?
      AXUIElementCopyActionNames(child, &actionNamesArray)

      guard let actionNames = actionNamesArray as? [CFString] else { continue }

      for name in actionNames {
        guard validateNotificationAction(of: child, name: name) else { continue }
        logger.info("action validation passed")

        guard validateNotificationAttributes(of: child) else { continue }
        logger.info("attributes validation passed")

        guard AXUIElementPerformAction(element, name) == .success else { continue }
        logger.info("action performed successfully")
        return
      }

      // @TODO avoid recurse here for known scenarios
      return findAndActionAirPlayNotification(in: child)
    }
  }

  private func validateNotificationAction(of element: AXUIElement, name: CFString) -> Bool {
    guard String(describing: name).lowercased().starts(with: "name:accept") else { return false }
    logger.info("action name matched: \(String(describing: name), privacy: .public)")

    var description: CFString?
    AXUIElementCopyActionDescription(element, name, &description)
    guard let description = description as? String, description.lowercased() == "accept"
    else {
      logger.debug(
        "action description not matched: \(String(describing: description), privacy: .public)"
      )
      return false
    }
    logger.info("action description match")
    return true
  }

  private func validateNotificationAttributes(of element: AXUIElement) -> Bool {
    var description: CFTypeRef?
    AXUIElementCopyAttributeValue(element, kAXDescription as CFString, &description)

    guard let description = description as? String else { return false }
    logger.debug("attribute description: \(description, privacy: .public)")

    // @TODO extract other regexs and constants in string catalog
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
          logger.debug(
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
          logger.debug(
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
        for: AARAirPlayRequestsHandler.notificationCenterBundleId)
    else { return nil }

    var windowsRef: CFTypeRef?
    AXUIElementCopyAttributeValue(
      notificationCenterUIElement, kAXWindowsAttribute as CFString, &windowsRef)

    guard
      let windows = windowsRef as? [AXUIElement], !windows.isEmpty
    else {
      logger.debug("notification center has no active windows")
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
      logger.error("app \(bundleId) not running")
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
