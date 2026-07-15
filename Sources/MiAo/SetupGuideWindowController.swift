// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import AppKit
import ApplicationServices
@preconcurrency import CoreBluetooth
import Foundation

private final class SetupCheckRowView: NSView {
    private let iconView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let requirementLabel = NSTextField(labelWithString: "")
    private let detailLabel = NSTextField(wrappingLabelWithString: "")
    private let actionButton = NSButton()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 12
        layer?.backgroundColor = NSColor.separatorColor.withAlphaComponent(0.075).cgColor

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        iconView.contentTintColor = .secondaryLabelColor

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)

        requirementLabel.translatesAutoresizingMaskIntoConstraints = false
        requirementLabel.font = .systemFont(ofSize: 10, weight: .semibold)
        requirementLabel.alignment = .center
        requirementLabel.wantsLayer = true
        requirementLabel.layer?.cornerRadius = 5

        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.font = .systemFont(ofSize: 12)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.maximumNumberOfLines = 2

        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.bezelStyle = .rounded
        actionButton.controlSize = .small
        actionButton.isHidden = true

        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(requirementLabel)
        addSubview(detailLabel)
        addSubview(actionButton)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 74),
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 13),
            titleLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: requirementLabel.leadingAnchor,
                constant: -8
            ),
            requirementLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: actionButton.leadingAnchor,
                constant: -10
            ),
            requirementLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            requirementLabel.widthAnchor.constraint(equalToConstant: 88),
            requirementLabel.heightAnchor.constraint(equalToConstant: 20),
            detailLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            detailLabel.trailingAnchor.constraint(equalTo: actionButton.leadingAnchor, constant: -12),
            detailLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -12),
            actionButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            actionButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            actionButton.widthAnchor.constraint(equalToConstant: 112),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func update(check: SetupCheck, target: AnyObject, action: Selector) {
        titleLabel.stringValue = check.title
        detailLabel.stringValue = check.detail
        requirementLabel.stringValue = check.requirement.title
        switch check.requirement {
        case .required:
            requirementLabel.textColor = .systemBlue
            requirementLabel.layer?.backgroundColor =
                NSColor.systemBlue.withAlphaComponent(0.11).cgColor
        case .featureRequired:
            requirementLabel.textColor = .systemOrange
            requirementLabel.layer?.backgroundColor =
                NSColor.systemOrange.withAlphaComponent(0.12).cgColor
        case .optional:
            requirementLabel.textColor = .secondaryLabelColor
            requirementLabel.layer?.backgroundColor =
                NSColor.secondaryLabelColor.withAlphaComponent(0.09).cgColor
        }
        let symbolName: String
        let color: NSColor
        switch check.state {
        case .ready:
            symbolName = "checkmark.circle.fill"
            color = .systemGreen
        case .actionRequired:
            symbolName = "exclamationmark.circle.fill"
            color = .systemOrange
        case .blocked:
            symbolName = "xmark.circle.fill"
            color = .systemRed
        }
        iconView.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: check.title)
        iconView.contentTintColor = color

        if let actionTitle = check.actionTitle, check.action != nil {
            actionButton.title = actionTitle
            actionButton.target = target
            actionButton.action = action
            actionButton.identifier = NSUserInterfaceItemIdentifier(check.id.rawValue)
            actionButton.isHidden = false
        } else {
            actionButton.isHidden = true
            actionButton.identifier = nil
        }
    }
}

final class SetupGuideWindowController: NSWindowController, NSWindowDelegate {
    private let configuration: Configuration
    private let standalone: Bool
    private let preferencesStore: AppPreferencesStore
    private let loginItemController: LoginItemController
    private let inspector = SetupEnvironmentInspector()
    private let rows = Dictionary(
        uniqueKeysWithValues: SetupCheckID.allCases.map { ($0, SetupCheckRowView()) }
    )
    private let summaryLabel = NSTextField(wrappingLabelWithString: "")
    private let preferenceStateLabel = NSTextField(wrappingLabelWithString: "")
    private let loginItemStateLabel = NSTextField(wrappingLabelWithString: "")
    private let automaticSubmitCheckbox = NSButton(
        checkboxWithTitle: "自动发送到 Codex（需要辅助功能与 Codex）",
        target: nil,
        action: nil
    )
    private let buttonControlCheckbox = NSButton(
        checkboxWithTitle: "启用遥控器按键控制（需要辅助功能；默认方案使用 Codex）",
        target: nil,
        action: nil
    )
    private let loginAtStartupCheckbox = NSButton(
        checkboxWithTitle: "登录时启动（可选，可随时关闭）",
        target: nil,
        action: nil
    )
    private let openLoginItemsButton = NSButton(title: "打开登录项设置", target: nil, action: nil)
    private let refreshButton = NSButton(title: "重新检查", target: nil, action: nil)
    private let startButton = NSButton(title: "连接遥控器并开始", target: nil, action: nil)
    private var report: SetupEnvironmentReport?
    private var bluetoothRequester: BluetoothAuthorizationRequester?
    private var process: Process?
    private var refreshTimer: Timer?
    private var preferences: AppPreferences
    private var preferencesLoadState: AppPreferencesLoadState

