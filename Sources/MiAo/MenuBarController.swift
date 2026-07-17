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
    case reconnecting(attempt: Int, delaySeconds: Int)
    case voiceSleeping
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
        case .reconnecting(let attempt, let delaySeconds):
            return "重连第 \(attempt) 次 · \(delaySeconds) 秒后继续"
        case .voiceSleeping: return "智能休眠 · 按键即可唤醒"
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
        case .voiceSleeping: return "moon.zzz.fill"
        case .error: return "exclamationmark.triangle.fill"
        case .stopping: return "hourglass"
        default: return "dot.radiowaves.left.and.right"
        }
    }

    var accentColor: NSColor {
        switch self {
        case .ready: return .systemBlue
        case .recording: return .systemRed
        case .processing: return .systemOrange
        case .sent: return .systemGreen
        case .voiceSleeping: return .systemIndigo
        case .error: return .systemRed
        default: return .secondaryLabelColor
        }
    }
}

enum MiAoMenuBarIconFactory {
    static let opticalSize = NSSize(width: 17, height: 17)
    static let brandAssetName = "mi-ao-menubar-sun-template.svg"

    static func image(for icon: MiAoMenuBarIcon, label: String) -> NSImage? {
        let image: NSImage?
        switch icon {
        case .brand:
            image =
                brandImage()
                ?? configuredSystemSymbol(named: "sun.max", label: label)
        case .systemSymbol(let name):
            image = configuredSystemSymbol(named: name, label: label)
        }
        image?.size = opticalSize
        image?.isTemplate = true
        return image
    }

    private static func brandImage() -> NSImage? {
        let sourceTreeURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Resources/Brand", isDirectory: true)
            .appendingPathComponent(brandAssetName)
        let bundledURL = Bundle.main.resourceURL?
            .appendingPathComponent("Brand", isDirectory: true)
            .appendingPathComponent(brandAssetName)
        return [bundledURL, sourceTreeURL]
            .compactMap { $0 }
            .lazy
            .compactMap(NSImage.init(contentsOf:))
            .first
    }

    private static func configuredSystemSymbol(named name: String, label: String) -> NSImage? {
        let configuration = NSImage.SymbolConfiguration(
            pointSize: 15,
            weight: .regular,
            scale: .medium
        )
        return NSImage(
            systemSymbolName: name,
            accessibilityDescription: "米遥：\(label)"
        )?.withSymbolConfiguration(configuration)
    }
}

@MainActor
private final class MenuBarPanelViewController: NSViewController {
    var onFocusCodex: (() -> Void)?
    var onOpenRecordings: (() -> Void)?
    var onOpenSetup: (() -> Void)?
    var onRetryVoice: (() -> Void)?
    var onQuit: (() -> Void)?

    private let statusIcon = NSImageView()
    private let statusLabel = NSTextField(wrappingLabelWithString: "")
    private let modeLabel = NSTextField(labelWithString: "方向环 · 鼠标指针")
    private let presetLabel = NSTextField(labelWithString: "配置 · 默认 · 鼠标指针")
    private let versionLabel = NSTextField(labelWithString: "")
    private lazy var retryVoiceButton = makeButton(
        title: "立即重试语音连接",
        symbol: "arrow.clockwise",
        action: #selector(retryVoice)
    )
    private var activePresetName = ButtonPreset.pointer.name
    private var runtimeStatus: MiAoRuntimeStatus = .starting

    override func loadView() {
        let effectView = NSVisualEffectView()
        effectView.material = .popover
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        view = effectView
        preferredContentSize = NSSize(width: 330, height: 354)

        statusIcon.translatesAutoresizingMaskIntoConstraints = false
        statusIcon.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 26, weight: .medium)

        let titleLabel = NSTextField(labelWithString: "米遥 MI-AO")
        titleLabel.font = .systemFont(ofSize: 19, weight: .bold)

        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.maximumNumberOfLines = 2

        let titleStack = NSStackView(views: [titleLabel, statusLabel])
        titleStack.orientation = .vertical
        titleStack.alignment = .leading
        titleStack.spacing = 3

        let header = NSStackView(views: [statusIcon, titleStack])
        header.orientation = .horizontal
        header.alignment = .centerY
        header.spacing = 12

