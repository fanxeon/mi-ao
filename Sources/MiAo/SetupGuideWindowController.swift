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

private final class ShortcutRecorderView: NSView {
    var recordedShortcut: KeyboardShortcutSpec?

    private let prompt = NSTextField(wrappingLabelWithString: "")

    override var acceptsFirstResponder: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 12
        layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.10).cgColor

        prompt.translatesAutoresizingMaskIntoConstraints = false
        prompt.font = .systemFont(ofSize: 13, weight: .medium)
        prompt.alignment = .center
        prompt.textColor = .secondaryLabelColor
        prompt.stringValue = "请按下要发送的按键组合"
        addSubview(prompt)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 320),
            heightAnchor.constraint(equalToConstant: 74),
            prompt.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            prompt.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            prompt.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        var modifiers: Set<ShortcutModifier> = []
        if event.modifierFlags.contains(.command) { modifiers.insert(.command) }
        if event.modifierFlags.contains(.option) { modifiers.insert(.option) }
        if event.modifierFlags.contains(.shift) { modifiers.insert(.shift) }
        if event.modifierFlags.contains(.control) { modifiers.insert(.control) }
        let keyLabel = event.charactersIgnoringModifiers?.uppercased() ?? "Key \(event.keyCode)"
        do {
            recordedShortcut = try KeyboardShortcutSpec(
                keyCode: event.keyCode,
                modifiers: modifiers,
                keyLabel: keyLabel
            )
            prompt.stringValue = "已记录：\(recordedShortcut?.displayName ?? "")"
            prompt.textColor = .controlAccentColor
        } catch {
            recordedShortcut = nil
            prompt.stringValue = error.localizedDescription
            prompt.textColor = .systemRed
        }
    }
}

private final class ButtonMappingRowView: NSView {
    private enum Choice {
        static let shortcut = "shortcut"
        static let presetSwitch = "preset_switch"
        static let actionPrefix = "action:"
    }

    let button: RemoteButton
    var onBindingChanged: ((ButtonBinding) -> Void)?
    var onShortcutRequested: (() -> Void)?

    private let titleLabel = NSTextField(labelWithString: "")
    private let detailLabel = NSTextField(wrappingLabelWithString: "")
    private let actionPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let targetLabel = NSTextField(labelWithString: "TV 切换至")
    private let targetPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let targetRow = NSStackView()
    private var currentBinding: ButtonBinding = .action(.unmapped)

