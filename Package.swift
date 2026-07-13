// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "XiaomiVoiceBridge",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "xiaomi-voice-bridge", targets: ["XiaomiVoiceBridge"])
    ],
    targets: [
        .executableTarget(
            name: "XiaomiVoiceBridge",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("CoreBluetooth"),
            ]
        ),
        .testTarget(
            name: "XiaomiVoiceBridgeTests",
            dependencies: ["XiaomiVoiceBridge"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
