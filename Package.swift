// swift-tools-version: 6.0
// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import PackageDescription

let package = Package(
    name: "MiAo",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "mi-ao", targets: ["MiAo"])
    ],
    targets: [
        .executableTarget(
            name: "MiAo",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("CoreBluetooth"),
                .linkedFramework("IOKit"),
                .linkedFramework("ServiceManagement"),
            ]
        ),
        .testTarget(
            name: "MiAoTests",
            dependencies: ["MiAo"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
