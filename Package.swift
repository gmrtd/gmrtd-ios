// swift-tools-version:5.9
import PackageDescription

// Bumped by the automated gmrtd-release-tracking job — keep this exact
// `let name = "value"` shape so the bot can locate/replace by regex.
let gmrtdCoreVersion = "1.7.1"
let gmrtdCoreChecksum = "1f3dcb7269db41b005fb4f98405202e5b7840af2f11f3bbabff9c612eba469b3"

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