    init(button: RemoteButton) {
        self.button = button
        super.init(frame: .zero)
        SetupInterfaceStyle.applySurface(to: self, radius: 18)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.stringValue = button.displayName

        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.font = .systemFont(ofSize: 11)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.maximumNumberOfLines = 2

        actionPopup.translatesAutoresizingMaskIntoConstraints = false
        actionPopup.target = self
        actionPopup.action = #selector(actionChanged)
        actionPopup.setAccessibilityLabel("\(button.displayName) 的动作")

        targetLabel.font = .systemFont(ofSize: 11, weight: .medium)
        targetLabel.textColor = .secondaryLabelColor
        targetPopup.target = self
        targetPopup.action = #selector(targetChanged)
        targetPopup.setAccessibilityLabel("TV 的目标配置")
        targetRow.orientation = .horizontal
        targetRow.alignment = .centerY
        targetRow.spacing = 8
        targetRow.translatesAutoresizingMaskIntoConstraints = false
        targetRow.addArrangedSubview(targetLabel)
        targetRow.addArrangedSubview(targetPopup)
        targetRow.isHidden = true

        addSubview(titleLabel)
        addSubview(detailLabel)
        addSubview(actionPopup)
        addSubview(targetRow)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 76),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 15),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: actionPopup.leadingAnchor, constant: -14),
            actionPopup.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            actionPopup.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            actionPopup.widthAnchor.constraint(equalToConstant: 248),
            detailLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            detailLabel.trailingAnchor.constraint(equalTo: actionPopup.trailingAnchor),
            targetRow.leadingAnchor.constraint(equalTo: detailLabel.leadingAnchor),
            targetRow.topAnchor.constraint(equalTo: detailLabel.bottomAnchor, constant: 8),
            targetRow.trailingAnchor.constraint(lessThanOrEqualTo: actionPopup.trailingAnchor),
            targetRow.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -13),
            detailLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -13),
            targetPopup.widthAnchor.constraint(equalToConstant: 200),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func update(
        binding: ButtonBinding,
        targetPresets: [ButtonPreset],
        editable: Bool
    ) {
        currentBinding = binding
        actionPopup.removeAllItems()
        for action in availableActions {
            addActionItem(action)
        }
        if button.isUserEditable {
            actionPopup.menu?.addItem(.separator())
            addItem(title: "录制自定义快捷键…", identifier: Choice.shortcut)
        }
        if button == .tv {
            actionPopup.menu?.addItem(.separator())
            let switchItem = NSMenuItem(title: "切换到另一配置", action: nil, keyEquivalent: "")
            switchItem.representedObject = Choice.presetSwitch
            switchItem.isEnabled = !targetPresets.isEmpty
            actionPopup.menu?.addItem(switchItem)
        }

        targetPopup.removeAllItems()
        for target in targetPresets {
            let item = NSMenuItem(title: target.name, action: nil, keyEquivalent: "")
            item.representedObject = target.id
            targetPopup.menu?.addItem(item)
        }

        let selectedIdentifier: String
        switch binding {
        case .action(let action):
            selectedIdentifier = Choice.actionPrefix + action.rawValue
            detailLabel.stringValue = action.displayName
        case .keyboardShortcut(let shortcut):
            selectedIdentifier = Choice.shortcut
            detailLabel.stringValue = "将发送 \(shortcut.displayName)；再次选择“录制自定义快捷键”可更换。"
        case .presetSwitch(let targetID):
            selectedIdentifier = Choice.presetSwitch
            detailLabel.stringValue = "按下 TV 会立即切换整个配置，其他按钮随之改变。"
            selectTarget(id: targetID)
        }
        selectAction(identifier: selectedIdentifier)
        targetRow.isHidden = button != .tv || selectedIdentifier != Choice.presetSwitch
        actionPopup.isEnabled = editable
        targetPopup.isEnabled = editable && !targetPresets.isEmpty
        alphaValue = editable ? 1 : 0.72
    }

    private var availableActions: [ButtonAction] {
        let common: [ButtonAction] = [
            .keyboardReturn,
            .keyboardEscape,
            .keyboardPageUp,
            .keyboardPageDown,
            .codexFocus,
            .codexLaunchOrFocus,
            .codexPreviousTask,
            .codexNextTask,
            .unmapped,
        ]
        switch button {
        case .dpadUp:
            return [.pointerMoveUp, .keyboardArrowUp, .pointerScrollUp] + common
        case .dpadDown:
            return [.pointerMoveDown, .keyboardArrowDown, .pointerScrollDown] + common
        case .dpadLeft:
            return [.pointerMoveLeft, .keyboardArrowLeft] + common
        case .dpadRight:
            return [.pointerMoveRight, .keyboardArrowRight] + common
        case .home:
            return [.homePageNavigation] + common
        case .tv:
            return [.modeTogglePointerDirectional] + common
        case .voice:
            return [.voicePushToTalk]
        case .menu:
            return [.unmapped]
        case .center, .back, .volumeUp, .volumeDown, .power:
            return common
        }
    }

    private func addActionItem(_ action: ButtonAction) {
        addItem(title: action.displayName, identifier: Choice.actionPrefix + action.rawValue)
    }

    private func addItem(title: String, identifier: String) {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.representedObject = identifier
        actionPopup.menu?.addItem(item)
    }

    private func selectAction(identifier: String) {
        guard let menu = actionPopup.menu else { return }
        let index = menu.items.firstIndex { ($0.representedObject as? String) == identifier }
        actionPopup.selectItem(at: index ?? 0)
    }

    private func selectTarget(id: String) {
        guard let menu = targetPopup.menu else { return }
        let index = menu.items.firstIndex { ($0.representedObject as? String) == id }
        targetPopup.selectItem(at: index ?? 0)
    }

    @objc private func actionChanged() {
        guard let identifier = actionPopup.selectedItem?.representedObject as? String else { return }
        if identifier == Choice.shortcut {
            onShortcutRequested?()
            return
        }
        if identifier == Choice.presetSwitch {
            guard let targetID = targetPopup.selectedItem?.representedObject as? String else { return }
            onBindingChanged?(.presetSwitch(targetID))
            return
        }
        guard let rawValue = identifier.stripPrefix(Choice.actionPrefix),
            let action = ButtonAction(rawValue: rawValue)
        else { return }
        onBindingChanged?(.action(action))
    }

    @objc private func targetChanged() {
        guard case .presetSwitch = currentBinding,
            let targetID = targetPopup.selectedItem?.representedObject as? String
        else { return }
        onBindingChanged?(.presetSwitch(targetID))
    }
}

