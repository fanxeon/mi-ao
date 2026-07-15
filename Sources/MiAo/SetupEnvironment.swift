// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import AppKit
import ApplicationServices
@preconcurrency import CoreBluetooth
import Darwin
import Foundation

enum SetupCheckID: String, CaseIterable {
    case system
    case speechEngine
    case accessibility
    case bluetooth
    case codex
    case source
}

enum SetupCheckState: Equatable {
    case ready
    case actionRequired
    case blocked
}

enum SetupCheckAction: Equatable {
    case requestAccessibility
    case requestBluetooth
    case openBluetoothSettings
    case openBluetoothPrivacy
    case prepareCodex
    case runSetup
    case revealSource
}

struct SetupCheck: Equatable {
    let id: SetupCheckID
    let title: String
    let detail: String
    let state: SetupCheckState
    let action: SetupCheckAction?
    let actionTitle: String?
}

struct SetupEnvironmentReport: Equatable {
    let checks: [SetupCheck]
    let runtimeActive: Bool

    var canStart: Bool {
        !runtimeActive && checks.allSatisfy { $0.state == .ready }
    }

    func check(_ id: SetupCheckID) -> SetupCheck? {
        checks.first { $0.id == id }
    }
}

struct MiAoInstallationContext: Codable, Equatable {
    let repositoryRoot: String
    let version: String
    let installedAt: String

    var repositoryURL: URL { URL(fileURLWithPath: repositoryRoot, isDirectory: true) }

    var startScriptURL: URL {
        repositoryURL.appendingPathComponent("scripts/start.sh")
    }

    var setupScriptURL: URL {
        repositoryURL.appendingPathComponent("scripts/setup.sh")
    }

    var codexAccessibilityScriptURL: URL {
        repositoryURL.appendingPathComponent("scripts/codex-accessibility.sh")
    }

    var isValid: Bool {
        FileManager.default.isExecutableFile(atPath: startScriptURL.path)
            && FileManager.default.isExecutableFile(atPath: setupScriptURL.path)
            && FileManager.default.isExecutableFile(atPath: codexAccessibilityScriptURL.path)
    }

    static var fileURL: URL {
        let environment = ProcessInfo.processInfo.environment
        let dataDirectory: String
        if let override = environment["VOICE_BRIDGE_DATA_DIR"], !override.isEmpty {
            dataDirectory = NSString(string: override).expandingTildeInPath
        } else {
            dataDirectory =
                NSString(
                    string: "~/Library/Application Support/mi-ao"
                ).expandingTildeInPath
        }
        return URL(fileURLWithPath: dataDirectory, isDirectory: true)
            .appendingPathComponent("install-context.plist")
    }

    static func load() -> MiAoInstallationContext? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? PropertyListDecoder().decode(MiAoInstallationContext.self, from: data)
    }
}

struct CodexRuntimeSnapshot: Equatable {
    let isInstalled: Bool
    let isRunning: Bool
    let compatibilityEnabled: Bool
}

struct SetupEnvironmentInspector {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func inspect(configuration: Configuration) -> SetupEnvironmentReport {
        SetupEnvironmentReport(
            checks: [
                systemCheck(),
                speechEngineCheck(configuration: configuration),
                accessibilityCheck(),
                bluetoothCheck(),
                codexCheck(),
                sourceCheck(),
            ],
            runtimeActive: isRuntimeActive
        )
    }

