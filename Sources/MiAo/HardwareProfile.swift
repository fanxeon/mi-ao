// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import Foundation

struct HardwareProfile: Codable, Equatable {
    struct Button: Codable, Equatable {
        let button: RemoteButton
        let usagePage: Int
        let usage: Int
        let intercept: Bool
    }

    let schemaVersion: Int
    let id: String
    let displayName: String
    let firmware: String
    let vendorID: Int
    let productID: Int
    let productName: String
    let transport: String
    let stateFile: String
    let buttons: [Button]

    var interceptedButtons: [Button] {
        buttons.filter(\.intercept)
    }

    func makeButtonMap(sourceURL: URL, preset: ButtonPreset) throws -> CalibratedButtonMap {
        var buttonsByUsage: [HIDUsageKey: RemoteButton] = [:]
        var usagesByButton: [RemoteButton: HIDUsageKey] = [:]

        for definition in buttons {
            let key = HIDUsageKey(page: definition.usagePage, usage: definition.usage)
            if let existing = buttonsByUsage[key], existing != definition.button {
                throw BridgeError.configuration(
                    "内置硬件档案冲突：\(existing.rawValue) 与 \(definition.button.rawValue) 使用相同 Usage"
                )
            }
            if usagesByButton[definition.button] != nil {
                throw BridgeError.configuration("内置硬件档案重复按钮：\(definition.button.rawValue)")
            }
            buttonsByUsage[key] = definition.button
            usagesByButton[definition.button] = key
        }

        guard preset.requiredButtons.isSubset(of: Set(usagesByButton.keys)) else {
            throw BridgeError.configuration("内置硬件档案缺少 \(preset.id) 必需按钮")
        }

        return CalibratedButtonMap(
            vendorID: vendorID,
            productID: productID,
            productName: productName,
            buttonsByUsage: buttonsByUsage,
            usagesByButton: usagesByButton,
            sourceFiles: [sourceURL]
        )
    }

    func replacingUsages(with map: CalibratedButtonMap) throws -> HardwareProfile {
        let updatedButtons = try buttons.map { definition -> Button in
            guard let key = map.usagesByButton[definition.button] else {
                throw BridgeError.configuration(
                    "解析后的硬件档案缺少按钮：\(definition.button.rawValue)"
                )
            }
            return Button(
                button: definition.button,
                usagePage: key.page,
                usage: key.usage,
                intercept: definition.intercept
            )
        }
        return HardwareProfile(
            schemaVersion: schemaVersion,
            id: id,
            displayName: displayName,
            firmware: firmware,
            vendorID: vendorID,
            productID: productID,
            productName: productName,
            transport: transport,
            stateFile: stateFile,
            buttons: updatedButtons
        )
    }
}

enum HardwareProfileStore {
    static let defaultFilename = "xiaomi-remote-2-pro-2671.plist"

    static func load(from url: URL) throws -> HardwareProfile {
        let data = try Data(contentsOf: url)
        let profile = try PropertyListDecoder().decode(HardwareProfile.self, from: data)
        guard profile.schemaVersion == 1 else {
            throw BridgeError.configuration(
                "不支持的硬件档案版本 \(profile.schemaVersion)：\(url.path)"
            )
        }
        return profile
    }

    static func loadBuiltIn(
        vendorID: Int,
        productID: Int,
        preset: ButtonPreset
    ) throws -> CalibratedButtonMap? {
        guard let profile = try loadBuiltInProfile(vendorID: vendorID, productID: productID),
            let url = builtInProfileURL()
        else { return nil }
        return try profile.makeButtonMap(sourceURL: url, preset: preset)
    }

    static func loadBuiltInProfile(vendorID: Int, productID: Int) throws -> HardwareProfile? {
        guard let url = builtInProfileURL() else { return nil }
        let profile = try load(from: url)
        guard profile.vendorID == vendorID, profile.productID == productID else { return nil }
        return profile
    }

    static func write(_ profile: HardwareProfile, to path: String) throws {
        let url = URL(fileURLWithPath: path)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        try encoder.encode(profile).write(to: url, options: .atomic)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: url.path
        )
    }

    static func builtInProfileURL() -> URL? {
        let environment = ProcessInfo.processInfo.environment
        if let explicit = environment["MI_AO_HARDWARE_PROFILE"], !explicit.isEmpty {
            return URL(fileURLWithPath: explicit)
        }

        if let resourceURL = Bundle.main.resourceURL {
            let bundled =
                resourceURL
                .appendingPathComponent("HardwareProfiles", isDirectory: true)
                .appendingPathComponent(defaultFilename)
            if FileManager.default.fileExists(atPath: bundled.path) { return bundled }
        }

        let sourceTree = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Resources/HardwareProfiles", isDirectory: true)
            .appendingPathComponent(defaultFilename)
        if FileManager.default.fileExists(atPath: sourceTree.path) { return sourceTree }
        return nil
    }
}
