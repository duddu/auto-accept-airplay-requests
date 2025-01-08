import AppKit.NSApplication
import AppKit.NSRunningApplication
import AppKit.NSWorkspace
import ApplicationServices.HIServices

// @TODO improve methods naming and reorder
public struct AARAirPlayManager: AARLoggable {
  static private let notificationCenterBundleId = "com.apple.notificationcenterui"

  private var notificationCenterWindow: AXUIElement? = nil

  private typealias UIElementWithAction = (AXUIElement, CFString)

  public init() {
    self.notificationCenterWindow = getNotificationCenterUIWindow()
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
//        guard String(describing: name).lowercased().starts(with: "name:accept") else { continue }
//        Self.logger.info("action name matched: \(String(describing: name), privacy: .public)")
//
//        var description: CFString?
//        AXUIElementCopyActionDescription(child, name, &description)
//        guard let description = description as? String, description.lowercased() == "accept"
//        else {
//          Self.logger.debug(
//            "action description not matched: \(String(describing: description), privacy: .public)"
//          )
//          continue
//        }
//        Self.logger.info("action description match")

        guard validateNotificationAction(of: child, name: name) else { continue }
        Self.logger.info("action validation passed")

        guard validateNotificationAttributes(of: child) else { continue }
        Self.logger.info("attributes validation passed")

//        guard AXUIElementPerformAction(child, name) == .success else { continue }
//        Self.logger.info("action performed successfully")

//        return
        return(child, name)
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

  // @TODO maybe store it and only get it fresh once something goes wrong?
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

  private func getNotificationCenterUIWindow() -> AXUIElement? {
    guard
      let notificationCenterUIElement = getApplicationUIElement(for: AARAirPlayManager.notificationCenterBundleId)
    else { return nil }

    var windowsRef: CFTypeRef?
    AXUIElementCopyAttributeValue(notificationCenterUIElement, kAXWindowsAttribute as CFString, &windowsRef)

    guard
      let windows = windowsRef as? [AXUIElement], !windows.isEmpty
    else {
      Self.logger.debug("notification center has no active windows")
      return nil
    }

    return windows.first
  }

  private func getUIElementChildren(of element: AXUIElement) -> [AXUIElement] {
    var children: CFTypeRef?
    AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &children)

    return children as? [AXUIElement] ?? []
  }

  // @TODO rename and change return type
  private func validateNotificationAttributes(of element: AXUIElement) -> Bool {
//    let attrsNames =
//      [
//        kAXDescription,
////        kAXIdentifierAttribute,
////        kAXRoleAttribute,
////        kAXSubroleAttribute,
////        kAXValueAttribute,
////        kAXTitleAttribute,
////        kAXTitleUIElementAttribute,
////        kAXSharedTextUIElementsAttribute,
////        kAXVisibleTextAttribute,
////        kAXContentsAttribute
//      ]
//    var attrsValues: CFArray?
//    AXUIElementCopyMultipleAttributeValues(
//      element, attrsNames as CFArray, AXCopyMultipleAttributeOptions(), &attrsValues
//    )
//
//    // @TODO log only values instead
//    let attrsDict = Dictionary(uniqueKeysWithValues: zip(
//      attrsNames as [String], attrsValues as? [CFTypeRef] ?? [])
//    )
//    Self.logger.debug("attributes inspected:") // \(attrsDict.debugDescription, privacy: .public)")
//    for (key, value) in attrsDict {
//      Self.logger.debug("\(key, privacy: .public): \(String(describing: value), privacy: .public)")
//    }

//    guard
//      let values = attrsValues as? [CFTypeRef],
//      values.contains(where: { value in
//        String(describing: value).contains(/^AirPlay.+would like to AirPlay to.+/)
//      })
////        || values.count(where: { value in
////          return value as? String == "AirPlay" || value.contains("would like to AirPlay to")
////        }) >= 2
//    else {
//      Self.logger.debug("attributes values inpection failed")

    var description: CFTypeRef?
    AXUIElementCopyAttributeValue(element, kAXDescription as CFString, &description)

    guard let description = description as? String else { return false }
    Self.logger.debug("attribute description: \(description, privacy: .public)")

    // @TODO extract other regexs and strings in static lets
    if let _ = try? (/^airplay.+would like to airplay to this mac\.$/.ignoresCase()).wholeMatch(
      in: description
    ) { return true }

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

  //  Optional(<__NSArrayM 0x60000054d470>(
  //    AirPlay, AIRPLAY, “DDiPhone16Pro” would like to AirPlay to this Mac.,
  //    26C8EB21-9D81-482A-A932-6366512E2EE6,
  //    AXGroup,
  //    AXNotificationCenterAlert,
  //    <AXValue 0x600000b5b000> {value = error:-25212 type = kAXValueAXErrorType}
  //  ))
}
