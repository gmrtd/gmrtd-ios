// swift-tools-version:5.9
import PackageDescription

// Bumped by the automated gmrtd-release-tracking job — keep this exact
// `let name = "value"` shape so the bot can locate/replace by regex.
let gmrtdCoreVersion = "1.4.0"
let gmrtdCoreChecksum = "d636b545b1d9c5fb4cd996890718ae9c2349446c363dd97de30852b828ee84a4"

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
