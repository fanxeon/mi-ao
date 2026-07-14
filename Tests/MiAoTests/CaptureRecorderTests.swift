// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import Foundation
import Testing

@testable import MiAo

@Test func parsesCustomWhisperPrompt() throws {
    let configuration = try Configuration.parse([
        "mi-ao",
        "run",
        "--prompt",
        "这是自定义词汇。",
        "--no-submit",
    ])

    #expect(configuration.whisperPrompt == "这是自定义词汇。")
    #expect(configuration.submitToCodex == false)
}

@Test func parsesCaptureConfiguration() throws {
    let configuration = try Configuration.parse([
        "mi-ao",
        "capture",
        "--identifier",
        "11111111-2222-3333-4444-555555555555",
        "--scan-seconds",
        "12",
        "--capture-seconds",
        "34",
        "--capture-dir",
        "~/mi-ao-capture-test",
        "--include-identifiers",
        "--include-device-names",
        "--debug",
    ])

    #expect(configuration.mode == .capture)
    #expect(configuration.peripheralIdentifier?.uuidString == "11111111-2222-3333-4444-555555555555")
    #expect(configuration.scanSeconds == 12)
    #expect(configuration.captureSeconds == 34)
    #expect(configuration.captureDirectory.hasSuffix("/mi-ao-capture-test"))
    #expect(configuration.includeIdentifiers)
    #expect(configuration.includeDeviceNames)
    #expect(configuration.debug)
}

@Test func captureReportRedactsIdentityAndRetainsProtocolEvidence() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let identifier = try #require(UUID(uuidString: "11111111-2222-3333-4444-555555555555"))
    let startedAt = Date(timeIntervalSince1970: 1_700_000_000)
    let recorder = try CaptureRecorder(
        directory: root.path,
        includeIdentifiers: false,
        includeDeviceNames: false,
        sessionID: try #require(UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")),
        startedAt: startedAt,
        appVersion: "test"
    )

    recorder.recordDiscovery(
        identifier: identifier,
        name: "Fan's Remote",
        rssi: -42,
        advertisedServices: [ATVVProtocol.serviceUUID],
        at: startedAt
    )
    recorder.setTarget(identifier: identifier, name: "Fan's Remote", at: startedAt)
    recorder.recordConnection(identifier: identifier, connected: true)
    recorder.recordService(ATVVProtocol.serviceUUID, isPrimary: true)
    recorder.recordCharacteristic(
        serviceUUID: ATVVProtocol.serviceUUID,
        uuid: ATVVProtocol.controlUUID,
        properties: ["notify", "read"],
        rawProperties: 18
    )
    recorder.recordValue(
        characteristicUUID: ATVVProtocol.controlUUID,
        data: Data([0x0B, 0x01, 0x00]),
        detail: "notification"
    )
    recorder.recordDescriptor(
        serviceUUID: ATVVProtocol.serviceUUID,
        characteristicUUID: ATVVProtocol.controlUUID,
        uuid: "2902"
    )
    let report = try recorder.finish(reason: "test", at: startedAt.addingTimeInterval(5))

    #expect(report.target?.id.hasPrefix("device-") == true)
    #expect(report.target?.id.contains(identifier.uuidString.lowercased()) == false)
    #expect(report.target?.name == "(redacted)")
    #expect(report.summary.discoveredDevices == 1)
    #expect(report.summary.connected)
    #expect(report.summary.services == 1)
    #expect(report.summary.characteristics == 1)
    #expect(report.summary.descriptors == 1)
    #expect(report.summary.values == 1)
    #expect(report.summary.payloadBytes == 3)
    #expect(report.summary.atvvDetected)
    #expect(report.services.first?.isPrimary == true)
    #expect(report.services.first?.characteristics.first?.descriptors == ["2902"])
    #expect(report.privacy.identifiers == "sha256-prefix")

    let reportData = try Data(contentsOf: recorder.reportURL)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let decoded = try decoder.decode(CaptureReport.self, from: reportData)
    #expect(decoded == report)

    let events = try String(contentsOf: recorder.eventsURL, encoding: .utf8)
    #expect(events.contains("0b 01 00"))
    #expect(events.contains(identifier.uuidString.lowercased()) == false)
    #expect(events.contains("Fan's Remote") == false)
}

@Test func captureCanExplicitlyIncludeLocalIdentity() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let identifier = UUID()
    let recorder = try CaptureRecorder(
        directory: root.path,
        includeIdentifiers: true,
        includeDeviceNames: true
    )

    recorder.recordDiscovery(
        identifier: identifier,
        name: "Xiaomi Remote",
        rssi: -50,
        advertisedServices: []
    )
    recorder.setTarget(identifier: identifier, name: "Xiaomi Remote")
    let report = try recorder.finish(reason: "test")

    #expect(report.target?.id == identifier.uuidString.lowercased())
    #expect(report.target?.name == "Xiaomi Remote")
    #expect(report.privacy.identifiers == "included")
    #expect(report.privacy.deviceNames == "included")
}

