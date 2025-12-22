// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "EasyVJEffects",
  platforms: [
    .iOS(.v17),
    .macOS(.v14),
    .visionOS(.v1),
  ],
  products: [
    .library(
      name: "EasyVJEffects",
      targets: ["EasyVJEffects"]
    )
  ],
  targets: [
    .target(
      name: "EasyVJEffects"
    ),
  ]
)