private extension String {
    func stripPrefix(_ prefix: String) -> String? {
        guard hasPrefix(prefix) else { return nil }
        return String(dropFirst(prefix.count))
    }
}

final class SetupGuideWindowController: NSWindowController, NSWindowDelegate, NSTextFieldDelegate {
    private let configuration: Configuration
    private let standalone: Bool
    private let preferencesStore: AppPreferencesStore
    private let presetStore: ButtonPresetStore
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
    private let presetPicker = NSPopUpButton(frame: .zero, pullsDown: false)
    private let presetNameField = NSTextField(string: "")
    private let createPresetButton = NSButton(title: "新建", target: nil, action: nil)
    private let duplicatePresetButton = NSButton(title: "复制", target: nil, action: nil)
    private let deletePresetButton = NSButton(title: "删除", target: nil, action: nil)
    private let savePresetButton = NSButton(title: "保存配置", target: nil, action: nil)
    private let presetStateLabel = NSTextField(wrappingLabelWithString: "")
    private var mappingRows: [RemoteButton: ButtonMappingRowView] = [:]
    private var report: SetupEnvironmentReport?
    private var bluetoothRequester: BluetoothAuthorizationRequester?
    private var process: Process?
    private var refreshTimer: Timer?
    private var preferences: AppPreferences
    private var preferencesLoadState: AppPreferencesLoadState
    private var presetCatalog: ButtonPresetCatalog
    private var presetCatalogLoadState: ButtonPresetCatalogLoadState
    private var selectedPresetID: String
    private var draftPreset: ButtonPreset
    private var hasUnsavedPresetChanges = false

