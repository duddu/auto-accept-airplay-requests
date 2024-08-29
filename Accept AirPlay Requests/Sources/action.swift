import AppKit.NSApplication

public struct AARActionManager {
  static public func initialize() {
    Task {
      repeat {
        if await AARSecurityManager.hasAccessibilityAccess {
          acceptAirPlayRequest()
        } else {
          if await !AARSecurityManager.isBusy {
            await AARSecurityManager.ensureAccessibilityAccess()
          }
        }
        try? await Task.sleep(for: .seconds(5))
      } while true
    }
  }

  static private func getApplicationElement(for bundleId: String) -> AXUIElement? {
    guard
      let runningApp: NSRunningApplication = NSWorkspace.shared.runningApplications.first(where: {
        $0.bundleIdentifier == bundleId
      })
    else {
      print("App with bundle id \(bundleId) is not running.")
      return nil
    }
    return AXUIElementCreateApplication(runningApp.processIdentifier)
  }

  static private func getApplicationFirstWindow(of appElement: AXUIElement) -> AXUIElement? {
    var windowsArray: CFTypeRef?
    AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsArray)
    guard let windows = windowsArray as? [AXUIElement], !windows.isEmpty
    else {
      print("No windows found for the application.")
      return nil
    }
    return windows.first
  }

  static private func inspectElementChildren(of element: AXUIElement) {
    var childrenArray: CFTypeRef?
    AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenArray)

    guard let children = childrenArray as? [AXUIElement] else { return }

    for child in children {
      var actionNamesArray: CFArray?
      AXUIElementCopyActionNames(child, &actionNamesArray)

      guard let actionNames = actionNamesArray as? [String] else { return }

      // @TODO swap from Slose to Accept action name and description
      let closeActionNames = actionNames.filter({ name in
        return name.starts(with: "Name:Close")
      })

      for closeActionName in closeActionNames {
        var description: CFString?
        AXUIElementCopyActionDescription(child, closeActionName as CFString, &description)

        if let closeActionDescription = description as? String, closeActionDescription == "Close" {
//          let attrs = _getAXUIElementAttributesValues(of: child)
//          print("\(closeActionDescription) -- \(attrs)")

          AXUIElementPerformAction(child, closeActionName as CFString)
          return
        }
      }

      inspectElementChildren(of: child)
    }
  }

  static private func inspectElementAttrs(of element: AXUIElement) -> String? {
    var attrsValues: CFArray?
    if AXUIElementCopyMultipleAttributeValues(
      element,
      [
        kAXIdentifierAttribute, kAXRoleAttribute, kAXSubroleAttribute,
        kAXValueAttribute, kAXDescription,
      ] as CFArray, AXCopyMultipleAttributeOptions(), &attrsValues)
      == .success
    {
      // @TODO if attrValues contain right strings
      return attrsValues.debugDescription.replacingOccurrences(
        of: "\n", with: " # ")
    } else {
      print("Failed to retrieve attrValues.")
      return nil
    }
  }

  static private func acceptAirPlayRequest() {
    guard let notificationCenterApp = getApplicationElement(for: "com.apple.notificationcenterui")
    else {
      print("getApplicationElement failed")
      return
    }

    guard let notificationCenterWindow = getApplicationFirstWindow(of: notificationCenterApp)
    else {
      print("getFirstWindow failed")
      return
    }

    inspectElementChildren(of: notificationCenterWindow)
  }
}
