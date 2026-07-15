// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import Foundation

enum ButtonPresetCatalogLoadState: Equatable {
    case defaults
    case loaded
    case recoveredInvalid(URL)
    case unsupportedVersion(Int)
}

struct ButtonPresetCatalogSnapshot: Equatable {
    let catalog: ButtonPresetCatalog
    let state: ButtonPresetCatalogLoadState
}

enum ButtonPresetStoreError: LocalizedError {
    case unsupportedVersion(Int)

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let version):
            return "按键配置来自较新的 schema v\(version)，当前版本无法安全写入"
        }
    }
}

struct ButtonPresetStore {
    private struct Document: Codable {
        static let currentSchemaVersion = 1

        let schemaVersion: Int
        let presets: [StoredPreset]
    }

    private struct StoredPreset: Codable {
        let id: String
        let name: String
        let bindings: [String: ButtonBinding]
    }

    let fileURL: URL
    private let fileManager: FileManager
    private let now: () -> Date

    init(
        fileURL: URL = ButtonPresetStore.defaultFileURL,
        fileManager: FileManager = .default,
        now: @escaping () -> Date = Date.init
    ) {
        self.fileURL = fileURL
        self.fileManager = fileManager
        self.now = now
    }

    static var defaultFileURL: URL {
        AppPreferencesStore.defaultFileURL
            .deletingLastPathComponent()
            .appendingPathComponent("button-presets.json")
    }

    func load() -> ButtonPresetCatalogSnapshot {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return ButtonPresetCatalogSnapshot(catalog: .builtIn, state: .defaults)
        }
        do {
            let document = try JSONDecoder().decode(Document.self, from: Data(contentsOf: fileURL))
            guard document.schemaVersion <= Document.currentSchemaVersion else {
                return ButtonPresetCatalogSnapshot(
                    catalog: .builtIn,
                    state: .unsupportedVersion(document.schemaVersion)
                )
            }
            let catalog = try catalog(from: document)
            return ButtonPresetCatalogSnapshot(catalog: catalog, state: .loaded)
        } catch {
            let quarantineURL = quarantineURL(for: now())
            do {
                try prepareDirectory()
                if fileManager.fileExists(atPath: quarantineURL.path) {
                    try fileManager.removeItem(at: quarantineURL)
                }
                try fileManager.moveItem(at: fileURL, to: quarantineURL)
                try fileManager.setAttributes(
                    [.posixPermissions: 0o600],
                    ofItemAtPath: quarantineURL.path
                )
                return ButtonPresetCatalogSnapshot(
                    catalog: .builtIn,
                    state: .recoveredInvalid(quarantineURL)
                )
            } catch {
                return ButtonPresetCatalogSnapshot(catalog: .builtIn, state: .defaults)
            }
        }
    }

    func save(_ catalog: ButtonPresetCatalog) throws {
        try catalog.validate()
        try prepareDirectory()
        let document = Document(
            schemaVersion: Document.currentSchemaVersion,
            presets: catalog.userPresets.map { preset in
                StoredPreset(
                    id: preset.id,
                    name: preset.name,
                    bindings: Dictionary(
                        uniqueKeysWithValues: preset.bindings.map { ($0.key.rawValue, $0.value) }
                    )
                )
            }
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var data = try encoder.encode(document)
        data.append(0x0A)
        try data.write(to: fileURL, options: .atomic)
        try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
    }

    private func catalog(from document: Document) throws -> ButtonPresetCatalog {
        let presets = try document.presets.map { storedPreset -> ButtonPreset in
            var bindings = ButtonPreset.pointer.bindings
            for (rawButton, binding) in storedPreset.bindings {
                guard let button = RemoteButton(rawValue: rawButton) else {
                    throw BridgeError.configuration("按键配置包含未知按钮：\(rawButton)")
                }
                bindings[button] = binding
            }
            return ButtonPreset(
                id: storedPreset.id,
                name: storedPreset.name,
                bindings: bindings,
                requiredButtons: ButtonPreset.pointer.requiredButtons,
                isBuiltIn: false
            )
        }
        let catalog = ButtonPresetCatalog(userPresets: presets)
        try catalog.validate()
        return catalog
    }

    private func prepareDirectory() throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        try fileManager.setAttributes(
            [.posixPermissions: 0o700],
            ofItemAtPath: directoryURL.path
        )
    }

    private func quarantineURL(for date: Date) -> URL {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return fileURL.deletingLastPathComponent()
            .appendingPathComponent("button-presets.invalid-\(formatter.string(from: date)).json")
    }
}