    init(
        configuration: Configuration,
        standalone: Bool,
        preferencesStore: AppPreferencesStore = AppPreferencesStore(),
        loginItemController: LoginItemController = LoginItemController()
    ) {
        self.configuration = configuration
        self.standalone = standalone
        self.preferencesStore = preferencesStore
        self.loginItemController = loginItemController
        let snapshot = preferencesStore.load()
        preferences = snapshot.preferences
        preferencesLoadState = snapshot.state
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 870),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "米遥设置向导"
        window.minSize = NSSize(width: 600, height: 820)
        window.isReleasedWhenClosed = false
        super.init(window: window)
        window.delegate = self
        buildInterface()
        refresh()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func showWindow(_ sender: Any?) {
        if standalone {
            NSApplication.shared.setActivationPolicy(.regular)
        }
        super.showWindow(sender)
        window?.center()
        window?.makeKeyAndOrderFront(sender)
        NSApplication.shared.activate(ignoringOtherApps: true)
        refresh()
        startAutoRefresh()
    }

    func windowWillClose(_ notification: Notification) {
        refreshTimer?.invalidate()
        refreshTimer = nil
        if standalone { NSApplication.shared.terminate(nil) }
    }

    deinit {
        refreshTimer?.invalidate()
    }

    private func buildInterface() {
        guard let contentView = window?.contentView else { return }

        let titleLabel = NSTextField(labelWithString: "让米遥在这台 Mac 上就绪")
        titleLabel.font = .systemFont(ofSize: 25, weight: .bold)

        let subtitleLabel = NSTextField(
            wrappingLabelWithString: "“必须”和“当前功能必需”会影响启动；“可选”未授权也能继续。米遥只在必要时请求系统权限。"
        )
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabelColor

        let header = NSStackView(views: [titleLabel, subtitleLabel])
        header.orientation = .vertical
        header.alignment = .leading
        header.spacing = 7

        let checksStack = NSStackView(
            views: SetupCheckID.allCases.compactMap { rows[$0] }
        )
        checksStack.orientation = .vertical
        checksStack.alignment = .width
        checksStack.spacing = 8

        let preferencesView = buildPreferencesView()

        summaryLabel.font = .systemFont(ofSize: 12)
        summaryLabel.textColor = .secondaryLabelColor

        refreshButton.target = self
        refreshButton.action = #selector(refreshPressed)
        refreshButton.bezelStyle = .rounded

        startButton.target = self
        startButton.action = #selector(startPressed)
        startButton.bezelStyle = .rounded
        startButton.keyEquivalent = "\r"

        let buttonSpacer = NSView()
        let buttons = NSStackView(views: [refreshButton, buttonSpacer, startButton])
        buttons.orientation = .horizontal
        buttons.alignment = .centerY
        buttons.spacing = 10

        let rootStack = NSStackView(
            views: [header, preferencesView, checksStack, summaryLabel, buttons]
        )
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        rootStack.orientation = .vertical
        rootStack.alignment = .width
        rootStack.spacing = 16
        contentView.addSubview(rootStack)

        let fullWidthViews: [NSView] = [
            header,
            preferencesView,
            checksStack,
            summaryLabel,
            buttons,
        ]
        let fullWidthConstraints = fullWidthViews.map {
            $0.widthAnchor.constraint(equalTo: rootStack.widthAnchor)
        }
        let rowWidthConstraints = SetupCheckID.allCases.compactMap { rows[$0] }.map {
            $0.widthAnchor.constraint(equalTo: checksStack.widthAnchor)
        }

        NSLayoutConstraint.activate(
            [
                rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
                rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -28),
                rootStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 26),
                rootStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -24),
                buttonSpacer.widthAnchor.constraint(greaterThanOrEqualToConstant: 1),
                startButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 176),
            ] + fullWidthConstraints + rowWidthConstraints)
    }

    private func buildPreferencesView() -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.cornerRadius = 12
        container.layer?.backgroundColor =
            NSColor.controlAccentColor.withAlphaComponent(0.055).cgColor

        let title = NSTextField(labelWithString: "使用方式与可选项")
        title.font = .systemFont(ofSize: 14, weight: .semibold)

        let explanation = NSTextField(
            wrappingLabelWithString:
                "核心必需：macOS 14+、本地语音引擎、蓝牙和 App 启动组件。下面三项由你决定。"
        )
        explanation.font = .systemFont(ofSize: 11)
        explanation.textColor = .secondaryLabelColor

        automaticSubmitCheckbox.target = self
        automaticSubmitCheckbox.action = #selector(preferencesChanged)
        buttonControlCheckbox.target = self
        buttonControlCheckbox.action = #selector(preferencesChanged)
        loginAtStartupCheckbox.target = self
        loginAtStartupCheckbox.action = #selector(loginItemChanged)

        openLoginItemsButton.target = self
        openLoginItemsButton.action = #selector(openLoginItemsSettings)
        openLoginItemsButton.bezelStyle = .rounded
        openLoginItemsButton.controlSize = .small
        openLoginItemsButton.isHidden = true

        loginItemStateLabel.font = .systemFont(ofSize: 10)
        loginItemStateLabel.textColor = .secondaryLabelColor
        preferenceStateLabel.font = .systemFont(ofSize: 10)
        preferenceStateLabel.textColor = .systemOrange

        let loginSpacer = NSView()
        let loginRow = NSStackView(
            views: [loginAtStartupCheckbox, loginSpacer, openLoginItemsButton]
        )
        loginRow.orientation = .horizontal
        loginRow.alignment = .centerY
        loginRow.spacing = 8

        let stack = NSStackView(
            views: [
                title,
                explanation,
                automaticSubmitCheckbox,
                buttonControlCheckbox,
                loginRow,
                loginItemStateLabel,
                preferenceStateLabel,
            ]
        )
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .vertical
        stack.alignment = .width
        stack.spacing = 5
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 154),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 13),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
            loginSpacer.widthAnchor.constraint(greaterThanOrEqualToConstant: 1),
        ])
        return container
    }

    @objc private func refreshPressed() {
        refresh()
    }

    private func refresh() {
        updatePreferenceControls()
        let report = inspector.inspect(
            configuration: configuration,
            preferences: preferences
        )
        self.report = report
        for check in report.checks {
            rows[check.id]?.update(
                check: check,
                target: self,
                action: #selector(performCheckAction(_:))
            )
        }

        if report.runtimeActive {
            summaryLabel.stringValue = "米遥当前已经运行。这里可以复查环境；退出请使用菜单栏中的安全退出。"
            startButton.title = "米遥正在运行"
            startButton.isEnabled = false
        } else if report.canStart {
            summaryLabel.stringValue = "环境已就绪。请先在系统蓝牙中连接遥控器，然后开始使用。"
            startButton.title = "连接遥控器并开始"
            startButton.isEnabled = process == nil
        } else {
            summaryLabel.stringValue = "还有项目需要处理；米遥不会在检查通过前修改系统按键映射。"
            startButton.title = "完成上方设置后开始"
            startButton.isEnabled = false
        }
        refreshButton.isEnabled = process == nil
    }

    private func updatePreferenceControls() {
        automaticSubmitCheckbox.state =
            preferences.submissionMode == .codex ? .on : .off
        buttonControlCheckbox.state = preferences.buttonControlEnabled ? .on : .off
        let preferencesAreWritable: Bool
        if case .unsupportedVersion = preferencesLoadState {
            preferencesAreWritable = false
        } else {
            preferencesAreWritable = true
        }
        automaticSubmitCheckbox.isEnabled = preferencesAreWritable
        buttonControlCheckbox.isEnabled = preferencesAreWritable

        let loginState = loginItemController.state
        switch loginState {
        case .disabled:
            loginAtStartupCheckbox.state = .off
            loginAtStartupCheckbox.isEnabled = true
            openLoginItemsButton.isHidden = true
        case .enabled:
            loginAtStartupCheckbox.state = .on
            loginAtStartupCheckbox.isEnabled = true
            openLoginItemsButton.isHidden = true
        case .requiresApproval:
            loginAtStartupCheckbox.state = .on
            loginAtStartupCheckbox.isEnabled = true
            openLoginItemsButton.isHidden = false
        case .unavailable:
            loginAtStartupCheckbox.state = .off
            loginAtStartupCheckbox.isEnabled = false
            openLoginItemsButton.isHidden = true
        }
        loginItemStateLabel.stringValue = loginState.detail

        switch preferencesLoadState {
        case .defaults, .loaded:
            preferenceStateLabel.stringValue = ""
        case .recoveredInvalid(let url):
            preferenceStateLabel.stringValue =
                "已隔离损坏配置并恢复默认：\(url.lastPathComponent)"
        case .unsupportedVersion(let version):
            preferenceStateLabel.stringValue =
                "检测到较新的配置 schema v\(version)，当前以安全默认值运行且未覆盖原文件"
        }
    }

    @objc private func preferencesChanged() {
        let previous = preferences
        preferences.submissionMode =
            automaticSubmitCheckbox.state == .on ? .codex : .transcriptionOnly
        preferences.buttonControlEnabled = buttonControlCheckbox.state == .on
        do {
            try preferencesStore.save(preferences)
            preferencesLoadState = .loaded
        } catch {
            preferences = previous
            showError(title: "偏好设置没有保存", message: error.localizedDescription)
        }
        refresh()
    }

    @objc private func loginItemChanged() {
        let requested = loginAtStartupCheckbox.state == .on
        do {
            try loginItemController.setEnabled(requested)
        } catch {
            showError(title: "登录时启动没有更改", message: error.localizedDescription)
        }
        refresh()
    }

    @objc private func openLoginItemsSettings() {
        loginItemController.openSystemSettings()
    }

    @objc private func performCheckAction(_ sender: NSButton) {
        guard
            let rawID = sender.identifier?.rawValue,
            let id = SetupCheckID(rawValue: rawID),
            let action = report?.check(id)?.action
        else { return }

        switch action {
        case .requestAccessibility:
            repairAccessibilityAuthorization()
        case .requestBluetooth:
            bluetoothRequester = BluetoothAuthorizationRequester { [weak self] in
                self?.scheduleRefresh()
            }
            bluetoothRequester?.start()
        case .openBluetoothSettings:
            openBluetoothSettings()
        case .openBluetoothPrivacy:
            openPrivacyPane(anchor: "Privacy_Bluetooth")
        case .prepareCodex:
            prepareCodex()
        case .runSetup:
            runSetupRepair()
        case .revealSource:
            NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
        }
    }

    @objc private func startPressed() {
        guard report?.canStart == true, let context = MiAoInstallationContext.load(), context.isValid
        else {
            refresh()
            return
        }
        runScript(
            context.startScriptURL,
            arguments: preferences.runtimeArguments,
            progress: "正在执行启动门禁并连接遥控器…"
        ) { [weak self] result in
            switch result {
            case .success(let output):
                var completedPreferences = self?.preferences ?? .defaults
                completedPreferences.hasCompletedSetup = true
                if let loadState = self?.preferencesLoadState,
                    case .unsupportedVersion = loadState
                {
                    // Preserve the future-version file verbatim.
                } else {
                    do {
                        try self?.preferencesStore.save(completedPreferences)
                        self?.preferences = completedPreferences
                        self?.preferencesLoadState = .loaded
                    } catch {
                        self?.showError(
                            title: "米遥已启动，但设置未保存",
                            message: error.localizedDescription
                        )
                        self?.refresh()
                        return
                    }
                }
                self?.summaryLabel.stringValue =
                    output.isEmpty
                    ? "米遥已启动，请查看菜单栏。"
                    : output
                NSApplication.shared.terminate(nil)
            case .failure(let error):
                self?.showError(title: "米遥没有启动", message: error.localizedDescription)
                self?.refresh()
            }
        }
    }

    private func prepareCodex() {
        guard let context = MiAoInstallationContext.load(), context.isValid else {
            showError(title: "缺少启动脚本", message: "请从本地项目目录重新运行 ./scripts/setup.sh。")
            return
        }
        let snapshot = inspector.codexSnapshot()
        if snapshot.isRunning && !snapshot.compatibilityEnabled {
            let alert = NSAlert()
            alert.messageText = "需要重启一次 Codex"
            alert.informativeText =
                "这只为下一次 Codex 进程加入官方 Chromium 辅助功能参数，不修改偏好设置。请先确认当前 Codex 工作已经可以安全重启。"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "重启并准备")
            alert.addButton(withTitle: "稍后")
            guard alert.runModal() == .alertFirstButtonReturn else { return }
        }
        let arguments = snapshot.isRunning ? ["enable", "--restart"] : ["enable"]
        runScript(
            context.codexAccessibilityScriptURL,
            arguments: arguments,
            progress: "正在准备 Codex 输入区…"
        ) { [weak self] result in
            if case .failure(let error) = result {
                self?.showError(title: "Codex 准备失败", message: error.localizedDescription)
            }
            self?.refresh()
        }
    }

    private func repairAccessibilityAuthorization() {
        let options =
            [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
            as CFDictionary
        if AXIsProcessTrustedWithOptions(options) {
            refresh()
            return
        }

        let alert = NSAlert()
        alert.messageText = "请重新添加当前米遥 App"
        alert.informativeText =
            "源码版更新后 ad-hoc 签名会变化。系统设置里即使旧“米遥”仍显示开启，也不代表当前构建已获授权。请选中旧“米遥”并移除，再点击“+”添加 Finder 中显示的当前 App。向导会自动刷新，无需重启。"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "打开设置并显示 App")
        alert.addButton(withTitle: "取消")
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
        openPrivacyPane(anchor: "Privacy_Accessibility")
        scheduleRefresh()
    }

    private func runSetupRepair() {
        guard let context = MiAoInstallationContext.load(), context.isValid else {
            showError(title: "启动组件损坏", message: "请从项目目录重新运行 ./scripts/setup.sh 恢复 App。")
            return
        }
        let alert = NSAlert()
        alert.messageText = "修复本地语音引擎"
        alert.informativeText = "将使用 App 内置组件安装缺失的 whisper.cpp 或语音模型，不会覆盖 App，也不会删除录音和配置。"
        alert.addButton(withTitle: "开始修复")
        alert.addButton(withTitle: "取消")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        runScript(
            context.setupScriptURL,
            arguments: [],
            progress: "正在修复安装，这可能需要几分钟…"
        ) { [weak self] result in
            if case .failure(let error) = result {
                self?.showError(title: "修复失败", message: error.localizedDescription)
            }
            self?.refresh()
        }
    }

    private func runScript(
        _ scriptURL: URL,
        arguments: [String],
        progress: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard process == nil else { return }
        let logURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("mi-ao-gui-\(UUID().uuidString).log")
        FileManager.default.createFile(atPath: logURL.path, contents: nil)
        guard let logHandle = try? FileHandle(forWritingTo: logURL) else {
            completion(.failure(BridgeError.configuration("无法创建临时运行日志")))
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = [scriptURL.path] + arguments
        process.currentDirectoryURL = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
        var environment = ProcessInfo.processInfo.environment
        environment["MI_AO_APP_BUNDLE"] = Bundle.main.bundleURL.path
        process.environment = environment
        process.standardOutput = logHandle
        process.standardError = logHandle
        self.process = process
        summaryLabel.stringValue = progress
        startButton.isEnabled = false
        refreshButton.isEnabled = false

        process.terminationHandler = { [weak self] terminated in
            try? logHandle.close()
            let data = (try? Data(contentsOf: logURL)) ?? Data()
            try? FileManager.default.removeItem(at: logURL)
            let output =
                String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            DispatchQueue.main.async {
                self?.process = nil
                if terminated.terminationStatus == 0 {
                    completion(.success(output))
                } else {
                    let message =
                        output.isEmpty
                        ? "脚本退出码：\(terminated.terminationStatus)"
                        : output
                    completion(.failure(BridgeError.configuration(message)))
                }
            }
        }
        do {
            try process.run()
        } catch {
            self.process = nil
            try? logHandle.close()
            try? FileManager.default.removeItem(at: logURL)
            completion(.failure(error))
            refresh()
        }
    }

    private func openPrivacyPane(anchor: String) {
        guard
            let url = URL(
                string: "x-apple.systempreferences:com.apple.preference.security?\(anchor)"
            )
        else { return }
        NSWorkspace.shared.open(url)
    }

    private func openBluetoothSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.BluetoothSettings")
        else { return }
        NSWorkspace.shared.open(url)
    }

    private func scheduleRefresh() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.refresh()
        }
    }

    private func startAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) {
            [weak self] _ in
            guard self?.window?.isVisible == true else { return }
            self?.refresh()
        }
        refreshTimer?.tolerance = 0.25
    }

    private func showError(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }
}

private final class BluetoothAuthorizationRequester: NSObject, CBCentralManagerDelegate {
    private let completion: () -> Void
    private var manager: CBCentralManager?

    init(completion: @escaping () -> Void) {
        self.completion = completion
    }

    func start() {
        manager = CBCentralManager(
            delegate: self,
            queue: .main,
            options: [CBCentralManagerOptionShowPowerAlertKey: false]
        )
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        completion()
        if CBManager.authorization != .notDetermined {
            manager = nil
        }
    }
}
