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