    init(
        configuration: Configuration,
        standalone: Bool,
        preferencesStore: AppPreferencesStore = AppPreferencesStore(),
        presetStore: ButtonPresetStore = ButtonPresetStore(),
        loginItemController: LoginItemController = LoginItemController()
    ) {
        self.configuration = configuration
        self.standalone = standalone
        self.preferencesStore = preferencesStore
        self.presetStore = presetStore
        self.loginItemController = loginItemController
        let snapshot = preferencesStore.load()
        preferences = snapshot.preferences
        preferencesLoadState = snapshot.state
        let presetSnapshot = presetStore.load()
        presetCatalog = presetSnapshot.catalog
        presetCatalogLoadState = presetSnapshot.state
        selectedPresetID = snapshot.preferences.selectedPresetID
        if (try? presetSnapshot.catalog.preset(id: selectedPresetID)) == nil {
            selectedPresetID = ButtonPreset.pointer.id
        }
        draftPreset = (try? presetSnapshot.catalog.preset(id: selectedPresetID)) ?? .pointer
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
        let buttonMappingsView = buildButtonMappingsView()
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
        pageTabs.addChild(makeTabPage(title: "按键配置", content: buttonMappingsView))
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

    private func buildButtonMappingsView() -> NSView {
        let sectionHeader = buildSectionHeader(
            title: "按键配置",
            detail: "创建自己的配置并保存。TV 可从当前配置跳转到另一套配置；语音键与菜单键为安全保留项。"
        )

        presetPicker.target = self
        presetPicker.action = #selector(presetSelectionChanged)
        presetPicker.setAccessibilityLabel("当前按键配置")

        presetNameField.placeholderString = "配置名称"
        presetNameField.font = .systemFont(ofSize: 13, weight: .medium)
        presetNameField.delegate = self
        presetNameField.setAccessibilityLabel("按键配置名称")

        createPresetButton.target = self
        createPresetButton.action = #selector(createPreset)
        duplicatePresetButton.target = self
        duplicatePresetButton.action = #selector(duplicatePreset)
        deletePresetButton.target = self
        deletePresetButton.action = #selector(deletePreset)
        savePresetButton.target = self
        savePresetButton.action = #selector(savePreset)
        [createPresetButton, duplicatePresetButton, deletePresetButton, savePresetButton].forEach {
            SetupInterfaceStyle.applyActionStyle(to: $0, primary: $0 === savePresetButton, compact: true)
        }

        let pickerTitle = NSTextField(labelWithString: "当前配置")
        pickerTitle.font = .systemFont(ofSize: 13, weight: .semibold)
        let pickerRow = NSStackView(views: [pickerTitle, presetPicker])
        pickerRow.orientation = .horizontal
        pickerRow.alignment = .centerY
        pickerRow.spacing = 10
        pickerTitle.widthAnchor.constraint(equalToConstant: 66).isActive = true
        presetPicker.widthAnchor.constraint(equalToConstant: 260).isActive = true

        let nameTitle = NSTextField(labelWithString: "名称")
        nameTitle.font = .systemFont(ofSize: 13, weight: .semibold)
        let nameRow = NSStackView(views: [nameTitle, presetNameField])
        nameRow.orientation = .horizontal
        nameRow.alignment = .centerY
        nameRow.spacing = 10
        nameTitle.widthAnchor.constraint(equalToConstant: 66).isActive = true
        presetNameField.widthAnchor.constraint(equalToConstant: 260).isActive = true

        let configurationCard = NSView()
        SetupInterfaceStyle.applySurface(to: configurationCard, radius: 20, emphasized: true)
        let buttonSpacer = NSView()
        let buttonRow = NSStackView(
            views: [createPresetButton, duplicatePresetButton, deletePresetButton, buttonSpacer, savePresetButton]
        )
        buttonRow.orientation = .horizontal
        buttonRow.alignment = .centerY
        buttonRow.spacing = 8
        buttonSpacer.widthAnchor.constraint(greaterThanOrEqualToConstant: 1).isActive = true

        presetStateLabel.font = .systemFont(ofSize: 11)
        presetStateLabel.textColor = .secondaryLabelColor
        presetStateLabel.maximumNumberOfLines = 2

        let configurationStack = NSStackView(
            views: [pickerRow, nameRow, buttonRow, presetStateLabel]
        )
        configurationStack.translatesAutoresizingMaskIntoConstraints = false
        configurationStack.orientation = .vertical
        configurationStack.alignment = .leading
        configurationStack.spacing = 10
        configurationCard.addSubview(configurationStack)
        NSLayoutConstraint.activate([
            configurationStack.leadingAnchor.constraint(equalTo: configurationCard.leadingAnchor, constant: 18),
            configurationStack.trailingAnchor.constraint(equalTo: configurationCard.trailingAnchor, constant: -18),
            configurationStack.topAnchor.constraint(equalTo: configurationCard.topAnchor, constant: 16),
            configurationStack.bottomAnchor.constraint(equalTo: configurationCard.bottomAnchor, constant: -16),
            pickerRow.widthAnchor.constraint(equalTo: configurationStack.widthAnchor),
            nameRow.widthAnchor.constraint(equalTo: configurationStack.widthAnchor),
            buttonRow.widthAnchor.constraint(equalTo: configurationStack.widthAnchor),
            presetStateLabel.widthAnchor.constraint(equalTo: configurationStack.widthAnchor),
        ])

        let retainedLabel = NSTextField(
            wrappingLabelWithString: "保留项：语音键始终用于按住说话；菜单键始终保留 macOS 原生鼠标右键。自定义快捷键只由已校准的目标遥控器触发。"
        )
        retainedLabel.font = .systemFont(ofSize: 11)
        retainedLabel.textColor = .secondaryLabelColor
        retainedLabel.maximumNumberOfLines = 3
        let retainedCard = NSView()
        SetupInterfaceStyle.applySurface(to: retainedCard, radius: 16)
        retainedLabel.translatesAutoresizingMaskIntoConstraints = false
        retainedCard.addSubview(retainedLabel)
        NSLayoutConstraint.activate([
            retainedLabel.leadingAnchor.constraint(equalTo: retainedCard.leadingAnchor, constant: 16),
            retainedLabel.trailingAnchor.constraint(equalTo: retainedCard.trailingAnchor, constant: -16),
            retainedLabel.topAnchor.constraint(equalTo: retainedCard.topAnchor, constant: 12),
            retainedLabel.bottomAnchor.constraint(equalTo: retainedCard.bottomAnchor, constant: -12),
        ])

        let mappingsHeader = buildSectionHeader(
            title: "按钮映射",
            detail: "保存后，所选配置会用于下一次启动；运行中按 TV 切换时会同步记住目标配置。"
        )
        let mappingStack = NSStackView()
        mappingStack.orientation = .vertical
        mappingStack.alignment = .leading
        mappingStack.spacing = 8
        for button in RemoteButton.allCases where button.isUserEditable {
            let row = ButtonMappingRowView(button: button)
            row.onBindingChanged = { [weak self] binding in
                self?.updateDraftBinding(binding, for: button)
            }
            row.onShortcutRequested = { [weak self] in
                self?.recordShortcut(for: button)
            }
            mappingRows[button] = row
            mappingStack.addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: mappingStack.widthAnchor).isActive = true
        }

        let stack = NSStackView(
            views: [sectionHeader, configurationCard, retainedCard, mappingsHeader, mappingStack]
        )
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        [sectionHeader, configurationCard, retainedCard, mappingsHeader, mappingStack].forEach {
            $0.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        }
        refreshPresetEditor()
        return stack
    }

