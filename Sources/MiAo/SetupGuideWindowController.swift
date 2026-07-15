// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import AppKit
import ApplicationServices
@preconcurrency import CoreBluetooth
import Foundation

private enum SetupInterfaceStyle {
    static func applySurface(to view: NSView, radius: CGFloat = 20, emphasized: Bool = false) {
        view.wantsLayer = true
        view.layer?.cornerRadius = radius
        view.layer?.masksToBounds = true
        view.layer?.backgroundColor =
            NSColor.labelColor.withAlphaComponent(emphasized ? 0.10 : 0.075).cgColor
        view.layer?.borderWidth = 1
        view.layer?.borderColor = NSColor.labelColor.withAlphaComponent(0.055).cgColor
    }

    static func applyActionStyle(to button: NSButton, primary: Bool, compact: Bool = false) {
        button.isBordered = true
        button.bezelStyle = .rounded
        button.controlSize = compact ? .small : .regular
        button.font = .systemFont(ofSize: compact ? 12 : 13, weight: .semibold)
        button.bezelColor = primary ? .controlAccentColor : nil
        button.contentTintColor = primary ? .white : nil
    }

    static func requirementColors(_ requirement: SetupRequirement) -> (text: NSColor, fill: NSColor) {
        switch requirement {
        case .required:
            return (.systemBlue, NSColor.systemBlue.withAlphaComponent(0.13))
        case .featureRequired:
            return (.systemOrange, NSColor.systemOrange.withAlphaComponent(0.14))
        case .optional:
            return (.secondaryLabelColor, NSColor.labelColor.withAlphaComponent(0.08))
        }
    }
}

private class FlippedLayoutView: NSView {
    override var isFlipped: Bool { true }
}

private final class SetupToggleRowView: NSView {
    init(title: String, detail: String, toggle: NSSwitch) {
        super.init(frame: .zero)
        SetupInterfaceStyle.applySurface(to: self, radius: 18)

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)

        let detailLabel = NSTextField(wrappingLabelWithString: detail)
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.font = .systemFont(ofSize: 11)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.maximumNumberOfLines = 2

        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.controlSize = .regular
        toggle.setAccessibilityLabel(title)

        addSubview(titleLabel)
        addSubview(detailLabel)
        addSubview(toggle)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 72),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 15),
            titleLabel.trailingAnchor.constraint(equalTo: toggle.leadingAnchor, constant: -16),
            detailLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            detailLabel.trailingAnchor.constraint(equalTo: toggle.leadingAnchor, constant: -16),
            detailLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -13),
            toggle.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            toggle.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }
}

private final class SetupCheckRowView: NSView {
    private let iconPlate = NSView()
    private let iconView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let requirementLabel = NSTextField(labelWithString: "")
    private let detailLabel = NSTextField(wrappingLabelWithString: "")
    private let actionButton = NSButton()
    private var actionWidthConstraint: NSLayoutConstraint!

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        SetupInterfaceStyle.applySurface(to: self, radius: 20)

