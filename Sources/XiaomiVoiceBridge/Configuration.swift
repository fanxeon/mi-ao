import Foundation

struct Configuration {
    enum Mode: String {
        case scan
        case run
        case doctor
        case authorize
    }

    var mode: Mode = .run
    var nameFilter: String?
    var peripheralIdentifier: UUID?
    var scanSeconds: TimeInterval = 20
    var modelPath: String = NSString(string: "~/.cache/xiaomi-voice-bridge/ggml-base.bin").expandingTildeInPath
    var whisperPath: String?
    var language = "zh"
    var outputDirectory = NSString(string: "~/Library/Application Support/XiaomiVoiceBridge/recordings")
        .expandingTildeInPath
    var silenceTimeout: TimeInterval = 1.5
    var silenceThreshold: Double = 35
    var gainDB: Double = 20
    var submitToCodex = true
    var forceSubmit = false
    var debug = false

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
            case "--model":
                config.modelPath = NSString(string: try requireValue(for: flag)).expandingTildeInPath
            case "--whisper":
                config.whisperPath = NSString(string: try requireValue(for: flag)).expandingTildeInPath
            case "--language":
                config.language = try requireValue(for: flag)
            case "--output-dir":
                config.outputDirectory = NSString(string: try requireValue(for: flag)).expandingTildeInPath
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

    static let help = """
        Xiaomi Voice Bridge

        用法：
          xiaomi-voice-bridge scan [--scan-seconds 20] [--debug]
          xiaomi-voice-bridge run [选项]
          xiaomi-voice-bridge doctor
          xiaomi-voice-bridge authorize

        run 选项：
          --name <文本>              只连接名称包含该文本的遥控器
          --identifier <UUID>        只连接 scan 输出的 macOS peripheral UUID
          --model <路径>             whisper.cpp GGML 模型
          --whisper <路径>           whisper-cli 可执行文件
          --language <代码>          转写语言，默认 zh
          --silence-ms <毫秒>        无松手信号时的静音收口时间，默认 1500
          --silence-threshold <RMS>  静音判定阈值，默认 35
          --gain-db <分贝>           写入 WAV 前增益，默认 20
          --output-dir <目录>        WAV 和 transcript 保存目录
          --no-submit                只转写，不发送给 Codex
          --force-submit             无法验证焦点控件时仍向 Codex 粘贴并回车
          --debug                    打印原始 GATT 数据
        """
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
