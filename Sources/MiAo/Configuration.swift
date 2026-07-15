// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import Foundation

struct Configuration {
    enum Mode: String {
        case scan
        case capture
        case run
        case doctor
        case authorize
        case checkButtons = "check-buttons"
        case learnButtons = "learn-buttons"
        case debugButtons = "debug-buttons"
    }

    var mode: Mode = .run
    var nameFilter: String?
    var peripheralIdentifier: UUID?
    var scanSeconds: TimeInterval = 20
    var captureSeconds: TimeInterval = 60
    var modelPath: String = NSString(string: "~/.cache/mi-ao/ggml-base.bin").expandingTildeInPath
    var whisperPath: String?
    var language = "zh"
    var whisperPrompt: String?
    var outputDirectory = NSString(string: "~/Library/Application Support/mi-ao/recordings")
        .expandingTildeInPath
    var captureDirectory = NSString(string: "~/Library/Application Support/mi-ao/captures")
        .expandingTildeInPath
    var silenceTimeout: TimeInterval = 1.5
    var silenceThreshold: Double = 35
    var gainDB: Double = 20
    var submitToCodex = true
    var forceSubmit = false
    var debug = false
    var includeIdentifiers = false
    var includeDeviceNames = false
    var hidVendorID = 0x2717
    var hidProductID = 0x32B8
    var buttonSeconds: TimeInterval = 10
    var buttonID: String?
    var buttonPresetID = "pointer"
    var buttonProfilePath: String?
    var resolvedProfilePath: String?
    var buttonsEnabled = true
    var buttonProfileDirectory = NSString(
        string: "~/Library/Application Support/mi-ao/button-profiles"
    ).expandingTildeInPath

    static func parse(_ arguments: [String]) throws -> Configuration {
        var config = Configuration()
        var index = 1

        if index < arguments.count, let mode = Mode(rawValue: arguments[index]) {
            config.mode = mode
            index += 1
        }

        func requireValue(for flag: String) throws -> String {
            index += 1
            guard index < arguments.count else {
                throw BridgeError.configuration("\(flag) 缺少参数")
            }
            return arguments[index]
        }

        while index < arguments.count {
            let flag = arguments[index]
            switch flag {
            case "--name":
                config.nameFilter = try requireValue(for: flag)
            case "--identifier":
                let raw = try requireValue(for: flag)
                guard let uuid = UUID(uuidString: raw) else {
                    throw BridgeError.configuration("无效的 peripheral identifier: \(raw)")
                }
                config.peripheralIdentifier = uuid
            case "--scan-seconds":
                config.scanSeconds = try parseDouble(try requireValue(for: flag), flag: flag)
            case "--capture-seconds":
                config.captureSeconds = try parseDouble(try requireValue(for: flag), flag: flag)
            case "--model":
                config.modelPath = NSString(string: try requireValue(for: flag)).expandingTildeInPath
            case "--whisper":
                config.whisperPath = NSString(string: try requireValue(for: flag)).expandingTildeInPath
            case "--language":
                config.language = try requireValue(for: flag)
            case "--prompt":
                config.whisperPrompt = try requireValue(for: flag)
            case "--output-dir":
                config.outputDirectory = NSString(string: try requireValue(for: flag)).expandingTildeInPath
            case "--capture-dir":
                config.captureDirectory = NSString(string: try requireValue(for: flag)).expandingTildeInPath
            case "--silence-ms":
                config.silenceTimeout = try parseDouble(try requireValue(for: flag), flag: flag) / 1_000
            case "--silence-threshold":
                config.silenceThreshold = try parseDouble(try requireValue(for: flag), flag: flag)
            case "--gain-db":
                config.gainDB = try parseDouble(try requireValue(for: flag), flag: flag)
            case "--no-submit":
                config.submitToCodex = false
            case "--force-submit":
                config.forceSubmit = true
            case "--debug":
                config.debug = true
            case "--include-identifiers":
                config.includeIdentifiers = true
            case "--include-device-names":
                config.includeDeviceNames = true
            case "--vendor-id":
                config.hidVendorID = try parseInteger(try requireValue(for: flag), flag: flag)
            case "--product-id":
                config.hidProductID = try parseInteger(try requireValue(for: flag), flag: flag)
            case "--button-seconds":
                config.buttonSeconds = try parseDouble(try requireValue(for: flag), flag: flag)
            case "--button":
                config.buttonID = try requireValue(for: flag)
            case "--preset":
                config.buttonPresetID = try requireValue(for: flag)
            case "--button-profile":
                config.buttonProfilePath =
                    NSString(
                        string: try requireValue(for: flag)
                    ).expandingTildeInPath
            case "--emit-profile":
                config.resolvedProfilePath =
                    NSString(
                        string: try requireValue(for: flag)
                    ).expandingTildeInPath
            case "--no-buttons":
                config.buttonsEnabled = false
            case "--profile-dir":
                config.buttonProfileDirectory =
                    NSString(
                        string: try requireValue(for: flag)
                    ).expandingTildeInPath
            case "--help", "-h":
                print(Self.help)
                exit(0)
            default:
                throw BridgeError.configuration("未知参数: \(flag)\n\n\(Self.help)")
            }
            index += 1
        }

        return config
    }

