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
    let executor = ButtonActionExecutor(
        preset: try loaded.catalog.preset(id: "user.writing"),
        catalog: loaded.catalog,
        presetChangeHandler: { preset in switchedID = preset.id }
    )
    executor.buttonDown(.tv)
    #expect(executor.preset.id == "user.review")
    #expect(switchedID == "user.review")
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
