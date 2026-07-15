// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import AppKit
import Foundation

enum MiAoRuntimeStatus: Equatable {
    case starting
    case searching
    case connecting
    case ready
    case recording
    case processing(Int)
    case sent
    case disconnected
    case stopping
    case error(String)

    var label: String {
        switch self {
        case .starting: return "正在启动"
        case .searching: return "正在寻找遥控器"
        case .connecting: return "正在连接遥控器"
        case .ready: return "已就绪 · 按住语音键说话"
        case .recording: return "正在听你说话"
        case .processing(let count):
            return count > 1 ? "后台转写中 · 另有一条等待" : "后台转写中 · 可继续说话"
        case .sent: return "已发送到 Codex"
        case .disconnected: return "遥控器已断开 · 正在重连"
        case .stopping: return "正在安全退出"
        case .error(let message): return "需要处理：\(message)"
        }
    }

    var systemImageName: String {
        switch self {
        case .ready: return "wand.and.stars"
        case .recording: return "mic.fill"
        case .processing: return "waveform"
        case .sent: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        case .stopping: return "hourglass"
        default: return "dot.radiowaves.left.and.right"
        }
    }
}

final class MenuBarController: NSObject {
    var onQuit: (() -> Void)?

    private let outputDirectory: String
    private let statusItem: NSStatusItem
    private let statusLine = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let modeLine = NSMenuItem(title: "方向环：鼠标指针", action: nil, keyEquivalent: "")
    private var status: MiAoRuntimeStatus = .starting

    init(outputDirectory: String) {
        self.outputDirectory = outputDirectory
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        NSApplication.shared.setActivationPolicy(.accessory)
        statusLine.isEnabled = false
        modeLine.isEnabled = false

        let menu = NSMenu()
        menu.addItem(statusLine)
        menu.addItem(modeLine)
        menu.addItem(.separator())
        menu.addItem(
            NSMenuItem(
                title: "聚焦 Codex",
                action: #selector(focusCodex),
                keyEquivalent: ""
            )
        )
        menu.addItem(
            NSMenuItem(
                title: "打开录音与文字记录",
                action: #selector(openRecordings),
                keyEquivalent: ""
            )
        )
        menu.addItem(.separator())
        menu.addItem(
            NSMenuItem(
                title: "安全退出并恢复遥控器",
                action: #selector(quitSafely),
                keyEquivalent: "q"
            )
        )
        for item in menu.items where item.action != nil { item.target = self }
        statusItem.menu = menu
        update(status: .starting)
    }

    func update(status: MiAoRuntimeStatus) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in self?.update(status: status) }
            return
        }
        self.status = status
        statusLine.title = "状态：\(status.label)"
        guard let button = statusItem.button else { return }
        let image = NSImage(
            systemSymbolName: status.systemImageName,
            accessibilityDescription: "米遥：\(status.label)"
        )
        image?.isTemplate = true
        button.image = image
        button.title = "米遥"
        button.imagePosition = .imageLeading
        button.toolTip = "米遥 · \(status.label)"
    }

    func update(controlMode: RemoteControlMode) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in self?.update(controlMode: controlMode) }
            return
        }
        modeLine.title = controlMode == .pointer ? "方向环：鼠标指针" : "方向环：上下左右"
    }

    @objc private func focusCodex() {
        _ = CodexSubmitter().launchOrActivateCodex()
    }

    @objc private func openRecordings() {
        try? FileManager.default.createDirectory(
            atPath: outputDirectory,
            withIntermediateDirectories: true
        )
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: outputDirectory)
    }

    @objc private func quitSafely() {
        update(status: .stopping)
        onQuit?()
    }
}
