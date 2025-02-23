// swift-tools-version: 6.0

import Foundation.NSURL
import PackageDescription

let productName: String = URL(filePath: #filePath)
  .deletingLastPathComponent()
  .lastPathComponent

let package = Package(
  name: "\(productName) Package",
  platforms: [
    .macOS(.v13)
  ],
  targets: [
    .executableTarget(
      name: productName
    ),
    .testTarget(
      name: "\(productName) Tests",
      dependencies: [
        .byNameItem(
          name: productName,
          condition: .none
        )
      ]
    )
  ]
)