@Test func parsesButtonLearnerConfiguration() throws {
    let configuration = try Configuration.parse([
        "mi-ao",
        "learn-buttons",
        "--name",
        "小米蓝牙语音遥控器",
        "--vendor-id",
        "0x2717",
        "--product-id",
        "12984",
        "--button-seconds",
        "12",
        "--button",
        "back",
        "--profile-dir",
        "~/mi-ao-button-test",
    ])

    #expect(configuration.mode == .learnButtons)
    #expect(configuration.hidVendorID == 0x2717)
    #expect(configuration.hidProductID == 0x32B8)
    #expect(configuration.buttonSeconds == 12)
    #expect(configuration.buttonID == "back")
    #expect(configuration.buttonProfileDirectory.hasSuffix("/mi-ao-button-test"))
}

@Test func writesRedactedButtonProfile() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let profile = ButtonProfile(
        schemaVersion: 4,
        captureMode: "confirmed_calibration",
        generatedAt: now,
        device: .init(vendorID: 0x2717, productID: 0x32B8, productName: "Xiaomi Remote"),
        privacy: "No identifiers stored.",
        observations: [
            .init(
                button: "dpad_up",
                label: "方向上",
                expectedTransport: "hid",
                status: .observed,
                usagePage: 0x07,
                usage: 0x52,
                elementUsage: Int(UInt32.max),
                rawValues: [1, 0],
                pressObserved: true,
                releaseObserved: true,
                repeatCount: 0,
                note: nil
            )
        ]
    )

    let url = try ButtonProfileWriter.write(profile, to: root.path, now: now)
    let data = try Data(contentsOf: url)
    let text = try #require(String(data: data, encoding: .utf8))
    #expect(text.contains("Xiaomi Remote"))
    #expect(text.contains("11111111-2222-3333-4444-555555555555") == false)

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    #expect(try decoder.decode(ButtonProfile.self, from: data) == profile)
}

@Test func pointerPresetMapsPhysicalButtonsToActions() throws {
    let preset = try ButtonPreset.named("pointer")
    #expect(preset.id == "pointer")
    #expect(preset.action(for: .dpadUp) == .pointerMoveUp)
    #expect(preset.action(for: .center) == .pointerLeftClick)
    #expect(preset.action(for: .back) == .pointerRightClick)
    #expect(preset.action(for: .volumeDown) == .pointerScrollDown)
    #expect(preset.action(for: .tv) == .modeTogglePointerDirectional)
    #expect(preset.action(for: .power) == .codexLaunchOrFocus)
}

@Test func parsesButtonDebugModeAndCalibrationDecisions() throws {
    let configuration = try Configuration.parse([
        "mi-ao", "debug-buttons", "--button", "back",
    ])
    #expect(configuration.mode == .debugButtons)
    #expect(configuration.buttonID == "back")
    #expect(ButtonCalibrationDecision.parse("") == .confirm)
    #expect(ButtonCalibrationDecision.parse("y") == .confirm)
    #expect(ButtonCalibrationDecision.parse("retry") == .retry)
    #expect(ButtonCalibrationDecision.parse("s") == .skip)
    #expect(ButtonCalibrationDecision.parse("q") == .quit)
    #expect(ButtonCalibrationDecision.parse("no") == .invalid)
}

@Test func parsesPointerRuntimeConfiguration() throws {
    let configuration = try Configuration.parse([
        "mi-ao", "run", "--preset", "pointer", "--button-profile", "~/confirmed.json",
        "--no-buttons",
    ])
    #expect(configuration.buttonPresetID == "pointer")
    #expect(configuration.buttonProfilePath?.hasSuffix("/confirmed.json") == true)
    #expect(configuration.buttonsEnabled == false)
}

@Test func mergesConfirmedCalibrationForRequiredPointerButtons() throws {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let required: [(RemoteButton, Int)] = [
        (.dpadUp, 0x52), (.dpadDown, 0x51), (.dpadLeft, 0x50),
        (.dpadRight, 0x4F), (.center, 0x28), (.back, 0xF1),
    ]
    let observations = required.map { button, usage in
        ButtonProfile.Observation(
            button: button.rawValue,
            label: button.rawValue,
            expectedTransport: "hid",
            status: .observed,
            usagePage: 0x07,
            usage: usage,
            elementUsage: Int(UInt32.max),
            rawValues: [usage, 0],
            pressObserved: true,
            releaseObserved: true,
            repeatCount: 0,
            note: nil
        )
    }
    let profile = ButtonProfile(
        schemaVersion: 4,
        captureMode: "confirmed_calibration",
        generatedAt: now,
        device: .init(vendorID: 0x2717, productID: 0x32B8, productName: "Xiaomi Remote"),
        privacy: "redacted",
        observations: observations
    )
    let url = URL(fileURLWithPath: "/tmp/confirmed.json")
    let builtMap = try ButtonProfileStore.buildMap(from: [(profile, url)], preset: .pointer)
    let map = try #require(builtMap)

    #expect(map.buttonsByUsage[HIDUsageKey(page: 0x07, usage: 0x52)] == .dpadUp)
    #expect(map.usagesByButton[.back] == HIDUsageKey(page: 0x07, usage: 0xF1))
    #expect(map.sourceFiles == [url])
    #expect(ButtonActionExecutor.pointerSpeed(heldSeconds: 0) == 260)
    #expect(ButtonActionExecutor.pointerSpeed(heldSeconds: 2) == 1_000)
}

