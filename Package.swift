// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "ActionStatusCore",
    platforms: [
        .macOS(.v10_15), .iOS(.v13), .tvOS(.v13)
    ],
    products: [
        .library(
            name: "ActionStatusCore",
            targets: ["ActionStatusCore"]),
    ],
    dependencies: [
        .package(url: "http://github.com/elegantchaos/DictionaryCoding.git", from: "1.0.9")
    ],
    targets: [
        .target(
            name: "ActionStatusCore",
            dependencies: ["DictionaryCoding"]),
        .testTarget(
            name: "ActionStatusCoreTests",
            dependencies: ["ActionStatusCore", "DictionaryCoding"]),
    ]
)
