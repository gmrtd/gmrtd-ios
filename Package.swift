// swift-tools-version:5.9
import PackageDescription

// Bumped by the automated gmrtd-release-tracking job — keep this exact
// `let name = "value"` shape so the bot can locate/replace by regex.
let gmrtdCoreVersion = "1.5.2"
let gmrtdCoreChecksum = "e76b4562431d6880cbc1a276671874d340ddbc490cbad83ff51cbe5e6ba55acf"

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
