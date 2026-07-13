// swift-tools-version: 6.0
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
            ]
        ),
        .testTarget(
            name: "MiAoTests",
            dependencies: ["MiAo"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
