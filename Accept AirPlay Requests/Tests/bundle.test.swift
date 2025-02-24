import Testing
@testable import Accept_AirPlay_Requests

@Suite struct AARBundleTests {
  @Suite struct ValuesExist {
    private let TestBundle: AARBundle = .init(infoDictionary: [
      "CFBundleName": "nameStub",
      "CFBundleShortVersionString": "versionStub",
      "CFBundleVersion": "buildNumberStub",
      "LSEnvironment": [
        "AARDocumentationUrl": "docsUrlStub"
      ]
    ])

    @Test func name() {
      #expect(TestBundle.name == "nameStub")
    }

    @Test func version() {
      #expect(TestBundle.version == "versionStub")
    }

    @Test func buildNumber() {
      #expect(TestBundle.buildNumber == "buildNumberStub")
    }

    @Test func docsUrl() {
      #expect(TestBundle.docsUrl == "docsUrlStub")
    }
  }

  @Suite struct ValuesDoNotExist {
    private let TestBundle: AARBundle = .init(infoDictionary: [:])

    @Test func name() {
      #expect(TestBundle.name == "unknown")
    }

    @Test func version() {
      #expect(TestBundle.version == "unknown")
    }

    @Test func buildNumber() {
      #expect(TestBundle.buildNumber == "unknown")
    }

    @Test func docsUrl() {
      #expect(TestBundle.docsUrl == "unknown")
    }
  }
}