    private func refreshPresetEditor() {
        let allPresets = presetCatalog.allPresets
        presetPicker.removeAllItems()
        for preset in allPresets {
            let item = NSMenuItem(title: preset.name, action: nil, keyEquivalent: "")
            item.representedObject = preset.id
            presetPicker.menu?.addItem(item)
        }
        if let selectedIndex = presetPicker.itemArray.firstIndex(where: {
            ($0.representedObject as? String) == selectedPresetID
        }) {
            presetPicker.selectItem(at: selectedIndex)
        }

        let storageWritable: Bool
        if case .unsupportedVersion = presetCatalogLoadState {
            storageWritable = false
        } else {
            storageWritable = true
        }
        let editable = storageWritable && !draftPreset.isBuiltIn
        presetNameField.stringValue = draftPreset.name
        presetNameField.isEnabled = editable
        duplicatePresetButton.isEnabled = storageWritable
        createPresetButton.isEnabled = storageWritable
        deletePresetButton.isEnabled = editable
        savePresetButton.isEnabled = editable && hasUnsavedPresetChanges
        presetPicker.isEnabled = storageWritable

        let targets = allPresets.filter { $0.id != draftPreset.id }
        for (button, row) in mappingRows {
            row.update(
                binding: draftPreset.binding(for: button),
                targetPresets: targets,
                editable: editable
            )
        }

        switch presetCatalogLoadState {
        case .defaults:
            presetStateLabel.stringValue =
                draftPreset.isBuiltIn
                ? "官方默认配置为只读。点击“新建”或“复制”创建自己的配置。"
                : "新配置尚未写入本地文件。"
        case .loaded:
            if draftPreset.isBuiltIn {
                presetStateLabel.stringValue = "官方默认配置为只读。点击“新建”或“复制”创建自己的配置。"
            } else if hasUnsavedPresetChanges {
                presetStateLabel.stringValue = "有未保存修改。保存后才会用于下一次启动。"
            } else {
                presetStateLabel.stringValue = "已保存到本机私有配置。TV 的切换目标会在运行中立即生效。"
            }
        case .recoveredInvalid(let url):
            presetStateLabel.stringValue = "已隔离损坏配置并恢复默认：\(url.lastPathComponent)"
        case .unsupportedVersion(let version):
            presetStateLabel.stringValue = "检测到较新的按键配置 schema v\(version)，为避免覆盖，当前只读。"
        }
    }

