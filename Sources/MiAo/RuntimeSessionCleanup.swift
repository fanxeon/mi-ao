// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import Foundation

enum RuntimeSessionCleanup {
    private static let restoreScriptKey = "MI_AO_MAPPING_RESTORE_SCRIPT"
    private static let runtimeLockKey = "MI_AO_RUNTIME_LOCK"
    private static let runtimeTokenKey = "MI_AO_RUNTIME_TOKEN"

    static func perform(environment: [String: String] = ProcessInfo.processInfo.environment) {
        if let restoreScript = environment[restoreScriptKey],
            FileManager.default.isExecutableFile(atPath: restoreScript)
        {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: restoreScript)
            process.arguments = ["restore"]
            do {
                try process.run()
                process.waitUntilExit()
                if process.terminationStatus != 0 {
                    fputs("警告：退出时恢复遥控器映射失败，请运行 scripts/stop.sh\n", stderr)
                }
            } catch {
                fputs("警告：无法执行遥控器恢复脚本：\(error.localizedDescription)\n", stderr)
            }
        }

        guard
            let lockPath = environment[runtimeLockKey],
            let token = environment[runtimeTokenKey]
        else { return }
        releaseLock(at: URL(fileURLWithPath: lockPath), matching: token)
    }

    static func releaseLock(at lockURL: URL, matching expectedToken: String) {
        let tokenURL = lockURL.appendingPathComponent("token")
        guard
            let storedToken = try? String(contentsOf: tokenURL, encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines),
            storedToken == expectedToken
        else { return }
        try? FileManager.default.removeItem(at: lockURL)
    }
}
