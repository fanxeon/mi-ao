// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import Foundation
import Testing

@testable import MiAo

@Test func savedButtonPresetsRoundTripAndTVSwitchesConfiguration() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("mi-ao-button-presets-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let store = ButtonPresetStore(fileURL: root.appendingPathComponent("button-presets.json"))

    var writingBindings = ButtonPreset.pointer.bindings
    writingBindings[.tv] = .presetSwitch("user.review")
    let writing = ButtonPreset(
        id: "user.writing",
        name: "写作",
        bindings: writingBindings,
        requiredButtons: ButtonPreset.pointer.requiredButtons,
        isBuiltIn: false
    )
    var reviewBindings = ButtonPreset.pointer.bindings
    reviewBindings[.tv] = .presetSwitch("user.writing")
    reviewBindings[.volumeUp] = .action(.keyboardPageUp)
    let review = ButtonPreset(
        id: "user.review",
        name: "审阅",
        bindings: reviewBindings,
        requiredButtons: ButtonPreset.pointer.requiredButtons,
        isBuiltIn: false
    )
    let catalog = ButtonPresetCatalog(userPresets: [writing, review])
    try store.save(catalog)

    let loaded = store.load()
    #expect(loaded.state == .loaded)
    #expect(try loaded.catalog.preset(id: "user.review").binding(for: .volumeUp) == .action(.keyboardPageUp))

    var switchedID: String?
    var activity: MiAoCommandActivity?
    let executor = ButtonActionExecutor(
        preset: try loaded.catalog.preset(id: "user.writing"),
        catalog: loaded.catalog,
        presetChangeHandler: { preset in switchedID = preset.id },
        activityHandler: { activity = $0 }
    )
    executor.buttonDown(.tv)
    #expect(executor.preset.id == "user.review")
    #expect(switchedID == "user.review")
    #expect(activity == .presetChanged(name: "审阅"))
}

@Test func invalidTVTargetAndDangerousShortcutAreRejected() throws {
    var invalidBindings = ButtonPreset.pointer.bindings
    invalidBindings[.tv] = .presetSwitch("user.missing")
    let invalidPreset = ButtonPreset(
        id: "user.invalid",
        name: "无效",
        bindings: invalidBindings,
        requiredButtons: ButtonPreset.pointer.requiredButtons,
        isBuiltIn: false
    )
    do {
        try ButtonPresetCatalog(userPresets: [invalidPreset]).validate()
        Issue.record("缺失 TV 目标的配置不应通过校验")
    } catch {}

    do {
        _ = try KeyboardShortcutSpec(keyCode: 12, modifiers: [.command], keyLabel: "Q")
        Issue.record("Command-Q 不应成为遥控器快捷键")
    } catch {}
}

@Test func runningExecutorCanReplaceCatalogAndSelectedPreset() throws {
    var bindings = ButtonPreset.pointer.bindings
    bindings[.volumeUp] = .action(.keyboardPageUp)
    let custom = ButtonPreset(
        id: "user.hot-reload",
        name: "热更新",
        bindings: bindings,
        requiredButtons: ButtonPreset.pointer.requiredButtons,
        isBuiltIn: false
    )
    let catalog = ButtonPresetCatalog(userPresets: [custom])
    var changedID: String?
    let executor = ButtonActionExecutor(
        preset: .pointer,
        presetChangeHandler: { changedID = $0.id }
    )

    let selected = try executor.replaceCatalog(catalog, selecting: custom.id)
    #expect(selected == custom)
    #expect(executor.preset == custom)
    #expect(changedID == custom.id)
}

@Test func buttonPresetExportImportRoundTripsAndRejectsOversizedInput() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("mi-ao-button-import-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let store = ButtonPresetStore(fileURL: root.appendingPathComponent("live.json"))
    let custom = ButtonPreset(
        id: "user.portable",
        name: "可携带配置",
        bindings: ButtonPreset.pointer.bindings,
        requiredButtons: ButtonPreset.pointer.requiredButtons,
        isBuiltIn: false
    )
    let catalog = ButtonPresetCatalog(userPresets: [custom])
    let exportURL = root.appendingPathComponent("export.json")

    try store.export(catalog, to: exportURL)
    #expect(try store.importCatalog(from: exportURL) == catalog)

    let oversizedURL = root.appendingPathComponent("oversized.json")
    try Data(repeating: 0x20, count: ButtonPresetStore.maximumImportBytes + 1)
        .write(to: oversizedURL)
    do {
        _ = try store.importCatalog(from: oversizedURL)
        Issue.record("超过 1 MB 的导入不应通过")
    } catch let error as ButtonPresetStoreError {
        guard case .importTooLarge = error else {
            Issue.record("应该返回 importTooLarge")
            return
        }
    }
}