@Test func directionalModeResolvesDpadCenterAndBackToKeyboard() {
    let executor = ButtonActionExecutor(preset: .pointer)
    #expect(executor.controlMode == .pointer)
    executor.buttonDown(.tv)
    #expect(executor.controlMode == .directional)
    executor.buttonDown(.tv)
    #expect(executor.controlMode == .pointer)

    #expect(
        ButtonActionExecutor.resolvedAction(
            .pointerMoveUp,
            mode: .directional
        ) == .keyboardArrowUp
    )
    #expect(
        ButtonActionExecutor.resolvedAction(
            .pointerLeftClick,
            mode: .directional
        ) == .keyboardReturn
    )
    #expect(
        ButtonActionExecutor.resolvedAction(
            .pointerRightClick,
            mode: .directional
        ) == .keyboardEscape
    )
    #expect(
        ButtonActionExecutor.resolvedAction(
            .pointerMoveUp,
            mode: .pointer
        ) == .pointerMoveUp
    )
}

@Test func newestCalibrationResultCanInvalidateAnOlderButton() throws {
    let first = makePointerProfile(generatedAt: Date(timeIntervalSince1970: 100))
    let invalidated = ButtonProfile(
        schemaVersion: 4,
        captureMode: "confirmed_calibration",
        generatedAt: Date(timeIntervalSince1970: 200),
        device: first.device,
        privacy: "redacted",
        observations: [
            .init(
                button: RemoteButton.dpadUp.rawValue,
                label: "dpad_up",
                expectedTransport: "hid",
                status: .notObserved,
                usagePage: nil,
                usage: nil,
                elementUsage: nil,
                rawValues: [],
                pressObserved: false,
                releaseObserved: false,
                repeatCount: 0,
                note: "retry required"
            )
        ]
    )

    let map = try ButtonProfileStore.buildMap(
        from: [
            (first, URL(fileURLWithPath: "/tmp/first.json")),
            (invalidated, URL(fileURLWithPath: "/tmp/latest.json")),
        ],
        preset: .pointer
    )
    #expect(map == nil)
}

@Test func rejectsDuplicateUsageAcrossPhysicalButtons() {
    let profile = makePointerProfile(
        generatedAt: Date(timeIntervalSince1970: 100),
        backUsage: 0x28
    )
    var rejected = false
    do {
        _ = try ButtonProfileStore.buildMap(
            from: [(profile, URL(fileURLWithPath: "/tmp/conflict.json"))],
            preset: .pointer
        )
    } catch {
        rejected = true
    }
    #expect(rejected)
}

@Test func suppressesOnlyMatchingFreshRemoteEventTokens() {
    let suppressor = RemoteEventSuppressor()
    suppressor.record(isDown: true, at: 10)
    #expect(suppressor.consume(isDown: false, now: 10.01) == false)
    #expect(suppressor.consume(isDown: true, now: 10.01))
    #expect(suppressor.consume(isDown: true, now: 10.02) == false)
    suppressor.record(isDown: false, at: 20)
    #expect(suppressor.consume(isDown: false, now: 20.2) == false)
    suppressor.record(isDown: true, at: 30)
    #expect(suppressor.consumeAny(now: 30.01))
    #expect(suppressor.consumeAny(now: 30.02) == false)
}

@Test func resolvesUsageFromKeyboardArrayReport() {
    #expect(
        ButtonLearner.normalizedUsage(
            elementUsage: Int(UInt32.max),
            rawValues: [62, 4_063_232, 0]
        ) == 62
    )
    #expect(ButtonLearner.normalizedUsage(elementUsage: 0x52, rawValues: [1, 0]) == 0x52)
    #expect(ButtonLearner.isRepeat(elapsed: 0.05) == false)
    #expect(ButtonLearner.isRepeat(elapsed: 0.35))
}

private func makePointerProfile(generatedAt: Date, backUsage: Int = 0xF1) -> ButtonProfile {
    let usages: [(RemoteButton, Int)] = [
        (.dpadUp, 0x52), (.dpadDown, 0x51), (.dpadLeft, 0x50),
        (.dpadRight, 0x4F), (.center, 0x28), (.back, backUsage),
    ]
    return ButtonProfile(
        schemaVersion: 4,
        captureMode: "confirmed_calibration",
        generatedAt: generatedAt,
        device: .init(vendorID: 0x2717, productID: 0x32B8, productName: "Xiaomi Remote"),
        privacy: "redacted",
        observations: usages.map { button, usage in
            .init(
                button: button.rawValue,
                label: button.rawValue,
                expectedTransport: "hid",
                status: .observed,
                usagePage: 0x07,
                usage: usage,
                elementUsage: usage,
                rawValues: [1, 0],
                pressObserved: true,
                releaseObserved: true,
                repeatCount: 0,
                note: nil
            )
        }
    )
}
