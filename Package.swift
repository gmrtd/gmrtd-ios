// swift-tools-version:5.9
import PackageDescription

// Bumped by the automated gmrtd-release-tracking job — keep this exact
// `let name = "value"` shape so the bot can locate/replace by regex.
let gmrtdCoreVersion = "1.10.0"
let gmrtdCoreChecksum = "b0bfff2d969bb9c520ba3752faf41aaeae92b3f0b6725c884715d574987ba3aa"

let package = Package(
    name: "GmrtdKit",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "GmrtdKit",
            targets: ["GmrtdKit"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "Gmrtd",
            url: "https://github.com/gmrtd/gmrtd/releases/download/v\(gmrtdCoreVersion)/Gmrtd.xcframework.zip",
            checksum: gmrtdCoreChecksum
        ),
        .target(
            name: "GmrtdKit",
            dependencies: ["Gmrtd"]
        ),
        .testTarget(
            name: "GmrtdKitTests",
            dependencies: ["GmrtdKit"]
        ),
    ]
)