    @objc private func presetSelectionChanged() {
        guard let nextID = presetPicker.selectedItem?.representedObject as? String,
            nextID != selectedPresetID
        else { return }
        if hasUnsavedPresetChanges {
            let alert = NSAlert()
            alert.messageText = "保存当前配置修改？"
            alert.informativeText = "切换配置前，需要决定是否保存当前编辑内容。"
            alert.addButton(withTitle: "保存并切换")
            alert.addButton(withTitle: "放弃修改")
            alert.addButton(withTitle: "取消")
            switch alert.runModal() {
            case .alertFirstButtonReturn:
                guard persistDraft() else {
                    refreshPresetEditor()
                    return
                }
            case .alertSecondButtonReturn:
                break
            default:
                refreshPresetEditor()
                return
            }
        }
        selectPreset(id: nextID)
    }

    @objc private func createPreset() {
        guard prepareForNewPreset() else { return }
        createUserPreset(from: .pointer, name: "新配置")
    }

    @objc private func duplicatePreset() {
        guard prepareForNewPreset() else { return }
        createUserPreset(from: draftPreset, name: "\(draftPreset.name) 副本")
    }

    @objc private func deletePreset() {
        guard !draftPreset.isBuiltIn else { return }
        let alert = NSAlert()
        alert.messageText = "删除“\(draftPreset.name)”？"
        alert.informativeText = "删除后不可恢复。若另一配置的 TV 正在跳转到它，删除会被安全拒绝。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "删除")
        alert.addButton(withTitle: "取消")
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        let remaining = presetCatalog.userPresets.filter { $0.id != draftPreset.id }
        let nextCatalog = ButtonPresetCatalog(userPresets: remaining)
        do {
            try nextCatalog.validate()
            try presetStore.save(nextCatalog)
            presetCatalog = nextCatalog
            presetCatalogLoadState = .loaded
            hasUnsavedPresetChanges = false
            selectPreset(id: ButtonPreset.pointer.id)
        } catch {
            showError(title: "配置没有删除", message: error.localizedDescription)
            refreshPresetEditor()
        }
    }

    @objc private func savePreset() {
        _ = persistDraft()
    }

    func controlTextDidChange(_ obj: Notification) {
        guard obj.object as? NSTextField === presetNameField,
            !draftPreset.isBuiltIn
        else { return }
        draftPreset = ButtonPreset(
            id: draftPreset.id,
            name: presetNameField.stringValue,
            bindings: draftPreset.bindings,
            requiredButtons: draftPreset.requiredButtons,
            isBuiltIn: false
        )
        hasUnsavedPresetChanges = true
        savePresetButton.isEnabled = true
        presetStateLabel.stringValue = "有未保存修改。保存后才会用于下一次启动。"
    }

    private func updateDraftBinding(_ binding: ButtonBinding, for button: RemoteButton) {
        guard !draftPreset.isBuiltIn else { return }
        var bindings = draftPreset.bindings
        bindings[button] = binding
        draftPreset = ButtonPreset(
            id: draftPreset.id,
            name: presetNameField.stringValue,
            bindings: bindings,
            requiredButtons: draftPreset.requiredButtons,
            isBuiltIn: false
        )
        hasUnsavedPresetChanges = true
        refreshPresetEditor()
    }

