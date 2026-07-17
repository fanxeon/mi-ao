// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import AppKit
import CryptoKit
import Foundation
import Testing

@testable import MiAo

@Test func pasteboardRestorePolicyNeverOverwritesNewClipboardContent() {
    #expect(
        PasteboardRestorePolicy.shouldRestore(
            expectedChangeCount: 7,
            currentChangeCount: 7
        )
    )
    #expect(
        !PasteboardRestorePolicy.shouldRestore(
            expectedChangeCount: 7,
            currentChangeCount: 8
        )
    )
}

@Test func menuBarStatusCopyExplainsBackgroundAvailability() {
    #expect(MiAoRuntimeStatus.ready.label.contains("按住语音键"))
    #expect(MiAoRuntimeStatus.processing(1).label.contains("可继续说话"))
    #expect(MiAoRuntimeStatus.processing(2).label.contains("一条等待"))
    #expect(MiAoRuntimeStatus.sent.label.contains("Codex"))
}

@Test func menuBarKeepsCommandFeedbackIndependentFromVoiceReconnects() throws {
    let command = try #require(MiAoCommandActivity.executed(action: .pointerMoveLeft))

    #expect(
        MiAoMenuBarPresentation.resolved(status: .ready, activity: command)
            == command.presentation
    )
    #expect(command.presentation.icon == .systemSymbol("arrow.left"))
    #expect(command.presentation.tone == .command)
    #expect(MiAoCommandActivity.displayDuration == 1.2)

    for status in [
        MiAoRuntimeStatus.processing(1),
        .disconnected,
        .reconnecting(attempt: 2, delaySeconds: 4),
        .voiceSleeping,
        .error("测试错误"),
    ] {
        #expect(
            MiAoMenuBarPresentation.resolved(status: status, activity: command)
                == command.presentation
        )
    }

    for status in [MiAoRuntimeStatus.recording, .stopping] {
        #expect(
            MiAoMenuBarPresentation.resolved(status: status, activity: command)
                == status.menuBarPresentation
        )
    }
}

@Test func menuBarFeedbackDistinguishesPendingSuccessAndFailure() {
    let pending = MiAoCommandActivity.codexActivation(.launchRequested).presentation
    let success = MiAoCommandActivity.codexFocus(succeeded: true).presentation
    let failure = MiAoCommandActivity.codexTask(.next, succeeded: false).presentation

    #expect(pending.label == "正在启动 Codex")
    #expect(pending.tone == .command)
    #expect(success.tone == .success)
    #expect(failure.tone == .failure)
    #expect(MiAoRuntimeStatus.ready.menuBarPresentation.tone == .ready)
    #expect(MiAoRuntimeStatus.ready.menuBarPresentation.icon == .brand)
    #expect(MiAoRuntimeStatus.recording.menuBarPresentation.tone == .recording)
    #expect(MiAoRuntimeStatus.recording.menuBarPresentation.icon == .brand)
}

@Test func menuBarFeedbackUsesAvailableSystemSymbols() throws {
    let presentations = try [
        #require(MiAoCommandActivity.executed(action: .pointerMoveUp)).presentation,
        #require(MiAoCommandActivity.executed(action: .pointerScrollDown)).presentation,
        #require(MiAoCommandActivity.executed(action: .keyboardReturn)).presentation,
        #require(MiAoCommandActivity.executed(action: .keyboardEscape)).presentation,
        MiAoCommandActivity.controlMode(.pointer).presentation,
        MiAoCommandActivity.controlMode(.directional).presentation,
        MiAoCommandActivity.presetChanged(name: "测试").presentation,
        MiAoCommandActivity.codexFocus(succeeded: true).presentation,
        MiAoCommandActivity.codexTask(.previous, succeeded: true).presentation,
        MiAoCommandActivity.codexTask(.next, succeeded: false).presentation,
    ]

    for presentation in presentations {
        guard case .systemSymbol(let name) = presentation.icon else {
            Issue.record("指令反馈必须使用系统符号")
            continue
        }
        #expect(
            NSImage(
                systemSymbolName: name,
                accessibilityDescription: presentation.label
            ) != nil
        )
    }
}

@MainActor
@Test func menuBarBrandAssetIsASeventeenPointTemplateImage() throws {
    let image = try #require(
        MiAoMenuBarIconFactory.image(for: .brand, label: "米遥")
    )

    #expect(image.isTemplate)
    #expect(image.size == NSSize(width: 17, height: 17))
}

@MainActor
@Test func runtimeApplicationReopenRoutesToSettings() {
    var reopenCount = 0
    let delegate = RuntimeApplicationDelegate {
        reopenCount += 1
    }

    #expect(
        delegate.applicationShouldHandleReopen(
            NSApplication.shared,
            hasVisibleWindows: false
        )
    )
    #expect(reopenCount == 1)
}

@Test func whisperRawTranscriptIsRestrictedToCurrentUser() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("mi-ao-whisper-permissions-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let executable = root.appendingPathComponent("fake-whisper")
    let model = root.appendingPathComponent("model.bin")
    let wav = root.appendingPathComponent("voice.wav")
    let script = """
        #!/bin/zsh
        set -euo pipefail
        output=""
        while (( $# > 0 )); do
          if [[ "$1" == "-of" ]]; then
            shift
            output="$1"
          fi
          shift
        done
        print -r -- "权限测试" > "$output.txt"
        """
    try script.write(to: executable, atomically: true, encoding: .utf8)
    try Data([0]).write(to: model)
    try Data([0]).write(to: wav)
    try FileManager.default.setAttributes(
        [.posixPermissions: 0o755],
        ofItemAtPath: executable.path
    )

    var configuration = Configuration()
    configuration.whisperPath = executable.path
    configuration.modelPath = model.path
    let modelHash = SHA256.hash(data: Data([0]))
        .map { String(format: "%02x", $0) }
        .joined()
    let transcriber = try WhisperTranscriber(
        configuration: configuration,
        modelVerifier: ModelIntegrityVerifier(
            expectedSHA256: modelHash,
            minimumByteCount: 0
        )
    )
    #expect(try transcriber.transcribe(wavURL: wav) == "权限测试")

    let rawTranscript = URL(fileURLWithPath: wav.deletingPathExtension().path + ".whisper.txt")
    #expect(try permissions(of: rawTranscript) == 0o600)
}