    func codexSnapshot() -> CodexRuntimeSnapshot {
        let installed =
            NSWorkspace.shared.urlForApplication(
                withBundleIdentifier: "com.openai.codex"
            ) != nil
        guard
            let application = NSRunningApplication.runningApplications(
                withBundleIdentifier: "com.openai.codex"
            ).first
        else {
            return CodexRuntimeSnapshot(
                isInstalled: installed,
                isRunning: false,
                compatibilityEnabled: false
            )
        }

        let process = Process()
        let output = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-p", String(application.processIdentifier), "-ww", "-o", "command="]
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            let data = output.fileHandleForReading.readDataToEndOfFile()
            let command = String(data: data, encoding: .utf8) ?? ""
            return CodexRuntimeSnapshot(
                isInstalled: installed,
                isRunning: true,
                compatibilityEnabled: command.contains(CodexSubmitter.accessibilityLaunchArgument)
            )
        } catch {
            return CodexRuntimeSnapshot(
                isInstalled: installed,
                isRunning: true,
                compatibilityEnabled: false
            )
        }
    }

    private func systemCheck() -> SetupCheck {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let supported = version.majorVersion >= 14
        return SetupCheck(
            id: .system,
            title: "macOS 版本",
            detail: supported
                ? "macOS \(version.majorVersion).\(version.minorVersion) · 满足 macOS 14+"
                : "需要 macOS 14 或更高版本",
            state: supported ? .ready : .blocked,
            action: nil,
            actionTitle: nil
        )
    }

    private func speechEngineCheck(configuration: Configuration) -> SetupCheck {
        let whisperPath = resolvedWhisperPath(explicit: configuration.whisperPath)
        let modelSize =
            (try? fileManager.attributesOfItem(atPath: configuration.modelPath)[.size])
            as? NSNumber
        let modelReady = (modelSize?.int64Value ?? 0) > 1_000_000
        if whisperPath != nil, modelReady {
            let formattedSize = ByteCountFormatter.string(
                fromByteCount: modelSize?.int64Value ?? 0,
                countStyle: .file
            )
            return SetupCheck(
                id: .speechEngine,
                title: "本地语音引擎",
                detail: "whisper-cli 与 \(formattedSize) 模型已就绪",
                state: .ready,
                action: nil,
                actionTitle: nil
            )
        }
        let missing = [
            whisperPath == nil ? "whisper-cli" : nil,
            modelReady ? nil : "语音模型",
        ].compactMap { $0 }.joined(separator: "、")
        return SetupCheck(
            id: .speechEngine,
            title: "本地语音引擎",
            detail: "缺少\(missing)，需要完成安装",
            state: .actionRequired,
            action: .runSetup,
            actionTitle: "修复安装"
        )
    }

    private func accessibilityCheck() -> SetupCheck {
        let trusted = AXIsProcessTrusted()
        return SetupCheck(
            id: .accessibility,
            title: "米遥辅助功能",
            detail: trusted ? "已允许控制 Codex 与执行遥控器动作" : "需要你在系统设置中明确允许“米遥”",
            state: trusted ? .ready : .actionRequired,
            action: trusted ? nil : .requestAccessibility,
            actionTitle: trusted ? nil : "请求权限"
        )
    }

    private func bluetoothCheck() -> SetupCheck {
        switch CBManager.authorization {
        case .allowedAlways:
            return SetupCheck(
                id: .bluetooth,
                title: "蓝牙权限",
                detail: "已允许连接和读取语音遥控器",
                state: .ready,
                action: .openBluetoothSettings,
                actionTitle: "配对遥控器"
            )
        case .notDetermined:
            return SetupCheck(
                id: .bluetooth,
                title: "蓝牙权限",
                detail: "尚未请求；点击后由 macOS 显示系统授权框",
                state: .actionRequired,
                action: .requestBluetooth,
                actionTitle: "请求权限"
            )
        case .denied:
            return SetupCheck(
                id: .bluetooth,
                title: "蓝牙权限",
                detail: "已被拒绝，请在系统设置中允许“米遥”",
                state: .blocked,
                action: .openBluetoothPrivacy,
                actionTitle: "打开设置"
            )
        case .restricted:
            return SetupCheck(
                id: .bluetooth,
                title: "蓝牙权限",
                detail: "当前系统策略限制了蓝牙访问",
                state: .blocked,
                action: .openBluetoothPrivacy,
                actionTitle: "查看设置"
            )
        @unknown default:
            return SetupCheck(
                id: .bluetooth,
                title: "蓝牙权限",
                detail: "无法读取当前授权状态",
                state: .blocked,
                action: .openBluetoothPrivacy,
                actionTitle: "打开设置"
            )
        }
    }

    private func codexCheck() -> SetupCheck {
        let snapshot = codexSnapshot()
        guard snapshot.isInstalled else {
            return SetupCheck(
                id: .codex,
                title: "Codex",
                detail: "没有找到 Codex App，请先安装并登录",
                state: .blocked,
                action: nil,
                actionTitle: nil
            )
        }
        if !snapshot.isRunning {
            return SetupCheck(
                id: .codex,
                title: "Codex 输入区",
                detail: "Codex 已安装；启动米遥时会带本次进程兼容参数打开",
                state: .ready,
                action: nil,
                actionTitle: nil
            )
        }
        if snapshot.compatibilityEnabled {
            return SetupCheck(
                id: .codex,
                title: "Codex 输入区",
                detail: "当前 Codex 进程已开启辅助功能兼容",
                state: .ready,
                action: nil,
                actionTitle: nil
            )
        }
        return SetupCheck(
            id: .codex,
            title: "Codex 输入区",
            detail: "Codex 正在工作；需要在空闲时由你确认重启一次",
            state: .actionRequired,
            action: .prepareCodex,
            actionTitle: "准备 Codex"
        )
    }

    private func sourceCheck() -> SetupCheck {
        guard let context = MiAoInstallationContext.load(), context.isValid else {
            return SetupCheck(
                id: .source,
                title: "安装来源",
                detail: "找不到本地项目脚本，请从项目目录重新运行 setup.sh",
                state: .blocked,
                action: nil,
                actionTitle: nil
            )
        }
        return SetupCheck(
            id: .source,
            title: "启动组件",
            detail: "米遥 \(context.version) · 安全门禁与恢复脚本可用",
            state: .ready,
            action: .revealSource,
            actionTitle: "查看目录"
        )
    }

    private func resolvedWhisperPath(explicit: String?) -> String? {
        let candidates = [
            explicit,
            "/opt/homebrew/bin/whisper-cli",
            "/usr/local/bin/whisper-cli",
        ].compactMap { $0 }
        return candidates.first { fileManager.isExecutableFile(atPath: $0) }
    }

    private var isRuntimeActive: Bool {
        let lockURL = MiAoInstallationContext.fileURL.deletingLastPathComponent()
            .appendingPathComponent("runtime.lock/pid")
        guard
            let value = try? String(contentsOf: lockURL, encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines),
            let pid = Int32(value),
            pid > 0
        else { return false }
        return kill(pid, 0) == 0
    }
}