        iconPlate.translatesAutoresizingMaskIntoConstraints = false
        iconPlate.wantsLayer = true
        iconPlate.layer?.cornerRadius = 20
        iconPlate.layer?.masksToBounds = true

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        iconView.contentTintColor = .secondaryLabelColor

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)

        requirementLabel.translatesAutoresizingMaskIntoConstraints = false
        requirementLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        requirementLabel.alignment = .center
        requirementLabel.wantsLayer = true
        requirementLabel.layer?.cornerRadius = 12
        requirementLabel.layer?.masksToBounds = true

        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.font = .systemFont(ofSize: 12)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.maximumNumberOfLines = 2

        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.isHidden = true
        actionButton.setAccessibilityIdentifier("setup-check-action")

        addSubview(iconPlate)
        iconPlate.addSubview(iconView)
        addSubview(titleLabel)
        addSubview(requirementLabel)
        addSubview(detailLabel)
        addSubview(actionButton)

        actionWidthConstraint = actionButton.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 88),
            iconPlate.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            iconPlate.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconPlate.widthAnchor.constraint(equalToConstant: 40),
            iconPlate.heightAnchor.constraint(equalToConstant: 40),
            iconView.centerXAnchor.constraint(equalTo: iconPlate.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconPlate.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),
            titleLabel.leadingAnchor.constraint(equalTo: iconPlate.trailingAnchor, constant: 14),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: requirementLabel.leadingAnchor,
                constant: -8
            ),
            requirementLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            requirementLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            requirementLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: actionButton.leadingAnchor,
                constant: -10
            ),
            requirementLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 54),
            requirementLabel.heightAnchor.constraint(equalToConstant: 24),
            detailLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            detailLabel.trailingAnchor.constraint(equalTo: actionButton.leadingAnchor, constant: -12),
            detailLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -15),
            actionButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            actionButton.centerYAnchor.constraint(equalTo: iconPlate.centerYAnchor),
            actionButton.heightAnchor.constraint(equalToConstant: 34),
            actionWidthConstraint,
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func update(check: SetupCheck, target: AnyObject, action: Selector) {
        titleLabel.stringValue = check.title
        detailLabel.stringValue = check.detail
        requirementLabel.stringValue = check.requirement.title
        let requirementColors = SetupInterfaceStyle.requirementColors(check.requirement)
        requirementLabel.textColor = requirementColors.text
        requirementLabel.layer?.backgroundColor = requirementColors.fill.cgColor
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
        iconPlate.layer?.backgroundColor = color.withAlphaComponent(0.14).cgColor

        if let actionTitle = check.actionTitle, check.action != nil {
            actionButton.title = actionTitle
            actionButton.target = target
            actionButton.action = action
            actionButton.identifier = NSUserInterfaceItemIdentifier(check.id.rawValue)
            actionButton.isHidden = false
            actionWidthConstraint.constant = 116
            SetupInterfaceStyle.applyActionStyle(to: actionButton, primary: false, compact: true)
        } else {
            actionButton.isHidden = true
            actionButton.identifier = nil
            actionWidthConstraint.constant = 0
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
    private let automaticSubmitCheckbox = NSSwitch()
    private let buttonControlCheckbox = NSSwitch()
    private let loginAtStartupCheckbox = NSSwitch()
    private let openLoginItemsButton = NSButton(title: "打开登录项设置", target: nil, action: nil)
    private let refreshButton = NSButton(title: "重新检查", target: nil, action: nil)
    private let startButton = NSButton(title: "连接遥控器并开始", target: nil, action: nil)
    private let pageTabs = NSTabViewController()
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
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 780),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "米遥设置向导"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.backgroundColor = .windowBackgroundColor
        window.minSize = NSSize(width: 660, height: 720)
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

        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        let heroView = buildHeroView()
        heroView.translatesAutoresizingMaskIntoConstraints = false
        let overviewView = buildOverviewView()

        let checksStack = NSStackView(
            views: SetupCheckID.allCases.compactMap { rows[$0] }
        )
        checksStack.orientation = .vertical
        checksStack.alignment = .leading
        checksStack.spacing = 10

        let preferencesView = buildPreferencesView()
        let buttonGuideView = buildButtonGuideView()

        let checksHeader = buildSectionHeader(
            title: "设备与权限检查",
            detail: "只需处理标注为“必须”或“当前功能必需”的项目。"
        )
        let checksSection = NSStackView(views: [checksHeader, checksStack])
        checksSection.orientation = .vertical
        checksSection.alignment = .leading
        checksSection.spacing = 12
        checksHeader.widthAnchor.constraint(equalTo: checksSection.widthAnchor).isActive = true
        checksStack.widthAnchor.constraint(equalTo: checksSection.widthAnchor).isActive = true

        pageTabs.tabStyle = .segmentedControlOnTop
        pageTabs.transitionOptions = []
        pageTabs.canPropagateSelectedChildViewControllerTitle = false
        pageTabs.addChild(makeTabPage(title: "开始", content: overviewView))
        pageTabs.addChild(makeTabPage(title: "权限与连接", content: checksSection))
        pageTabs.addChild(makeTabPage(title: "控制偏好", content: preferencesView))
        pageTabs.addChild(makeTabPage(title: "按键指南", content: buttonGuideView))
        pageTabs.view.translatesAutoresizingMaskIntoConstraints = false
        pageTabs.view.setAccessibilityLabel("米遥设置分类")

        summaryLabel.font = .systemFont(ofSize: 12, weight: .medium)
        summaryLabel.textColor = .secondaryLabelColor
        let summaryView = NSView()
        summaryView.translatesAutoresizingMaskIntoConstraints = false
        SetupInterfaceStyle.applySurface(to: summaryView, radius: 16)
        let summaryIcon = NSImageView()
        summaryIcon.translatesAutoresizingMaskIntoConstraints = false
        summaryIcon.image = NSImage(systemSymbolName: "info.circle.fill", accessibilityDescription: nil)
        summaryIcon.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        summaryIcon.contentTintColor = .secondaryLabelColor
        summaryLabel.translatesAutoresizingMaskIntoConstraints = false
        summaryView.addSubview(summaryIcon)
        summaryView.addSubview(summaryLabel)
        NSLayoutConstraint.activate([
            summaryView.heightAnchor.constraint(greaterThanOrEqualToConstant: 52),
            summaryIcon.leadingAnchor.constraint(equalTo: summaryView.leadingAnchor, constant: 17),
            summaryIcon.centerYAnchor.constraint(equalTo: summaryView.centerYAnchor),
            summaryIcon.widthAnchor.constraint(equalToConstant: 18),
            summaryIcon.heightAnchor.constraint(equalToConstant: 18),
            summaryLabel.leadingAnchor.constraint(equalTo: summaryIcon.trailingAnchor, constant: 10),
            summaryLabel.trailingAnchor.constraint(equalTo: summaryView.trailingAnchor, constant: -17),
            summaryLabel.topAnchor.constraint(equalTo: summaryView.topAnchor, constant: 13),
            summaryLabel.bottomAnchor.constraint(equalTo: summaryView.bottomAnchor, constant: -13),
        ])

        refreshButton.target = self
        refreshButton.action = #selector(refreshPressed)
        refreshButton.setAccessibilityLabel("重新检查环境")

        startButton.target = self
        startButton.action = #selector(startPressed)
        startButton.keyEquivalent = "\r"
        startButton.setAccessibilityLabel("连接遥控器并开始")

        let buttonSpacer = NSView()
        let buttons = NSStackView(views: [refreshButton, buttonSpacer, startButton])
        buttons.orientation = .horizontal
        buttons.alignment = .centerY
        buttons.spacing = 12

        buttons.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(heroView)
        contentView.addSubview(pageTabs.view)
        contentView.addSubview(summaryView)
        contentView.addSubview(buttons)

        let rowWidthConstraints = SetupCheckID.allCases.compactMap { rows[$0] }.map {
            $0.widthAnchor.constraint(equalTo: checksStack.widthAnchor)
        }

        NSLayoutConstraint.activate(
            [
                heroView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
                heroView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -28),
                heroView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 22),
                pageTabs.view.leadingAnchor.constraint(equalTo: heroView.leadingAnchor),
                pageTabs.view.trailingAnchor.constraint(equalTo: heroView.trailingAnchor),
                pageTabs.view.topAnchor.constraint(equalTo: heroView.bottomAnchor, constant: 18),
                pageTabs.view.bottomAnchor.constraint(equalTo: summaryView.topAnchor, constant: -18),
                summaryView.leadingAnchor.constraint(equalTo: heroView.leadingAnchor),
                summaryView.trailingAnchor.constraint(equalTo: heroView.trailingAnchor),
                buttons.leadingAnchor.constraint(equalTo: heroView.leadingAnchor),
                buttons.trailingAnchor.constraint(equalTo: heroView.trailingAnchor),
                buttons.topAnchor.constraint(equalTo: summaryView.bottomAnchor, constant: 12),
                buttons.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -22),
                buttonSpacer.widthAnchor.constraint(greaterThanOrEqualToConstant: 1),
                refreshButton.widthAnchor.constraint(equalToConstant: 124),
                refreshButton.heightAnchor.constraint(equalToConstant: 44),
                startButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 202),
                startButton.heightAnchor.constraint(equalToConstant: 44),
            ] + rowWidthConstraints)
    }

    private func makeTabPage(title: String, content: NSView) -> NSViewController {
        let controller = NSViewController()
        controller.title = title

        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay

        let documentView = FlippedLayoutView()
        documentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = documentView
        content.translatesAutoresizingMaskIntoConstraints = false
        documentView.addSubview(content)
        NSLayoutConstraint.activate([
            documentView.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor),
            content.leadingAnchor.constraint(equalTo: documentView.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: documentView.trailingAnchor),
            content.topAnchor.constraint(equalTo: documentView.topAnchor, constant: 12),
            content.bottomAnchor.constraint(equalTo: documentView.bottomAnchor, constant: -12),
        ])
        controller.view = scrollView
        return controller
    }

    private func buildOverviewView() -> NSView {
        let sectionHeader = buildSectionHeader(
            title: "三步开始使用",
            detail: "先选好使用方式，再完成有标记的检查；检查通过前，米遥不会修改系统按键映射。"
        )

        let stepsCard = NSView()
        SetupInterfaceStyle.applySurface(to: stepsCard, radius: 22, emphasized: true)
        let steps = NSStackView(
            views: [
                buildOverviewStep(
                    number: "01",
                    title: "选择使用方式",
                    detail: "在“控制偏好”中决定是否自动发送到 Codex 与启用遥控器按键控制。"
                ),
                buildOverviewStep(
                    number: "02",
                    title: "完成必要检查并连接遥控器",
                    detail: "在“权限与连接”处理橙色项目，并确认小米蓝牙遥控器 2 Pro 已连接。"
                ),
                buildOverviewStep(
                    number: "03",
                    title: "启动后按住说话，松开提交",
                    detail: "环境就绪后点击下方主按钮；之后可随时在菜单栏打开设置与诊断。"
                ),
            ]
        )
        steps.translatesAutoresizingMaskIntoConstraints = false
        steps.orientation = .vertical
        steps.alignment = .leading
        steps.spacing = 16
        stepsCard.addSubview(steps)
        let arrangedSteps = steps.arrangedSubviews
        arrangedSteps.forEach {
            $0.widthAnchor.constraint(equalTo: steps.widthAnchor).isActive = true
        }
        NSLayoutConstraint.activate([
            steps.leadingAnchor.constraint(equalTo: stepsCard.leadingAnchor, constant: 22),
            steps.trailingAnchor.constraint(equalTo: stepsCard.trailingAnchor, constant: -22),
            steps.topAnchor.constraint(equalTo: stepsCard.topAnchor, constant: 22),
            steps.bottomAnchor.constraint(equalTo: stepsCard.bottomAnchor, constant: -22),
        ])

        let continueButton = NSButton(
            title: "下一步：选择使用方式",
            target: self,
            action: #selector(showControlPreferences)
        )
        continueButton.setAccessibilityLabel("前往控制偏好")
        SetupInterfaceStyle.applyActionStyle(to: continueButton, primary: true)

        let stack = NSStackView(views: [sectionHeader, stepsCard, continueButton])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        sectionHeader.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        stepsCard.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        continueButton.heightAnchor.constraint(equalToConstant: 34).isActive = true
        return stack
    }

    private func buildOverviewStep(number: String, title: String, detail: String) -> NSView {
        let numberLabel = NSTextField(labelWithString: number)
        numberLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .bold)
        numberLabel.textColor = .controlAccentColor

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)

        let titleRow = NSStackView(views: [numberLabel, titleLabel])
        titleRow.orientation = .horizontal
        titleRow.alignment = .firstBaseline
        titleRow.spacing = 8

        let detailLabel = NSTextField(wrappingLabelWithString: detail)
        detailLabel.font = .systemFont(ofSize: 12)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.maximumNumberOfLines = 2

        let step = NSStackView(views: [titleRow, detailLabel])
        step.orientation = .vertical
        step.alignment = .leading
        step.spacing = 4
        titleRow.widthAnchor.constraint(equalTo: step.widthAnchor).isActive = true
        detailLabel.widthAnchor.constraint(equalTo: step.widthAnchor).isActive = true
        return step
    }

    private func buildButtonGuideView() -> NSView {
        let sectionHeader = buildSectionHeader(
            title: "按键指南",
            detail: "默认 pointer 预设已经写入 App。TV 只切换方向环；其余按钮在两种模式下保持相同。"
        )

        let guideCard = NSView()
        SetupInterfaceStyle.applySurface(to: guideCard, radius: 22, emphasized: true)

        let imageView = NSImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageAlignment = .alignCenter
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.setAccessibilityLabel("小米蓝牙遥控器 2 Pro 的米遥按键映射图")
        let imageURL = Bundle.main.resourceURL?
            .appendingPathComponent("Brand/mi-ao-button-map.png")
        imageView.image = imageURL.flatMap(NSImage.init(contentsOf:))

        let caption = NSTextField(
            wrappingLabelWithString: "向下滚动查看完整示意图。确认始终是 Return，返回始终是 Escape；菜单键保留 macOS 原生鼠标右键。"
        )
        caption.translatesAutoresizingMaskIntoConstraints = false
        caption.font = .systemFont(ofSize: 12)
        caption.textColor = .secondaryLabelColor
        caption.alignment = .center
        caption.maximumNumberOfLines = 2

        guideCard.addSubview(imageView)
        guideCard.addSubview(caption)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: guideCard.topAnchor, constant: 18),
            imageView.centerXAnchor.constraint(equalTo: guideCard.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 420),
            imageView.heightAnchor.constraint(equalToConstant: 560),
            caption.leadingAnchor.constraint(equalTo: guideCard.leadingAnchor, constant: 22),
            caption.trailingAnchor.constraint(equalTo: guideCard.trailingAnchor, constant: -22),
            caption.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
            caption.bottomAnchor.constraint(equalTo: guideCard.bottomAnchor, constant: -18),
        ])

        let stack = NSStackView(views: [sectionHeader, guideCard])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        sectionHeader.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        guideCard.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        return stack
    }

    private func buildPreferencesView() -> NSView {
        let sectionHeader = buildSectionHeader(
            title: "使用方式",
            detail: "开关只影响对应功能；关闭后，相关系统授权会立即变为可选。"
        )

        automaticSubmitCheckbox.target = self
        automaticSubmitCheckbox.action = #selector(preferencesChanged)
        buttonControlCheckbox.target = self
        buttonControlCheckbox.action = #selector(preferencesChanged)
        loginAtStartupCheckbox.target = self
        loginAtStartupCheckbox.action = #selector(loginItemChanged)

        openLoginItemsButton.target = self
        openLoginItemsButton.action = #selector(openLoginItemsSettings)
        openLoginItemsButton.setAccessibilityLabel("打开 macOS 登录项设置")
        openLoginItemsButton.isHidden = true
        SetupInterfaceStyle.applyActionStyle(to: openLoginItemsButton, primary: false, compact: true)

        loginItemStateLabel.font = .systemFont(ofSize: 11)
        loginItemStateLabel.textColor = .secondaryLabelColor
        preferenceStateLabel.font = .systemFont(ofSize: 11)
        preferenceStateLabel.textColor = .systemOrange

        let automaticSubmitRow = SetupToggleRowView(
            title: "自动发送到 Codex",
            detail: "松开语音键后，转写内容会自动粘贴并发送。",
            toggle: automaticSubmitCheckbox
        )
        let buttonControlRow = SetupToggleRowView(
            title: "遥控器按键控制",
            detail: "用方向、音量和常用键操作 Codex 与指针。",
            toggle: buttonControlCheckbox
        )
        let loginRow = SetupToggleRowView(
            title: "登录后自动启动",
            detail: "可选。不启用也可随时从“应用程序”打开米遥。",
            toggle: loginAtStartupCheckbox
        )
        let loginStateSpacer = NSView()
        let loginStateRow = NSStackView(
            views: [loginItemStateLabel, loginStateSpacer, openLoginItemsButton]
        )
        loginStateRow.orientation = .horizontal
        loginStateRow.alignment = .centerY
        loginStateRow.spacing = 8
        loginStateSpacer.widthAnchor.constraint(greaterThanOrEqualToConstant: 1).isActive = true

        let preferenceViews: [NSView] = [
            sectionHeader,
            automaticSubmitRow,
            buttonControlRow,
            loginRow,
            loginStateRow,
            preferenceStateLabel,
        ]
        let stack = NSStackView(views: preferenceViews)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        preferenceViews.forEach {
            $0.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        }

        return stack
    }

    private func buildHeroView() -> NSView {
        let hero = NSVisualEffectView()
        hero.material = .headerView
        hero.blendingMode = .withinWindow
        hero.state = .active
        hero.wantsLayer = true
        hero.layer?.cornerRadius = 26
        hero.layer?.masksToBounds = true
        hero.layer?.borderWidth = 1
        hero.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.65).cgColor

        let eyebrow = NSTextField(labelWithString: "米遥 · 设置向导")
        eyebrow.translatesAutoresizingMaskIntoConstraints = false
        eyebrow.font = .systemFont(ofSize: 12, weight: .semibold)
        eyebrow.textColor = .controlAccentColor

        let title = NSTextField(labelWithString: "让米遥在这台 Mac 上就绪")
        title.translatesAutoresizingMaskIntoConstraints = false
        title.font = .systemFont(ofSize: 25, weight: .bold)

        let subtitle = NSTextField(
            wrappingLabelWithString: "权限只在当前功能真正需要时才请求。完成必要项后，就可以按住遥控器说话，让 Codex 干活。"
        )
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.font = .systemFont(ofSize: 12)
        subtitle.textColor = .secondaryLabelColor
        subtitle.maximumNumberOfLines = 2

        let copy = NSStackView(views: [eyebrow, title, subtitle])
        copy.translatesAutoresizingMaskIntoConstraints = false
        copy.orientation = .vertical
        copy.alignment = .leading
        copy.spacing = 6
        hero.addSubview(copy)

        NSLayoutConstraint.activate([
            hero.heightAnchor.constraint(equalToConstant: 116),
            copy.leadingAnchor.constraint(equalTo: hero.leadingAnchor, constant: 24),
            copy.trailingAnchor.constraint(equalTo: hero.trailingAnchor, constant: -24),
            copy.topAnchor.constraint(equalTo: hero.topAnchor, constant: 18),
            copy.bottomAnchor.constraint(equalTo: hero.bottomAnchor, constant: -18),
        ])
        return hero
    }

    private func buildSectionHeader(title: String, detail: String) -> NSView {
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 17, weight: .bold)
        let detailLabel = NSTextField(wrappingLabelWithString: detail)
        detailLabel.font = .systemFont(ofSize: 12)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.maximumNumberOfLines = 2
        let stack = NSStackView(views: [titleLabel, detailLabel])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        return stack
    }

    @objc private func refreshPressed() {
        refresh()
    }

    @objc private func showControlPreferences() {
        pageTabs.selectedTabViewItemIndex = 2
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
            let remainingCount = report.checks.filter {
                $0.requirement.blocksStart && $0.state != .ready
            }.count
            summaryLabel.stringValue =
                "还差 \(remainingCount) 项必要检查；请在“权限与连接”页处理橙色项目。米遥在检查通过前不会修改系统按键映射。"
            startButton.title = "完成上方设置后开始"
            startButton.isEnabled = false
        }
        refreshButton.isEnabled = process == nil
        SetupInterfaceStyle.applyActionStyle(to: refreshButton, primary: false)
        SetupInterfaceStyle.applyActionStyle(to: startButton, primary: true)
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
            loginAtStartupCheckbox.isEnabled = true
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
