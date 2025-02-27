import Testing
@testable import Accept_AirPlay_Requests

@Suite struct AARBundleTests {
  @Suite struct ValuesExist {
    private let testBundle: AARBundle = .init(infoDictionary: [
      "AARDocumentationUrl": "docs-url-stub",
      "AARLaunchAgentPlist": "launch-agent-plist-stub",
      "CFBundleName": "name-stub",
      "CFBundleShortVersionString": "version-stub",
      "CFBundleVersion": "build-number-stub"
    ])

    @Test func name() {
      #expect(testBundle.name == "name-stub")
    }

    @Test func version() {
      #expect(testBundle.version == "version-stub")
    }

    @Test func buildNumber() {
      #expect(testBundle.buildNumber == "build-number-stub")
    }

    @Test func launchAgentPlist() {
      #expect(testBundle.launchAgentPlist == "launch-agent-plist-stub")
    }

    @Test func docsUrl() {
      #expect(testBundle.docsUrl == "docs-url-stub")
    }
  }

  @Suite struct ValuesDoNotExist {
    private let testBundle: AARBundle = .init(infoDictionary: [:])
    private let unknownValue: String = "unknown"

    @Test func name() {
      #expect(testBundle.name == unknownValue)
    }

    @Test func version() {
      #expect(testBundle.version == unknownValue)
    }

    @Test func buildNumber() {
      #expect(testBundle.buildNumber == unknownValue)
    }

    @Test func launchAgentPlist() {
      #expect(testBundle.launchAgentPlist == unknownValue)
    }

    @Test func docsUrl() {
      #expect(testBundle.docsUrl == unknownValue)
    }
  }
}
