import os.log

public struct AARLogger {
  static private let subsystem = "dev.duddu.accept-airplay-requests"

  static public func withCategory(_ category: String) -> Logger {
    return Logger(
      subsystem: subsystem,
      category: category
    )
  }
}

public struct AARTimer {
  static public func sleep(_ seconds: Double) async {
    try? await Task.sleep(
      for: .seconds(seconds),
      tolerance: .seconds(seconds / 10 * 2),
      clock: ContinuousClock()
    )
  }
}
