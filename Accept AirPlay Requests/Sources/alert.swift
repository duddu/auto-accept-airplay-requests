import AppKit.NSAlert
import AppKit.NSApplication
import Foundation.NSBundle

@MainActor
public struct AARAlert {
  static private let bundleName = Bundle.main.infoDictionary![kCFBundleNameKey as String]!

  //  private let style: NSAlert.Style
  //  private let title: String
  //  private let message: String
  //  private let okButtonTitle: String
  //  private let cancelButtonTitle: String?

  private let alert: NSAlert
//  private var alert: NSAlert? = .init()

  private init(
    style: NSAlert.Style,
    title: String,
    message: String,
    okButtonTitle: String?,
    cancelButtonTitle: String?
  ) {
    //    self.style = style
    //    self.title = title
    //    self.message = message
    //    self.okButtonTitle = okButtonTitle ?? "OK"
    //    self.cancelButtonTitle = cancelButtonTitle ?? nil
    alert = NSAlert()
//    if let alert {
    alert.alertStyle = style
    alert.messageText = "\(Self.bundleName)\n\(title)"
    alert.informativeText = message
    alert.addButton(withTitle: okButtonTitle ?? "OK")
    if let cancelButtonTitle {
      alert.addButton(withTitle: cancelButtonTitle)
    }
//    }
  }

  //  public struct Response: RawRepresentable, Sendable {
  //    public typealias Response = NSApplication.ModalResponse
  //    public typealias RawValue = Response.RawValue
  //
  //    public let rawValue: RawValue
  //
  //    public init(rawValue: RawValue) {
  //      self.rawValue = rawValue
  //    }
  //
  //    public init(_ response: Response) {
  //      let response: Response = response == .alertFirstButtonReturn ? .OK : .cancel
  //      self.init(rawValue: response.rawValue)
  //    }
  //
  //    public static func from(_ response: Response) -> Self {
  //      .init(response)
  //    }
  //
  //    static let OK: Self = .init(.OK)
  //    static let cancel: Self = .init(.cancel)
  //  }

  private func run() -> NSApplication.ModalResponse {
    //    let alert = NSAlert()
    //    alert.alertStyle = style
    //    alert.messageText = title
    //    alert.informativeText = message
    //    alert.addButton(withTitle: okButtonTitle)
    //    if let cancelButtonTitle {
    //      alert.addButton(withTitle: cancelButtonTitle)
    //    }
    //    return .from(alert.runModal())
    return alert.runModal() == .alertFirstButtonReturn ? .OK : .cancel
//    let response: NSApplication.ModalResponse =
//      alert?.runModal() == .alertFirstButtonReturn ? .OK : .cancel
//    alert = nil
//    return response
  }

  static private func display(
    style: NSAlert.Style,
    title: String,
    message: String,
    okButtonTitle: String? = nil,
    cancelButtonTitle: String? = nil
  ) -> NSApplication.ModalResponse {
    Self.init(
      style: style,
      title: title,
      message: message,
      okButtonTitle: okButtonTitle ?? nil,
      cancelButtonTitle: cancelButtonTitle
    ).run()
  }

  static private func display(
    style: NSAlert.Style,
    title: String,
    message: String,
    okButtonTitle: String? = nil
  ) {
    _ = Self.init(
      style: style,
      title: title,
      message: message,
      okButtonTitle: okButtonTitle,
      cancelButtonTitle: nil
    ).run()
  }

  static public func info(
    title: String,
    message: String,
    okButtonTitle: String? = nil
  ) {
    Self.display(
      style: .informational,
      title: title,
      message: message,
      okButtonTitle: okButtonTitle
    )
  }

  static public func warning(
    title: String,
    message: String,
    okButtonTitle: String? = nil,
    cancelButtonTitle: String? = nil
  ) -> NSApplication.ModalResponse {
    Self.display(
      style: .warning,
      title: title,
      message: message,
      okButtonTitle: okButtonTitle,
      cancelButtonTitle: cancelButtonTitle
    )
  }

  static public func error(
    title: String,
    message: String,
    okButtonTitle: String? = nil
  ) {
    Self.display(
      style: .critical,
      title: title,
      message: message,
      okButtonTitle: okButtonTitle
    )
  }
}
