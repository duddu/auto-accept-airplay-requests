import Foundation.NSProcessInfo

extension ProcessInfo {
  /// Whether this process executable was launched as a launchd agent.
  /// Evaluates whether the value of the environment variable `AAR_PROCESS_IS_AGENT` is `"1"`.
  /// The variable is assigned in the LaunchAgent.plist.
  public var isLaunchAgent: Bool {
    self.environment["AAR_PROCESS_IS_AGENT"] == "1"
  }

  /// The value of the environment variable `AAR_PROCESS_LABEL`.
  /// The variable is assigned in the Info.plist, and overriden in the LaunchAgent.plist for when the program is managed by launchd.
  public var label: String {
    self.environment["AAR_PROCESS_LABEL"] ?? "\(self.processName)[unlabeled]"
  }
}
