// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "StretchlyCore",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [
    .library(name: "StretchlyCore", targets: ["StretchlyCore"])
  ],
  targets: [
    .target(name: "StretchlyCore"),
    .testTarget(name: "StretchlyCoreTests", dependencies: ["StretchlyCore"])
  ]
)