    private static func parseDouble(_ raw: String, flag: String) throws -> Double {
        guard let value = Double(raw), value >= 0 else {
            throw BridgeError.configuration("\(flag) 需要非负数字，收到: \(raw)")
        }
        return value
    }

    private static func parseInteger(_ raw: String, flag: String) throws -> Int {
        let normalized = raw.lowercased()
        let value: Int?
        if normalized.hasPrefix("0x") {
            value = Int(normalized.dropFirst(2), radix: 16)
        } else {
            value = Int(normalized)
        }
        guard let value, value >= 0 else {
            throw BridgeError.configuration("\(flag) 需要十进制或 0x 十六进制非负整数，收到: \(raw)")
        }
        return value
    }

    private static var executableName: String {
        URL(fileURLWithPath: CommandLine.arguments.first ?? "voice-bridge").lastPathComponent
    }

    static var help: String {
        """
        米遥 MI-AO：蓝牙语音遥控器桥接

        用法：
          \(executableName) scan [--scan-seconds 20] [--debug]
          \(executableName) capture [--identifier <UUID> | --name <文本>] [选项]
          \(executableName) run [选项]
          \(executableName) doctor
          \(executableName) authorize
          \(executableName) check-buttons [run 选项]
          \(executableName) learn-buttons [选项]
          \(executableName) debug-buttons [选项]

        capture 选项：
          --identifier <UUID>        连接 scan 输出的 macOS peripheral UUID
          --name <文本>              连接名称包含该文本的设备
          --scan-seconds <秒>        等待目标或纯扫描时长，默认 20
          --capture-seconds <秒>     连接后的采集时长，默认 60
          --capture-dir <目录>       报告与原始事件保存目录
          --include-identifiers      在报告中保留设备 UUID，默认哈希脱敏
          --include-device-names     在报告中保留广播名称，默认隐藏
          --debug                    同时在终端打印原始 GATT 数据

        run 选项：
          --name <文本>              只连接名称包含该文本的遥控器
          --identifier <UUID>        只连接 scan 输出的 macOS peripheral UUID
          --model <路径>             whisper.cpp GGML 模型
          --whisper <路径>           whisper-cli 可执行文件
          --language <代码>          转写语言，默认 zh
          --prompt <文本>            覆盖 Whisper 上下文提示
          --silence-ms <毫秒>        无松手信号时的静音收口时间，默认 1500
          --silence-threshold <RMS>  静音判定阈值，默认 35
          --gain-db <分贝>           写入 WAV 前增益，默认 20
          --output-dir <目录>        WAV 和 transcript 保存目录
          --no-submit                只转写，不发送给 Codex
          --force-submit             无法验证焦点控件时仍向 Codex 粘贴并回车
          --debug                    打印原始 GATT 数据和运行时 HID 按键映射
          --preset <标识>            按键映射套装，默认 pointer
          --button-profile <路径>    只使用指定的已确认校准档案
          --emit-profile <路径>      check-buttons 输出合并后的硬件档案
          --no-buttons               禁用实体按键动作，只保留语音链路

        learn-buttons 选项：
          --name <文本>              HID 产品名需包含该文本
          --vendor-id <数字>         HID Vendor ID，默认 0x2717（小米）
          --product-id <数字>        HID Product ID，默认 0x32B8
          --button-seconds <秒>      每个按钮的等待时间，默认 10
          --button <标识>            只采集一个按钮，例如 back
          --preset <标识>            校准时预览的映射套装，默认 pointer
          --profile-dir <目录>       脱敏按键报告保存目录

        debug-buttons 使用相同选项，但每个结果都必须人工确认；只预览当前预设动作，不实际执行米遥动作。
        check-buttons 在修改系统映射前验证辅助功能权限和可用按键档案，不启动 BLE 或执行按键动作。
        校准期间原始 HID 键仍可能由 macOS 或前台 App 处理，请先聚焦到安全窗口。
        """
    }
}

enum BridgeError: LocalizedError {
    case configuration(String)
    case bluetooth(String)
    case protocolFailure(String)
    case transcription(String)
    case submission(String)

    var errorDescription: String? {
        switch self {
        case .configuration(let message), .bluetooth(let message),
            .protocolFailure(let message), .transcription(let message),
            .submission(let message):
            return message
        }
    }
}
