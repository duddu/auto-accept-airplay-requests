import Foundation
import Testing
@testable import Accept_AirPlay_Requests

class BundleMock: Foundation.Bundle, @unchecked Sendable {
  private let _infoDictionaryStub: [String: String]

  init(withInfoDictionary infoDictionary: [String: String]) {
    self._infoDictionaryStub = infoDictionary
    super.init()
  }

  override var infoDictionary: [String: Any] { _infoDictionaryStub }
}

@Suite struct AARBundleTests {
  protocol AARBundleTestsSuite {
    var testBundle: AARBundle { get }
    func testValues() -> ()
  }

  @Suite struct ValidInfoDictionary: AARBundleTestsSuite {
    private let testInfoDictionary: [String: String] = Dictionary(
      uniqueKeysWithValues: [
        "AARDocumentationUrl",
        "AARLaunchAgentLabel",
        "CFBundleName",
        "CFBundleShortVersionString",
        "CFBundleVersion"
      ].map { key in
        (key, UUID().uuidString)
      }
    )

    let testBundle: AARBundle

    init() {
      testBundle = .init(for: BundleMock(withInfoDictionary: testInfoDictionary))
    }

    @Test func testValues() {
      #expect(testBundle.name == testInfoDictionary["CFBundleName"])
      #expect(testBundle.version == testInfoDictionary["CFBundleShortVersionString"])
      #expect(testBundle.buildNumber == testInfoDictionary["CFBundleVersion"])
      #expect(testBundle.launchAgentLabel == testInfoDictionary["AARLaunchAgentLabel"])
      #expect(testBundle.docsUrl == testInfoDictionary["AARDocumentationUrl"])
    }
  }

  @Suite struct InvalidInfoDictionary: AARBundleTestsSuite {
    private let unknownValueStub: String = "unknown-stub"

    let testBundle: AARBundle

    init() {
      testBundle = .init(
        for: BundleMock(withInfoDictionary: [:]),
        unknownValueFallback: unknownValueStub
      )
    }

    @Test func testValues() {
      #expect(testBundle.name == unknownValueStub)
      #expect(testBundle.version == unknownValueStub)
      #expect(testBundle.buildNumber == unknownValueStub)
      #expect(testBundle.launchAgentLabel == unknownValueStub)
      #expect(testBundle.docsUrl == unknownValueStub)
    }
  }
}