    private func recordShortcut(for button: RemoteButton) {
        guard !draftPreset.isBuiltIn, button.isUserEditable else { return }
        let recorder = ShortcutRecorderView(frame: .zero)
        let alert = NSAlert()
        alert.messageText = "录制 \(button.displayName) 的快捷键"
        alert.informativeText = "按下组合后点“使用快捷键”。米遥会在松手和异常退出时主动释放全部修饰键。"
        alert.accessoryView = recorder
        alert.addButton(withTitle: "使用快捷键")
        alert.addButton(withTitle: "取消")
        alert.window.initialFirstResponder = recorder
        DispatchQueue.main.async { [weak recorder] in
            recorder?.window?.makeFirstResponder(recorder)
        }
        guard alert.runModal() == .alertFirstButtonReturn, let shortcut = recorder.recordedShortcut else {
            refreshPresetEditor()
            return
        }
        updateDraftBinding(.keyboardShortcut(shortcut), for: button)
    }

    private func prepareForNewPreset() -> Bool {
        guard !hasUnsavedPresetChanges else {
            let alert = NSAlert()
            alert.messageText = "请先保存当前配置"
            alert.informativeText = "创建或复制前，先保存或切换并放弃当前修改。"
            alert.addButton(withTitle: "保存")
            alert.addButton(withTitle: "取消")
            guard alert.runModal() == .alertFirstButtonReturn else { return false }
            return persistDraft()
        }
        return true
    }

    private func createUserPreset(from source: ButtonPreset, name: String) {
        let preset = ButtonPreset(
            id: "user.\(UUID().uuidString.lowercased())",
            name: name,
            bindings: source.bindings,
            requiredButtons: ButtonPreset.pointer.requiredButtons,
            isBuiltIn: false
        )
        let nextCatalog = ButtonPresetCatalog(userPresets: presetCatalog.userPresets + [preset])
        do {
            try nextCatalog.validate()
            try presetStore.save(nextCatalog)
            presetCatalog = nextCatalog
            presetCatalogLoadState = .loaded
            selectedPresetID = preset.id
            draftPreset = preset
            hasUnsavedPresetChanges = false
            try persistSelectedPresetID(preset.id)
            refreshPresetEditor()
        } catch {
            showError(title: "配置没有创建", message: error.localizedDescription)
        }
    }

    private func selectPreset(id: String) {
        guard let preset = try? presetCatalog.preset(id: id) else {
            refreshPresetEditor()
            return
        }
        do {
            try persistSelectedPresetID(id)
            selectedPresetID = id
            draftPreset = preset
            hasUnsavedPresetChanges = false
            refreshPresetEditor()
        } catch {
            showError(title: "当前配置没有保存", message: error.localizedDescription)
            refreshPresetEditor()
        }
    }

    private func persistDraft() -> Bool {
        guard !draftPreset.isBuiltIn else { return true }
        let name = presetNameField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let savedPreset = ButtonPreset(
            id: draftPreset.id,
            name: name,
            bindings: draftPreset.bindings,
            requiredButtons: draftPreset.requiredButtons,
            isBuiltIn: false
        )
        var userPresets = presetCatalog.userPresets
        guard let index = userPresets.firstIndex(where: { $0.id == savedPreset.id }) else {
            showError(title: "配置没有保存", message: "找不到要保存的配置")
            return false
        }
        userPresets[index] = savedPreset
        let nextCatalog = ButtonPresetCatalog(userPresets: userPresets)
        do {
            try nextCatalog.validate()
            try presetStore.save(nextCatalog)
            presetCatalog = nextCatalog
            presetCatalogLoadState = .loaded
            draftPreset = savedPreset
            hasUnsavedPresetChanges = false
            refreshPresetEditor()
            return true
        } catch {
            showError(title: "配置没有保存", message: error.localizedDescription)
            return false
        }
    }

    private func persistSelectedPresetID(_ id: String) throws {
        if case .unsupportedVersion(let version) = preferencesLoadState {
            throw AppPreferencesError.unsupportedVersion(version)
        }
        var updated = preferences
        updated.selectedPresetID = id
        try preferencesStore.save(updated)
        preferences = updated
        preferencesLoadState = .loaded
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
