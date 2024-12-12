import AppKit.NSApplication

public struct AARActionManager {
  static private let logger = AARLogger.withCategory("action")

  static private func getApplicationElement(for bundleId: String) -> AXUIElement? {
    guard
      let runningApp: NSRunningApplication = NSWorkspace.shared.runningApplications.first(where: {
        $0.bundleIdentifier == bundleId
      })
    else {
      logger.debug("No app running with bundle id \(bundleId).")
      return nil
    }
    return AXUIElementCreateApplication(runningApp.processIdentifier)
  }

  static private func getApplicationFirstWindow(of appElement: AXUIElement) -> AXUIElement? {
    var windowsArray: CFTypeRef?
    AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsArray)

    guard let windows = windowsArray as? [AXUIElement], !windows.isEmpty
    else {
      logger.debug("No windows opened for this application.")
      return nil
    }
    return windows.first
  }

  static private func inspectElementChildren(of element: AXUIElement) -> [AXUIElement]? {
    var childrenArray: CFTypeRef?
    AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenArray)

    guard let children = childrenArray as? [AXUIElement] else { return nil }

    for child in children {
      var actionNamesArray: CFArray?
      AXUIElementCopyActionNames(child, &actionNamesArray)

      guard
        let actionNames = actionNamesArray as? [String],

        let acceptActionNames = actionNames.filter({ name in
          guard name.starts(with: "Name:Accept") else { return false }

          var description: CFString?
          AXUIElementCopyActionDescription(child, name as CFString, &description)
          guard description as? String == "Accept" else { return false }

          return inspectElementAttrs(of: child)
        }) as [CFString]?,

        !acceptActionNames.isEmpty
      else {
        return inspectElementChildren(of: child)
      }

      for name in acceptActionNames {
        AXUIElementPerformAction(child, name)
      }
    }

    return nil
  }

  static private func inspectElementAttrs(of element: AXUIElement) -> Bool {
    // @TODO copy and inspect attrs relevant for each macOS version
    let attrsNames = [
      kAXDescription,
      kAXIdentifierAttribute,
      kAXRoleAttribute,
      kAXSubroleAttribute,
      kAXValueAttribute,
    ] as CFArray
    var attrsValues: CFArray?
    AXUIElementCopyMultipleAttributeValues(
      element, attrsNames, AXCopyMultipleAttributeOptions(), &attrsValues
    )

    guard
      let values = attrsValues as? [AnyObject],
      values.contains(where: { value in
        String(describing: value).contains(/^AirPlay.+would like to AirPlay to.+/)
      }) || values.count(where: { value in
        return value as? String == "AirPlay" || value.contains("would like to AirPlay to")
      }) >= 2
    else {
      logger.debug("Attribute values criteria not met.\n \(attrsValues.debugDescription)")
      return false
    }

    return true
  }

  //  Optional(<__NSArrayM 0x60000054d470>(
  //    AirPlay, AIRPLAY, “DDiPhone16Pro” would like to AirPlay to this Mac.,
  //    26C8EB21-9D81-482A-A932-6366512E2EE6,
  //    AXGroup,
  //    AXNotificationCenterAlert,
  //    <AXValue 0x600000b5b000> {value = error:-25212 type = kAXValueAXErrorType}
  //  ))

  static public func inspectAirPlayRequestNotifications() {
    guard
      let notificationCenterApp = getApplicationElement(for: "com.apple.notificationcenterui"),
      let notificationCenterWindow = getApplicationFirstWindow(of: notificationCenterApp)
    else { return }

    _ = inspectElementChildren(of: notificationCenterWindow)
  }
}
