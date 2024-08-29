// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "Accept AirPlay Requests Executable",
  platforms: [.macOS(.v13)],
  targets: [
    .executableTarget(
      name: "Accept AirPlay Requests"
    )
  ]
)