        let modeTitle = NSTextField(labelWithString: "当前控制")
        modeTitle.font = .systemFont(ofSize: 11, weight: .medium)
        modeTitle.textColor = .secondaryLabelColor
        modeLabel.font = .systemFont(ofSize: 13, weight: .medium)
        presetLabel.font = .systemFont(ofSize: 11)
        presetLabel.textColor = .secondaryLabelColor
        presetLabel.stringValue = "配置 · \(activePresetName)"
        let modeStack = NSStackView(views: [modeTitle, modeLabel, presetLabel])
        modeStack.orientation = .vertical
        modeStack.alignment = .leading
        modeStack.spacing = 3

        let focusButton = makeButton(
            title: "聚焦 Codex",
            symbol: "rectangle.and.hand.point.up.left",
            action: #selector(focusCodex)
        )
        let recordingsButton = makeButton(
            title: "录音与文字记录",
            symbol: "waveform.badge.magnifyingglass",
            action: #selector(openRecordings)
        )
        let setupButton = makeButton(
            title: "设置与诊断",
            symbol: "checklist",
            action: #selector(openSetup)
        )
        retryVoiceButton.isHidden = true
        let quitButton = makeButton(
            title: "安全退出并恢复遥控器",
            symbol: "power",
            action: #selector(quitSafely)
        )
        quitButton.contentTintColor = .systemRed

        let actions = NSStackView(
            views: [focusButton, recordingsButton, setupButton, retryVoiceButton, quitButton]
        )
        actions.orientation = .vertical
        actions.alignment = .width
        actions.spacing = 8

        let version =
            Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
            as? String ?? "开发版"
        versionLabel.stringValue = "MI-AO \(version) · FanXeon@Poemcoder with Codex"
        versionLabel.font = .systemFont(ofSize: 10)
        versionLabel.textColor = .tertiaryLabelColor
        versionLabel.alignment = .center

        let rootStack = NSStackView(views: [header, modeStack, actions, versionLabel])
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        rootStack.orientation = .vertical
        rootStack.alignment = .width
        rootStack.spacing = 16
        view.addSubview(rootStack)

        let fullWidthViews: [NSView] = [header, modeStack, actions, versionLabel]
        let fullWidthConstraints = fullWidthViews.map {
            $0.widthAnchor.constraint(equalTo: rootStack.widthAnchor)
        }
        let actionWidthConstraints = [
            focusButton, recordingsButton, setupButton, retryVoiceButton, quitButton,
        ].map { $0.widthAnchor.constraint(equalTo: actions.widthAnchor) }

        NSLayoutConstraint.activate(
            [
                rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
                rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
                rootStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 18),
                rootStack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -14),
                statusIcon.widthAnchor.constraint(equalToConstant: 34),
                statusIcon.heightAnchor.constraint(equalToConstant: 34),
                focusButton.heightAnchor.constraint(equalToConstant: 34),
                recordingsButton.heightAnchor.constraint(equalTo: focusButton.heightAnchor),
                setupButton.heightAnchor.constraint(equalTo: focusButton.heightAnchor),
                retryVoiceButton.heightAnchor.constraint(equalTo: focusButton.heightAnchor),
                quitButton.heightAnchor.constraint(equalTo: focusButton.heightAnchor),
            ] + fullWidthConstraints + actionWidthConstraints)

        update(status: runtimeStatus)
    }

    func update(status: MiAoRuntimeStatus) {
        runtimeStatus = status
        guard isViewLoaded else { return }
        statusLabel.stringValue = status.label
        statusIcon.image = NSImage(
            systemSymbolName: status.systemImageName,
            accessibilityDescription: "米遥：\(status.label)"
        )
        statusIcon.contentTintColor = status.accentColor
        let voiceRetryIsHidden = {
            switch status {
            case .reconnecting:
                retryVoiceButton.title = "立即重试语音连接"
                return false
            case .voiceSleeping:
                retryVoiceButton.title = "唤醒语音连接"
                return false
            default:
                return true
            }
        }()
        retryVoiceButton.isHidden = voiceRetryIsHidden
        preferredContentSize = NSSize(
            width: 330,
            height: voiceRetryIsHidden ? 354 : 396
        )
    }

    func update(controlMode: RemoteControlMode) {
        guard isViewLoaded else { return }
        modeLabel.stringValue =
            controlMode == .pointer
            ? "方向环 · 鼠标指针"
            : "方向环 · 上下左右"
    }

    func update(preset: ButtonPreset) {
        activePresetName = preset.name
        guard isViewLoaded else { return }
        presetLabel.stringValue = "配置 · \(preset.name)"
    }

    private func makeButton(title: String, symbol: String, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.bezelStyle = .rounded
        button.alignment = .left
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: title)
        button.imagePosition = .imageLeading
        return button
    }

    @objc private func focusCodex() { onFocusCodex?() }
    @objc private func openRecordings() { onOpenRecordings?() }
    @objc private func openSetup() { onOpenSetup?() }
    @objc private func retryVoice() { onRetryVoice?() }
    @objc private func quitSafely() { onQuit?() }
}

