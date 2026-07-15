// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import Foundation

struct AppRuntimeLauncher {
    func start(preferences: AppPreferences) throws -> String {
        guard let context = MiAoInstallationContext.load(), context.isValid else {
            throw BridgeError.configuration("App 内置启动组件缺失或损坏，请打开设置向导修复")
        }

        let process = Process()
        let output = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = [context.startScriptURL.path] + preferences.runtimeArguments
        process.currentDirectoryURL =
            context.startScriptURL.deletingLastPathComponent().deletingLastPathComponent()
        var environment = ProcessInfo.processInfo.environment
        environment["MI_AO_APP_BUNDLE"] = Bundle.main.bundleURL.path
        process.environment = environment
        process.standardOutput = output
        process.standardError = output
        try process.run()
        process.waitUntilExit()

        let message =
            String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard process.terminationStatus == 0 else {
            throw BridgeError.configuration(
                message.isEmpty ? "启动脚本退出码：\(process.terminationStatus)" : message
            )
        }
        return message
    }
}
