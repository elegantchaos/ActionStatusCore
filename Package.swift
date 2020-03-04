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
        .package(url: "https://github.com/elegantchaos/DictionaryCoding.git", from: "1.0.9"),
        .package(url: "https://github.com/elegantchaos/Logger.git", from: "1.5.1"),
        .package(url: "https://github.com/elegantchaos/Hardware.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "ActionStatusCore",
            dependencies: ["DictionaryCoding", "Hardware", "Logger"]),
        .testTarget(
            name: "ActionStatusCoreTests",
            dependencies: ["ActionStatusCore", "DictionaryCoding"]),
    ]
)