@MainActor
final class MenuBarController: NSObject, NSPopoverDelegate {
    var onQuit: (() -> Void)?
    var onRetryVoice: (() -> Void)?

    private let configuration: Configuration
    private let outputDirectory: String
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private let panel = MenuBarPanelViewController()
    private var setupWindowController: SetupGuideWindowController?
    private var status: MiAoRuntimeStatus = .starting
    private var activity: MiAoCommandActivity?
    private var activityTimer: Timer?

    init(configuration: Configuration) {
        self.configuration = configuration
        outputDirectory = configuration.outputDirectory
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        NSApplication.shared.setActivationPolicy(.accessory)
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        popover.contentViewController = panel

        panel.onFocusCodex = { [weak self] in
            guard let self else { return }
            self.closePopover()
            self.show(activity: .codexActivation(CodexSubmitter().launchOrActivateCodex()))
        }
        panel.onOpenRecordings = { [weak self] in
            self?.closePopover()
            self?.openRecordings()
        }
        panel.onOpenSetup = { [weak self] in
            self?.closePopover()
            self?.showSetupGuide()
        }
        panel.onRetryVoice = { [weak self] in
            self?.onRetryVoice?()
        }
        panel.onQuit = { [weak self] in
            self?.closePopover()
            self?.quitSafely()
        }

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(togglePopover)
            button.sendAction(on: [.leftMouseUp])
            button.imagePosition = .imageOnly
            button.imageScaling = .scaleProportionallyDown
            button.alignment = .center
        }
        let catalog = ButtonPresetStore().load().catalog
        let preset = (try? catalog.preset(id: configuration.buttonPresetID)) ?? .pointer
        panel.update(preset: preset)
        update(status: .starting)
        statusItem.isVisible = true
    }

    func update(status: MiAoRuntimeStatus) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in self?.update(status: status) }
            return
        }
        self.status = status
        panel.update(status: status)
        if !status.allowsTransientCommandActivity {
            clearActivity(render: false)
        }
        renderMenuBarPresentation()
    }

    func show(activity: MiAoCommandActivity) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in self?.show(activity: activity) }
            return
        }
        guard status.allowsTransientCommandActivity else { return }
        activityTimer?.invalidate()
        self.activity = activity
        renderMenuBarPresentation()
        activityTimer = Timer.scheduledTimer(
            withTimeInterval: MiAoCommandActivity.displayDuration,
            repeats: false
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.clearActivity(render: true)
            }
        }
    }

    private func renderMenuBarPresentation() {
        guard let button = statusItem.button else { return }
        let presentation = MiAoMenuBarPresentation.resolved(
            status: status,
            activity: activity
        )
        button.image = MiAoMenuBarIconFactory.image(
            for: presentation.icon,
            label: presentation.label
        )
        button.title = ""
        button.contentTintColor = nil
        button.toolTip = "米遥 · \(presentation.label)"
        button.setAccessibilityLabel("米遥")
        button.setAccessibilityValue(presentation.label)
    }

    func update(controlMode: RemoteControlMode) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in self?.update(controlMode: controlMode) }
            return
        }
        panel.update(controlMode: controlMode)
    }

    func update(preset: ButtonPreset) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in self?.update(preset: preset) }
            return
        }
        panel.update(preset: preset)
    }

    @objc private func togglePopover() {
        if popover.isShown {
            closePopover()
            return
        }
        guard let button = statusItem.button else { return }
        panel.update(status: status)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    private func closePopover() {
        popover.performClose(nil)
    }

    private func clearActivity(render: Bool) {
        activityTimer?.invalidate()
        activityTimer = nil
        activity = nil
        if render { renderMenuBarPresentation() }
    }

    private func openRecordings() {
        try? FileManager.default.createDirectory(
            atPath: outputDirectory,
            withIntermediateDirectories: true
        )
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: outputDirectory)
    }

    func showSetupGuide() {
        if setupWindowController == nil {
            setupWindowController = SetupGuideWindowController(
                configuration: configuration,
                standalone: false
            )
        }
        setupWindowController?.showWindow(nil)
    }

    private func quitSafely() {
        update(status: .stopping)
        onQuit?()
    }
}
