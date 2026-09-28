// swift-tools-version:5.9
import PackageDescription

// Bumped by the automated gmrtd-release-tracking job — keep this exact
// `let name = "value"` shape so the bot can locate/replace by regex.
let gmrtdCoreVersion = "1.3.0"
let gmrtdCoreChecksum = "2463c971101b980e994abc04696b65a5072566e5fa7323eb79837dadfc6256e3"

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
