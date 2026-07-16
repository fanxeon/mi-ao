// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import CryptoKit
import Foundation
import Testing

@testable import MiAo

private func modelHash(_ data: Data) -> String {
    SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
}

@Test func modelIntegrityAcceptsOnlyThePinnedBytes() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("mi-ao-model-integrity-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let modelURL = root.appendingPathComponent("model.bin")
    let original = Data("known model bytes".utf8)
    try original.write(to: modelURL)
    let verifier = ModelIntegrityVerifier(
        expectedSHA256: modelHash(original),
        minimumByteCount: 0
    )

    #expect(
        verifier.verify(modelPath: modelURL.path)
            == .valid(byteCount: Int64(original.count))
    )

    let tampered = Data("known model byteZ".utf8)
    #expect(tampered.count == original.count)
    try tampered.write(to: modelURL)
    guard case .hashMismatch = verifier.verify(modelPath: modelURL.path) else {
        Issue.record("同尺寸篡改的模型必须被拒绝")
        return
    }
}

@Test func modelIntegrityReportsMissingSmallAndMissingContract() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("mi-ao-model-states-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let modelURL = root.appendingPathComponent("model.bin")
    let verifier = ModelIntegrityVerifier(
        expectedSHA256: String(repeating: "0", count: 64),
        minimumByteCount: 10
    )

    #expect(verifier.verify(modelPath: modelURL.path) == .missing)
    try Data([0, 1, 2]).write(to: modelURL)
    #expect(verifier.verify(modelPath: modelURL.path) == .tooSmall(byteCount: 3))
    #expect(
        ModelIntegrityVerifier(expectedSHA256: nil, minimumByteCount: 0)
            .verify(modelPath: modelURL.path) == .contractMissing
    )
}

@Test func transcriberRejectsTamperedModelBeforeLaunchingWhisper() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("mi-ao-model-runtime-gate-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let executable = root.appendingPathComponent("fake-whisper")
    let marker = root.appendingPathComponent("launched")
    let modelURL = root.appendingPathComponent("model.bin")
    try "#!/bin/zsh\ntouch \"(marker.path)\"\n".write(
        to: executable,
        atomically: true,
        encoding: .utf8
    )
    try FileManager.default.setAttributes(
        [.posixPermissions: 0o755],
        ofItemAtPath: executable.path
    )
    try Data("tampered".utf8).write(to: modelURL)

    var configuration = Configuration()
    configuration.whisperPath = executable.path
    configuration.modelPath = modelURL.path
    do {
        _ = try WhisperTranscriber(
            configuration: configuration,
            modelVerifier: ModelIntegrityVerifier(
                expectedSHA256: modelHash(Data("expected".utf8)),
                minimumByteCount: 0
            )
        )
        Issue.record("篡改模型不应创建转写器")
    } catch let error as BridgeError {
        #expect(error.localizedDescription.contains("完整性校验失败"))
    }
    #expect(!FileManager.default.fileExists(atPath: marker.path))
}