@Test func runtimeCleanupReleasesOnlyItsOwnSessionLock() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("mi-ao-runtime-lock-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let tokenURL = root.appendingPathComponent("token")
    try "current-session\n".write(to: tokenURL, atomically: true, encoding: .utf8)

    RuntimeSessionCleanup.releaseLock(at: root, matching: "another-session")
    #expect(FileManager.default.fileExists(atPath: root.path))

    RuntimeSessionCleanup.releaseLock(at: root, matching: "current-session")
    #expect(!FileManager.default.fileExists(atPath: root.path))
}

@Test func runtimeRegistersOnlyAgainstItsOwnSessionToken() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("mi-ao-runtime-registration-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let tokenURL = root.appendingPathComponent("token")
    let pidURL = root.appendingPathComponent("pid")
    try "current-session\n".write(to: tokenURL, atomically: true, encoding: .utf8)
    try "100\n".write(to: pidURL, atomically: true, encoding: .utf8)

    #expect(
        !RuntimeSessionCleanup.registerCurrentProcess(
            processID: 4242,
            environment: [
                "MI_AO_RUNTIME_LOCK": root.path,
                "MI_AO_RUNTIME_TOKEN": "another-session",
            ]
        ))
    #expect(try String(contentsOf: pidURL, encoding: .utf8) == "100\n")

    #expect(
        RuntimeSessionCleanup.registerCurrentProcess(
            processID: 4242,
            environment: [
                "MI_AO_RUNTIME_LOCK": root.path,
                "MI_AO_RUNTIME_TOKEN": "current-session",
            ]
        ))
    #expect(try String(contentsOf: pidURL, encoding: .utf8) == "4242\n")
    #expect(try permissions(of: pidURL) == 0o600)
}

@Test func speechJobQueueWritesPrivateArtifactsAndCompletesOffTheBLEPath() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("mi-ao-speech-job-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let completed = DispatchSemaphore(value: 0)
    let callbackQueue = DispatchQueue(label: "com.fanx.miao.tests.callback")
    let received = LockedBox<Result<SpeechJobOutput, Error>?>(nil)
    let queue = SpeechJobQueue(
        callbackQueue: callbackQueue,
        transcribe: { wavURL in
            #expect(FileManager.default.fileExists(atPath: wavURL.path))
            return "米遥异步测试"
        },
        submit: { _, _, completion in completion(.success(())) }
    )

    let accepted = queue.enqueue(
        SpeechJobRequest(
            samples: Array(repeating: 1_200, count: 1_600),
            sampleRate: 16_000,
            gainDB: 0,
            outputDirectory: root.path,
            reason: "test-release",
            submitToCodex: true,
            forceSubmit: false
        )
    ) { result in
        received.set(result)
        completed.signal()
    }

    #expect(accepted)
    #expect(completed.wait(timeout: .now() + 3) == .success)
    let output = try #require(try received.get()?.get())
    #expect(output.reason == "test-release")
    #expect(output.transcript == "米遥异步测试")
    #expect(output.submitted)
    #expect(try String(contentsOf: output.transcriptURL, encoding: .utf8) == "米遥异步测试")
    #expect(try permissions(of: output.wavURL) == 0o600)
    #expect(try permissions(of: output.transcriptURL) == 0o600)
}

@Test func speechJobQueueAllowsOneWaitingJobAndRejectsTheThird() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("mi-ao-speech-capacity-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let transcribeStarted = DispatchSemaphore(value: 0)
    let releaseTranscriber = DispatchSemaphore(value: 0)
    let completed = DispatchSemaphore(value: 0)
    let queue = SpeechJobQueue(
        callbackQueue: DispatchQueue(label: "com.fanx.miao.tests.capacity-callback"),
        transcribe: { _ in
            transcribeStarted.signal()
            _ = releaseTranscriber.wait(timeout: .now() + 3)
            return "完成"
        },
        submit: { _, _, completion in completion(.success(())) }
    )
    let request = SpeechJobRequest(
        samples: Array(repeating: 400, count: 800),
        sampleRate: 16_000,
        gainDB: 0,
        outputDirectory: root.path,
        reason: "capacity-test",
        submitToCodex: false,
        forceSubmit: false
    )
    let completion: @Sendable (Result<SpeechJobOutput, Error>) -> Void = { _ in
        completed.signal()
    }

    #expect(queue.enqueue(request, completion: completion))
    #expect(transcribeStarted.wait(timeout: .now() + 2) == .success)
    #expect(queue.enqueue(request, completion: completion))
    #expect(!queue.enqueue(request, completion: completion))
    #expect(queue.pendingCount == 2)

    releaseTranscriber.signal()
    releaseTranscriber.signal()
    #expect(completed.wait(timeout: .now() + 3) == .success)
    #expect(completed.wait(timeout: .now() + 3) == .success)
}

private func permissions(of url: URL) throws -> Int {
    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
    return try #require(attributes[.posixPermissions] as? Int)
}

private final class LockedBox<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Value

    init(_ value: Value) {
        self.value = value
    }

    func set(_ value: Value) {
        lock.lock()
        self.value = value
        lock.unlock()
    }

    func get() -> Value {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}
