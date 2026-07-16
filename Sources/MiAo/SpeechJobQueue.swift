// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import Foundation

struct SpeechJobRequest: Sendable {
    let samples: [Int16]
    let sampleRate: Int
    let gainDB: Double
    let outputDirectory: String
    let reason: String
    let submitToCodex: Bool
    let forceSubmit: Bool
}

struct SpeechJobOutput: Sendable {
    let reason: String
    let wavURL: URL
    let transcriptURL: URL
    let transcript: String
    let submitted: Bool
    let submissionError: String?
}

final class SpeechJobQueue: @unchecked Sendable {
    typealias Transcribe = @Sendable (URL) throws -> String
    typealias Submit = @Sendable (String, Bool, @escaping @Sendable (Result<Void, Error>) -> Void) -> Void

    private final class SubmissionBox: @unchecked Sendable {
        private let lock = NSLock()
        private var stored: Result<Void, Error>?

        func set(_ result: Result<Void, Error>) {
            lock.lock()
            stored = result
            lock.unlock()
        }

        func get() -> Result<Void, Error>? {
            lock.lock()
            defer { lock.unlock() }
            return stored
        }
    }

    private let workQueue: DispatchQueue
    private let callbackQueue: DispatchQueue
    private let maximumPendingJobs: Int
    private let transcribe: Transcribe
    private let submit: Submit
    private let stateLock = NSLock()
    private var pendingJobs = 0

    init(
        maximumPendingJobs: Int = 2,
        workQueue: DispatchQueue = DispatchQueue(label: "com.fanx.miao.speech-processing"),
        callbackQueue: DispatchQueue = .main,
        transcribe: @escaping Transcribe,
        submit: @escaping Submit
    ) {
        self.maximumPendingJobs = max(1, maximumPendingJobs)
        self.workQueue = workQueue
        self.callbackQueue = callbackQueue
        self.transcribe = transcribe
        self.submit = submit
    }

    var pendingCount: Int {
        stateLock.lock()
        defer { stateLock.unlock() }
        return pendingJobs
    }

    @discardableResult
    func enqueue(
        _ request: SpeechJobRequest,
        completion: @escaping @Sendable (Result<SpeechJobOutput, Error>) -> Void
    ) -> Bool {
        stateLock.lock()
        guard pendingJobs < maximumPendingJobs else {
            stateLock.unlock()
            return false
        }
        pendingJobs += 1
        stateLock.unlock()

        workQueue.async {
            let result = Result { try self.process(request) }
            self.stateLock.lock()
            self.pendingJobs -= 1
            self.stateLock.unlock()
            self.callbackQueue.async {
                completion(result)
            }
        }
        return true
    }

    private func process(_ request: SpeechJobRequest) throws -> SpeechJobOutput {
        let prepared = AudioPipeline.prepareForWhisper(
            request.samples,
            sampleRate: request.sampleRate,
            gainDB: request.gainDB
        )
        let identifier = "\(Self.timestamp())-\(UUID().uuidString.prefix(8).lowercased())"
        let wavURL = URL(fileURLWithPath: request.outputDirectory)
            .appendingPathComponent("voice-\(identifier).wav")
        try AudioPipeline.writeWAV(samples: prepared, sampleRate: 16_000, to: wavURL)
        try Self.restrictPermissions(of: wavURL)

        let transcript = try transcribe(wavURL)
        let transcriptURL = wavURL.deletingPathExtension().appendingPathExtension("txt")
        try transcript.write(to: transcriptURL, atomically: true, encoding: .utf8)
        try Self.restrictPermissions(of: transcriptURL)

        guard request.submitToCodex else {
            return SpeechJobOutput(
                reason: request.reason,
                wavURL: wavURL,
                transcriptURL: transcriptURL,
                transcript: transcript,
                submitted: false,
                submissionError: nil
            )
        }

        let semaphore = DispatchSemaphore(value: 0)
        let submissionBox = SubmissionBox()
        callbackQueue.async {
            self.submit(transcript, request.forceSubmit) { result in
                submissionBox.set(result)
                semaphore.signal()
            }
        }
        let waitResult = semaphore.wait(timeout: .now() + 30)
        let submissionResult = submissionBox.get()
        let submitted: Bool
        let submissionError: String?
        if waitResult == .timedOut {
            submitted = false
            submissionError = "Codex 提交等待超过 30 秒；transcript 已保存在本机"
        } else {
            switch submissionResult {
            case .success?:
                submitted = true
                submissionError = nil
            case .failure(let error)?:
                submitted = false
                submissionError = error.localizedDescription
            case nil:
                submitted = false
                submissionError = "Codex 提交没有返回结果；transcript 已保存在本机"
            }
        }

        return SpeechJobOutput(
            reason: request.reason,
            wavURL: wavURL,
            transcriptURL: transcriptURL,
            transcript: transcript,
            submitted: submitted,
            submissionError: submissionError
        )
    }

    private static func timestamp(now: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        return formatter.string(from: now)
    }

    private static func restrictPermissions(of url: URL) throws {
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: url.path
        )
    }
}
