// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import Foundation
import Testing

@testable import MiAo

@Test func appPreferencesPersistPrivatelyAndBuildRuntimeArguments() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("mi-ao-preferences-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let fileURL = root.appendingPathComponent("preferences.json")
    let store = AppPreferencesStore(fileURL: fileURL)

    var preferences = AppPreferences.defaults
    preferences.hasCompletedSetup = true
    preferences.submissionMode = .transcriptionOnly
    preferences.buttonControlEnabled = false
    preferences.selectedPresetID = "personal"
    preferences.preferredPeripheralIdentifier = UUID(
        uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"
    )
    try store.save(preferences)

    #expect(store.load() == AppPreferencesSnapshot(preferences: preferences, state: .loaded))
    #expect(
        preferences.runtimeArguments == [
            "--name",
            "小米蓝牙语音遥控器",
            "--no-submit",
            "--no-buttons",
            "--preset",
            "personal",
            "--identifier",
            "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE",
        ]
    )

    let directoryMode = try permissions(at: root)
    let fileMode = try permissions(at: fileURL)
    #expect(directoryMode & 0o777 == 0o700)
    #expect(fileMode & 0o777 == 0o600)
}

@Test func appPreferencesQuarantineInvalidJSONAndRecoverDefaults() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("mi-ao-preferences-invalid-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let fileURL = root.appendingPathComponent("preferences.json")
    try Data("{not-json".utf8).write(to: fileURL)
    let store = AppPreferencesStore(
        fileURL: fileURL,
        now: { Date(timeIntervalSince1970: 0) }
    )

    let snapshot = store.load()
    #expect(snapshot.preferences == .defaults)
    guard case .recoveredInvalid(let quarantineURL) = snapshot.state else {
        Issue.record("损坏配置没有进入隔离恢复状态")
        return
    }
    #expect(quarantineURL.lastPathComponent == "preferences.invalid-19700101-000000.json")
    #expect(FileManager.default.fileExists(atPath: quarantineURL.path))
    #expect(!FileManager.default.fileExists(atPath: fileURL.path))
    #expect(try permissions(at: quarantineURL) & 0o777 == 0o600)
}

@Test func appPreferencesPreserveUnsupportedFutureSchema() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("mi-ao-preferences-future-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let fileURL = root.appendingPathComponent("preferences.json")
    var future = AppPreferences.defaults
    future.schemaVersion = AppPreferences.currentSchemaVersion + 1
    try JSONEncoder().encode(future).write(to: fileURL)

    let snapshot = AppPreferencesStore(fileURL: fileURL).load()
    #expect(snapshot.preferences == .defaults)
    #expect(snapshot.state == .unsupportedVersion(AppPreferences.currentSchemaVersion + 1))
    #expect(FileManager.default.fileExists(atPath: fileURL.path))
}

@Test func appPreferencesMigrateV1WithoutPresetSelection() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("mi-ao-preferences-v1-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let fileURL = root.appendingPathComponent("preferences.json")
    try Data(
        """
        {"schemaVersion":1,"hasCompletedSetup":true,"submissionMode":"codex","buttonControlEnabled":true}
        """.utf8
    ).write(to: fileURL)

    let snapshot = AppPreferencesStore(fileURL: fileURL).load()
    #expect(snapshot.state == .loaded)
    #expect(snapshot.preferences.selectedPresetID == "pointer")
    #expect(snapshot.preferences.hasCompletedSetup)
}

private func permissions(at url: URL) throws -> Int {
    let value = try FileManager.default.attributesOfItem(atPath: url.path)[.posixPermissions]
    if let number = value as? NSNumber { return number.intValue }
    return try #require(value as? Int)
}
