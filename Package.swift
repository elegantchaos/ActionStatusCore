// swift-tools-version:5.2

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
        .package(url: "https://github.com/elegantchaos/BindingsExtensions.git", from: "1.0.1"),
        .package(url: "https://github.com/elegantchaos/Bundles.git", from: "1.0.6"),
        .package(url: "https://github.com/elegantchaos/DictionaryCoding.git", from: "1.0.9"),
        .package(url: "https://github.com/elegantchaos/Logger.git", from: "1.5.5"),
        .package(url: "https://github.com/elegantchaos/Hardware.git", from: "1.0.1"),
        .package(url: "https://github.com/elegantchaos/Octoid.git", from: "1.0.1"),
        .package(url: "https://github.com/elegantchaos/SwiftUIExtensions.git", from: "1.1.1"),
    ],
    targets: [
        .target(
            name: "ActionStatusCore",
            dependencies: [
                "BindingsExtensions",
                "Bundles",
                "DictionaryCoding",
                "Hardware",
                "Logger",
                "Octoid",
                "SwiftUIExtensions"
            ]),
        .testTarget(
            name: "ActionStatusCoreTests",
            dependencies: ["ActionStatusCore", "DictionaryCoding"]),
    ]
)
