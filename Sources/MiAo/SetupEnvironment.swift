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

enum SetupRequirement: Equatable {
    case required
    case featureRequired
    case optional

    var title: String {
        switch self {
        case .required: return "必须"
        case .featureRequired: return "当前功能必需"
        case .optional: return "可选"
        }
    }

    var blocksStart: Bool {
        self != .optional
    }
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
    let requirement: SetupRequirement

    init(
        id: SetupCheckID,
        title: String,
        detail: String,
        state: SetupCheckState,
        action: SetupCheckAction?,
        actionTitle: String?,
        requirement: SetupRequirement = .required
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.state = state
        self.action = action
        self.actionTitle = actionTitle
        self.requirement = requirement
    }
}

struct SetupEnvironmentReport: Equatable {
    let checks: [SetupCheck]
    let runtimeActive: Bool

    var canStart: Bool {
        !runtimeActive
            && checks.allSatisfy { !$0.requirement.blocksStart || $0.state == .ready }
    }

    func check(_ id: SetupCheckID) -> SetupCheck? {
        checks.first { $0.id == id }
    }
}

struct MiAoInstallationContext: Codable, Equatable {
    let repositoryRoot: String?
    let runtimeRoot: String?
    let version: String
    let installedAt: String
    let codeHash: String?

    private static var bundledRuntimeURL: URL? {
        guard let resources = Bundle.main.resourceURL else { return nil }
        let candidate = resources.appendingPathComponent("Runtime", isDirectory: true)
        return runtimeIsValid(candidate) ? candidate : nil
    }

    private static func runtimeIsValid(_ root: URL) -> Bool {
        let requiredPaths = [
            "VERSION",
            "Resources/Info.plist",
            "Resources/HardwareProfiles/xiaomi-remote-2-pro-2671.plist",
            "scripts/start.sh",
            "scripts/stop.sh",
            "scripts/run.sh",
            "scripts/run-with-mapping.sh",
            "scripts/check-buttons.sh",
            "scripts/remote-mapping.sh",
            "scripts/codex-accessibility.sh",
            "scripts/lib/project.sh",
            "scripts/lib/environment.sh",
            "Resources/WhisperModel.sha256",
        ]
        let baseIsValid = requiredPaths.allSatisfy {
            FileManager.default.fileExists(atPath: root.appendingPathComponent($0).path)
        }
        let hasRepair = FileManager.default.fileExists(
            atPath: root.appendingPathComponent("scripts/repair-runtime.sh").path
        )
        let hasLegacySetup = FileManager.default.fileExists(
            atPath: root.appendingPathComponent("scripts/setup.sh").path
        )
        return baseIsValid && (hasRepair || hasLegacySetup)
    }

    var runtimeURL: URL {
        if let bundled = Self.bundledRuntimeURL { return bundled }
        if let runtimeRoot, !runtimeRoot.isEmpty {
            return URL(fileURLWithPath: runtimeRoot, isDirectory: true)
        }
        if let repositoryRoot, !repositoryRoot.isEmpty {
            return URL(fileURLWithPath: repositoryRoot, isDirectory: true)
        }
        return URL(fileURLWithPath: "/__mi_ao_missing_runtime__", isDirectory: true)
    }

    var isSelfContained: Bool {
        Self.bundledRuntimeURL != nil || (runtimeRoot?.isEmpty == false)
    }

    var startScriptURL: URL {
        runtimeURL.appendingPathComponent("scripts/start.sh")
    }

    var setupScriptURL: URL {
        let repair = runtimeURL.appendingPathComponent("scripts/repair-runtime.sh")
        if FileManager.default.isExecutableFile(atPath: repair.path) { return repair }
        return runtimeURL.appendingPathComponent("scripts/setup.sh")
    }

    var codexAccessibilityScriptURL: URL {
        runtimeURL.appendingPathComponent("scripts/codex-accessibility.sh")
    }

