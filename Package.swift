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
        .package(url: "https://github.com/elegantchaos/Bundles.git", from: "1.0.4"),
        .package(url: "https://github.com/elegantchaos/DictionaryCoding.git", from: "1.0.9"),
        .package(url: "https://github.com/elegantchaos/Logger.git", from: "1.5.5"),
        .package(url: "https://github.com/elegantchaos/Hardware.git", from: "1.0.1"),
        .package(url: "https://github.com/elegantchaos/SheetController.git", from: "1.0.2"),
        .package(url: "https://github.com/elegantchaos/SwiftUIExtensions.git", from: "1.3.0"),
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
                "SheetController",
                "SwiftUIExtensions"
            ]),
        .testTarget(
            name: "ActionStatusCoreTests",
            dependencies: ["ActionStatusCore", "DictionaryCoding"]),
    ]
)
