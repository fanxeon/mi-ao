// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import Foundation

enum SubmissionMode: String, Codable, CaseIterable {
    case codex
    case transcriptionOnly = "transcription_only"
}

struct AppPreferences: Codable, Equatable {
    static let currentSchemaVersion = 2

    var schemaVersion = currentSchemaVersion
    var hasCompletedSetup = false
    var submissionMode: SubmissionMode = .codex
    var buttonControlEnabled = true
    var selectedPresetID = "pointer"
    var preferredPeripheralIdentifier: UUID?

    static let defaults = AppPreferences()

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case hasCompletedSetup
        case submissionMode
        case buttonControlEnabled
        case selectedPresetID
        case preferredPeripheralIdentifier
    }

    init(
        schemaVersion: Int = currentSchemaVersion,
        hasCompletedSetup: Bool = false,
        submissionMode: SubmissionMode = .codex,
        buttonControlEnabled: Bool = true,
        selectedPresetID: String = "pointer",
        preferredPeripheralIdentifier: UUID? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.hasCompletedSetup = hasCompletedSetup
        self.submissionMode = submissionMode
        self.buttonControlEnabled = buttonControlEnabled
        self.selectedPresetID = selectedPresetID
        self.preferredPeripheralIdentifier = preferredPeripheralIdentifier
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion =
            try container.decodeIfPresent(Int.self, forKey: .schemaVersion)
            ?? Self.currentSchemaVersion
        hasCompletedSetup = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedSetup) ?? false
        submissionMode = try container.decodeIfPresent(SubmissionMode.self, forKey: .submissionMode) ?? .codex
        buttonControlEnabled = try container.decodeIfPresent(Bool.self, forKey: .buttonControlEnabled) ?? true
        selectedPresetID = try container.decodeIfPresent(String.self, forKey: .selectedPresetID) ?? "pointer"
        preferredPeripheralIdentifier = try container.decodeIfPresent(
            UUID.self,
            forKey: .preferredPeripheralIdentifier
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(hasCompletedSetup, forKey: .hasCompletedSetup)
        try container.encode(submissionMode, forKey: .submissionMode)
        try container.encode(buttonControlEnabled, forKey: .buttonControlEnabled)
        try container.encode(selectedPresetID, forKey: .selectedPresetID)
        try container.encodeIfPresent(
            preferredPeripheralIdentifier,
            forKey: .preferredPeripheralIdentifier
        )
    }

    var requiresAccessibility: Bool {
        submissionMode == .codex || buttonControlEnabled
    }

    var requiresCodex: Bool {
        submissionMode == .codex || buttonControlEnabled
    }

    var requiresCodexCompatibility: Bool {
        submissionMode == .codex
    }

    var runtimeArguments: [String] {
        var arguments = ["--name", "小米蓝牙语音遥控器"]
        if submissionMode == .transcriptionOnly {
            arguments.append("--no-submit")
        }
        if !buttonControlEnabled {
            arguments.append("--no-buttons")
        }
        arguments.append(contentsOf: ["--preset", selectedPresetID])
        if let preferredPeripheralIdentifier {
            arguments.append(contentsOf: ["--identifier", preferredPeripheralIdentifier.uuidString])
        }
        return arguments
    }
}

enum AppPreferencesLoadState: Equatable {
    case defaults
    case loaded
    case recoveredInvalid(URL)
    case unsupportedVersion(Int)
}

struct AppPreferencesSnapshot: Equatable {
    let preferences: AppPreferences
    let state: AppPreferencesLoadState
}

enum AppPreferencesError: LocalizedError {
    case unsupportedVersion(Int)
    case invalidPreset

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let version):
            return "配置来自较新的 schema v\(version)，当前版本无法安全写入"
        case .invalidPreset:
            return "按键预设标识不能为空"
        }
    }
}

struct AppPreferencesStore {
    let fileURL: URL
    private let fileManager: FileManager
    private let now: () -> Date

    init(
        fileURL: URL = AppPreferencesStore.defaultFileURL,
        fileManager: FileManager = .default,
        now: @escaping () -> Date = Date.init
    ) {
        self.fileURL = fileURL
        self.fileManager = fileManager
        self.now = now
    }

    static var defaultFileURL: URL {
        let environment = ProcessInfo.processInfo.environment
        let dataDirectory: String
        if let override = environment["VOICE_BRIDGE_DATA_DIR"], !override.isEmpty {
            dataDirectory = NSString(string: override).expandingTildeInPath
        } else {
            dataDirectory =
                NSString(string: "~/Library/Application Support/mi-ao").expandingTildeInPath
        }
        return URL(fileURLWithPath: dataDirectory, isDirectory: true)
            .appendingPathComponent("preferences.json")
    }

    func load() -> AppPreferencesSnapshot {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return AppPreferencesSnapshot(preferences: .defaults, state: .defaults)
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let preferences = try JSONDecoder().decode(AppPreferences.self, from: data)
            guard preferences.schemaVersion <= AppPreferences.currentSchemaVersion else {
                return AppPreferencesSnapshot(
                    preferences: .defaults,
                    state: .unsupportedVersion(preferences.schemaVersion)
                )
            }
            return AppPreferencesSnapshot(preferences: preferences, state: .loaded)
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
                return AppPreferencesSnapshot(
                    preferences: .defaults,
                    state: .recoveredInvalid(quarantineURL)
                )
            } catch {
                return AppPreferencesSnapshot(preferences: .defaults, state: .defaults)
            }
        }
    }

    func save(_ preferences: AppPreferences) throws {
        guard preferences.schemaVersion <= AppPreferences.currentSchemaVersion else {
            throw AppPreferencesError.unsupportedVersion(preferences.schemaVersion)
        }
        guard !preferences.selectedPresetID.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AppPreferencesError.invalidPreset
        }
        try prepareDirectory()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var data = try encoder.encode(preferences)
        data.append(0x0A)
        try data.write(to: fileURL, options: .atomic)
        try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
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
            .appendingPathComponent("preferences.invalid-\(formatter.string(from: date)).json")
    }
}