    var isValid: Bool {
        Self.runtimeIsValid(runtimeURL)
            && FileManager.default.isExecutableFile(atPath: startScriptURL.path)
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
    private let modelVerifier: ModelIntegrityVerifier

    init(
        fileManager: FileManager = .default,
        modelVerifier: ModelIntegrityVerifier? = nil
    ) {
        self.fileManager = fileManager
        self.modelVerifier = modelVerifier ?? .production(fileManager: fileManager)
    }

    func inspect(
        configuration: Configuration,
        preferences: AppPreferences = .defaults
    ) -> SetupEnvironmentReport {
        SetupEnvironmentReport(
            checks: [
                systemCheck(),
                speechEngineCheck(configuration: configuration),
                accessibilityCheck(required: preferences.requiresAccessibility),
                bluetoothCheck(),
                codexCheck(
                    required: preferences.requiresCodex,
                    compatibilityRequired: preferences.requiresCodexCompatibility
                ),
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
        let modelStatus = modelVerifier.verify(
            modelPath: configuration.modelPath,
            useMetadataCache: true
        )
        if whisperPath != nil, case .valid(let byteCount) = modelStatus {
            let formattedSize = ByteCountFormatter.string(
                fromByteCount: byteCount,
                countStyle: .file
            )
            return SetupCheck(
                id: .speechEngine,
                title: "本地语音引擎",
                detail: "whisper-cli 与 \(formattedSize) 模型已就绪 · SHA-256 已验证",
                state: .ready,
                action: nil,
                actionTitle: nil
            )
        }
        let modelDetail: String
        switch modelStatus {
        case .valid:
            modelDetail = "缺少 whisper-cli"
        case .missing:
            modelDetail = "缺少语音模型"
        case .tooSmall(let byteCount):
            let size = ByteCountFormatter.string(fromByteCount: byteCount, countStyle: .file)
            modelDetail = "语音模型不完整（\(size)）"
        case .hashMismatch:
            modelDetail = "语音模型完整性校验失败"
        case .contractMissing:
            modelDetail = "当前安装缺少语音模型校验契约"
        case .unreadable:
            modelDetail = "语音模型无法读取"
        }
        let detail: String
        if whisperPath == nil {
            if case .valid = modelStatus {
                detail = "缺少 whisper-cli"
            } else {
                detail = "缺少 whisper-cli；\(modelDetail)"
            }
        } else {
            detail = modelDetail
        }
        return SetupCheck(
            id: .speechEngine,
            title: "本地语音引擎",
            detail: "\(detail)，需要修复安装",
            state: .actionRequired,
            action: .runSetup,
            actionTitle: "修复安装"
        )
    }

    private func accessibilityCheck(required: Bool) -> SetupCheck {
        let trusted = AXIsProcessTrusted()
        if !required {
            return SetupCheck(
                id: .accessibility,
                title: "米遥辅助功能",
                detail: trusted
                    ? "已授权；当前仅转写且按键控制关闭时不会使用"
                    : "仅转写且关闭按键控制时无需授权；以后启用增强功能再授权",
                state: .ready,
                action: trusted ? nil : .requestAccessibility,
                actionTitle: trusted ? nil : "授权增强功能",
                requirement: .optional
            )
        }
        return SetupCheck(
            id: .accessibility,
            title: "米遥辅助功能",
            detail: trusted
                ? "已允许控制 Codex 与执行遥控器动作"
                : "当前 App 未获授权；若系统已显示开启，请移除旧“米遥”后重新添加",
            state: trusted ? .ready : .actionRequired,
            action: trusted ? nil : .requestAccessibility,
            actionTitle: trusted ? nil : "修复权限",
            requirement: .featureRequired
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

    private func codexCheck(required: Bool, compatibilityRequired: Bool) -> SetupCheck {
        guard required else {
            return SetupCheck(
                id: .codex,
                title: "Codex 输入区",
                detail: "当前选择仅转写，不要求安装、登录或重启 Codex",
                state: .ready,
                action: nil,
                actionTitle: nil,
                requirement: .optional
            )
        }
        let snapshot = codexSnapshot()
        guard snapshot.isInstalled else {
            return SetupCheck(
                id: .codex,
                title: "Codex",
                detail: "没有找到 Codex App，请先安装并登录",
                state: .blocked,
                action: nil,
                actionTitle: nil,
                requirement: .featureRequired
            )
        }
        if !compatibilityRequired {
            return SetupCheck(
                id: .codex,
                title: "Codex",
                detail: "Codex 已安装；按键导航可用，只有自动发送需要输入区兼容",
                state: .ready,
                action: nil,
                actionTitle: nil,
                requirement: .featureRequired
            )
        }
        if !snapshot.isRunning {
            return SetupCheck(
                id: .codex,
                title: "Codex 输入区",
                detail: "Codex 已安装；启动米遥时会带本次进程兼容参数打开",
                state: .ready,
                action: nil,
                actionTitle: nil,
                requirement: .featureRequired
            )
        }
        if snapshot.compatibilityEnabled {
            return SetupCheck(
                id: .codex,
                title: "Codex 输入区",
                detail: "当前 Codex 进程已开启辅助功能兼容",
                state: .ready,
                action: nil,
                actionTitle: nil,
                requirement: .featureRequired
            )
        }
        return SetupCheck(
            id: .codex,
            title: "Codex 输入区",
            detail: "Codex 正在工作；需要在空闲时由你确认重启一次",
            state: .actionRequired,
            action: .prepareCodex,
            actionTitle: "准备 Codex",
            requirement: .featureRequired
        )
    }

    private func sourceCheck() -> SetupCheck {
        guard let context = MiAoInstallationContext.load(), context.isValid else {
            return SetupCheck(
                id: .source,
                title: "安装来源",
                detail: "App 内置启动组件缺失或损坏，请从项目目录重新运行 setup.sh",
                state: .blocked,
                action: nil,
                actionTitle: nil
            )
        }
        return SetupCheck(
            id: .source,
            title: "启动组件",
            detail: context.isSelfContained
                ? "米遥 \(context.version) · App 内置门禁与恢复组件可用"
                : "米遥 \(context.version) · 兼容使用本地项目组件",
            state: .ready,
            action: .revealSource,
            actionTitle: context.isSelfContained ? "显示 App" : "查看目录"
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
