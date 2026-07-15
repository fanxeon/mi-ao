// Copyright (c) 2026 FanXeon@Poemcoder with Codex
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
    let transcriber = try WhisperTranscriber(configuration: configuration)
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

@Test func speechJobQueueWritesPrivateArtifactsAndCompletesOffTheBLEPath() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("mi-ao-speech-job-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let completed = DispatchSemaphore(value: 0)
    let callbackQueue = DispatchQueue(label: "com.fanx.miao.tests.callback")
    var received: Result<SpeechJobOutput, Error>?
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
        received = result
        completed.signal()
    }

    #expect(accepted)
    #expect(completed.wait(timeout: .now() + 3) == .success)
    let output = try #require(try received?.get())
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
    let completion: (Result<SpeechJobOutput, Error>) -> Void = { _ in completed.signal() }

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
