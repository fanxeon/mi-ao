// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import Foundation

struct WhisperTranscriber {
    static let defaultChinesePrompt = "米遥。Codex。项目。代码。测试。发送。"

    let executableURL: URL
    let modelURL: URL
    let language: String
    let prompt: String?

    init(
        configuration: Configuration,
        modelVerifier: ModelIntegrityVerifier = .production()
    ) throws {
        switch modelVerifier.verify(modelPath: configuration.modelPath) {
        case .valid:
            break
        case .missing:
            throw BridgeError.transcription(
                "Whisper 模型不存在：\(configuration.modelPath)\n请在米遥设置中执行“修复安装”"
            )
        case .tooSmall:
            throw BridgeError.transcription(
                "Whisper 模型不完整：\(configuration.modelPath)\n请在米遥设置中执行“修复安装”"
            )
        case .hashMismatch:
            throw BridgeError.transcription(
                "Whisper 模型完整性校验失败：\(configuration.modelPath)\n已拒绝启动，请执行“修复安装”"
            )
        case .contractMissing:
            throw BridgeError.transcription(
                "当前米遥安装缺少语音模型校验契约，已拒绝启动；请重新安装米遥"
            )
        case .unreadable:
            throw BridgeError.transcription(
                "Whisper 模型无法读取：\(configuration.modelPath)\n请检查权限或执行“修复安装”"
            )
        }
        modelURL = URL(fileURLWithPath: configuration.modelPath)
        language = configuration.language
        prompt =
            configuration.whisperPrompt
            ?? (configuration.language.lowercased().hasPrefix("zh") ? Self.defaultChinesePrompt : nil)

        if let explicit = configuration.whisperPath {
            guard FileManager.default.isExecutableFile(atPath: explicit) else {
                throw BridgeError.transcription("whisper-cli 不可执行：\(explicit)")
            }
            executableURL = URL(fileURLWithPath: explicit)
            return
        }

        let candidates = [
            "/opt/homebrew/bin/whisper-cli",
            "/usr/local/bin/whisper-cli",
        ]
        guard let path = candidates.first(where: FileManager.default.isExecutableFile(atPath:)) else {
            throw BridgeError.transcription("找不到 whisper-cli，请先运行 scripts/setup.sh")
        }
        executableURL = URL(fileURLWithPath: path)
    }

    func transcribe(wavURL: URL) throws -> String {
        let outputBase = wavURL.deletingPathExtension().appendingPathExtension("whisper")
        let outputTextURL = URL(fileURLWithPath: outputBase.path + ".txt")
        try? FileManager.default.removeItem(at: outputTextURL)

        let process = Process()
        process.executableURL = executableURL
        var arguments = [
            "-m", modelURL.path,
            "-f", wavURL.path,
            "-l", language,
            "-otxt",
            "-of", outputBase.path,
            "-np",
        ]
        if let prompt, !prompt.isEmpty {
            arguments.append(contentsOf: ["--prompt", prompt])
        }
        process.arguments = arguments
        let errorPipe = Pipe()
        process.standardOutput = Pipe()
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        if FileManager.default.fileExists(atPath: outputTextURL.path) {
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o600],
                ofItemAtPath: outputTextURL.path
            )
        }
        guard process.terminationStatus == 0 else {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let error = String(data: errorData, encoding: .utf8) ?? "unknown whisper error"
            throw BridgeError.transcription("Whisper 转写失败：\(error.trimmingCharacters(in: .whitespacesAndNewlines))")
        }

        guard let transcript = try? String(contentsOf: outputTextURL, encoding: .utf8) else {
            throw BridgeError.transcription("Whisper 没有生成 transcript：\(outputTextURL.path)")
        }
        return transcript.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
