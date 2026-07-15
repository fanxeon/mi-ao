// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import Foundation

enum RemoteButton: String, CaseIterable, Codable {
    case voice
    case dpadUp = "dpad_up"
    case dpadDown = "dpad_down"
    case dpadLeft = "dpad_left"
    case dpadRight = "dpad_right"
    case center
    case back
    case home
    case menu
    case volumeUp = "volume_up"
    case volumeDown = "volume_down"
    case tv
    case power

    var displayName: String {
        switch self {
        case .voice: return "语音"
        case .dpadUp: return "方向上"
        case .dpadDown: return "方向下"
        case .dpadLeft: return "方向左"
        case .dpadRight: return "方向右"
        case .center: return "中间确认"
        case .back: return "返回"
        case .home: return "HOME"
        case .menu: return "菜单"
        case .volumeUp: return "音量 +"
        case .volumeDown: return "音量 -"
        case .tv: return "TV"
        case .power: return "电源"
        }
    }

    var isUserEditable: Bool {
        self != .voice && self != .menu
    }
}

enum ButtonAction: String, CaseIterable, Codable {
    case voicePushToTalk = "voice.push_to_talk"
    case pointerMoveUp = "pointer.move_up"
    case pointerMoveDown = "pointer.move_down"
    case pointerMoveLeft = "pointer.move_left"
    case pointerMoveRight = "pointer.move_right"
    case pointerScrollUp = "pointer.scroll_up"
    case pointerScrollDown = "pointer.scroll_down"
    case keyboardArrowUp = "keyboard.arrow_up"
    case keyboardArrowDown = "keyboard.arrow_down"
    case keyboardArrowLeft = "keyboard.arrow_left"
    case keyboardArrowRight = "keyboard.arrow_right"
    case keyboardReturn = "keyboard.return"
    case keyboardEscape = "keyboard.escape"
    case keyboardPageUp = "keyboard.page_up"
    case keyboardPageDown = "keyboard.page_down"
    case homePageNavigation = "home.page_navigation"
    case modeTogglePointerDirectional = "mode.toggle_pointer_directional"
    case codexFocus = "codex.focus"
    case codexLaunchOrFocus = "codex.launch_or_focus"
    case codexPreviousTask = "codex.previous_task"
    case codexNextTask = "codex.next_task"
    case presetCycle = "preset.cycle"
    case unmapped

    var displayName: String {
        switch self {
        case .voicePushToTalk: return "按住语音说话"
        case .pointerMoveUp: return "移动鼠标 · 上"
        case .pointerMoveDown: return "移动鼠标 · 下"
        case .pointerMoveLeft: return "移动鼠标 · 左"
        case .pointerMoveRight: return "移动鼠标 · 右"
        case .pointerScrollUp: return "滚动 · 向上"
        case .pointerScrollDown: return "滚动 · 向下"
        case .keyboardArrowUp: return "键盘 · 上方向"
        case .keyboardArrowDown: return "键盘 · 下方向"
        case .keyboardArrowLeft: return "键盘 · 左方向"
        case .keyboardArrowRight: return "键盘 · 右方向"
        case .keyboardReturn: return "键盘 · Return"
        case .keyboardEscape: return "键盘 · Escape"
        case .keyboardPageUp: return "键盘 · Page Up"
        case .keyboardPageDown: return "键盘 · Page Down"
        case .homePageNavigation: return "HOME · 单击下翻 / 双击上翻"
        case .modeTogglePointerDirectional: return "切换方向环模式"
        case .codexFocus: return "聚焦 Codex"
        case .codexLaunchOrFocus: return "启动或聚焦 Codex"
        case .codexPreviousTask: return "Codex · 上一个会话"
        case .codexNextTask: return "Codex · 下一个会话"
        case .presetCycle: return "循环切换配置（旧版）"
        case .unmapped: return "不执行动作"
        }
    }
}

enum ShortcutModifier: String, CaseIterable, Codable, Hashable {
    case command
    case option
    case shift
    case control

    var symbol: String {
        switch self {
        case .command: return "⌘"
        case .option: return "⌥"
        case .shift: return "⇧"
        case .control: return "⌃"
        }
    }

    var keyCode: UInt16 {
        switch self {
        case .command: return 55
        case .option: return 58
        case .shift: return 56
        case .control: return 59
        }
    }
}

struct KeyboardShortcutSpec: Codable, Equatable {
    let keyCode: UInt16
    let modifiers: Set<ShortcutModifier>
    let keyLabel: String

    init(keyCode: UInt16, modifiers: Set<ShortcutModifier>, keyLabel: String) throws {
        guard keyCode < 128 else {
            throw BridgeError.configuration("快捷键按键码无效")
        }
        let trimmedLabel = keyLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLabel.isEmpty, trimmedLabel.count <= 12 else {
            throw BridgeError.configuration("快捷键按键名称无效")
        }
        guard !Self.isDangerous(keyCode: keyCode, modifiers: modifiers) else {
            throw BridgeError.configuration("为避免意外退出、锁屏或强制退出，不能保存这个快捷键")
        }
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.keyLabel = trimmedLabel.uppercased()
    }

    var displayName: String {
        ShortcutModifier.allCases
            .filter(modifiers.contains)
            .map(\.symbol)
            .joined() + keyLabel
    }

    private static func isDangerous(keyCode: UInt16, modifiers: Set<ShortcutModifier>) -> Bool {
        let command = modifiers.contains(.command)
        let option = modifiers.contains(.option)
        let control = modifiers.contains(.control)
        return (command && keyCode == 12)  // Command-Q
            || (command && option && keyCode == 53)  // Command-Option-Escape
            || (command && control && keyCode == 12)  // Command-Control-Q
    }

    private enum CodingKeys: String, CodingKey {
        case keyCode
        case modifiers
        case keyLabel
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            keyCode: container.decode(UInt16.self, forKey: .keyCode),
            modifiers: container.decode(Set<ShortcutModifier>.self, forKey: .modifiers),
            keyLabel: container.decode(String.self, forKey: .keyLabel)
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(keyCode, forKey: .keyCode)
        try container.encode(modifiers, forKey: .modifiers)
        try container.encode(keyLabel, forKey: .keyLabel)
    }
}

enum ButtonBinding: Equatable {
    case action(ButtonAction)
    case keyboardShortcut(KeyboardShortcutSpec)
    case presetSwitch(String)

    var displayName: String {
        switch self {
        case .action(let action): return action.displayName
        case .keyboardShortcut(let shortcut): return "自定义快捷键 · \(shortcut.displayName)"
        case .presetSwitch: return "切换到另一配置"
        }
    }

    var action: ButtonAction {
        guard case .action(let action) = self else { return .unmapped }
        return action
    }
}

extension ButtonBinding: Codable {
    private enum CodingKeys: String, CodingKey {
        case kind
        case action
        case shortcut
        case targetPresetID = "target_preset_id"
    }

    private enum Kind: String, Codable {
        case action
        case keyboardShortcut = "keyboard_shortcut"
        case presetSwitch = "preset_switch"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Kind.self, forKey: .kind) {
        case .action:
            self = .action(try container.decode(ButtonAction.self, forKey: .action))
        case .keyboardShortcut:
            self = .keyboardShortcut(
                try container.decode(KeyboardShortcutSpec.self, forKey: .shortcut)
            )
        case .presetSwitch:
            self = .presetSwitch(try container.decode(String.self, forKey: .targetPresetID))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .action(let action):
            try container.encode(Kind.action, forKey: .kind)
            try container.encode(action, forKey: .action)
        case .keyboardShortcut(let shortcut):
            try container.encode(Kind.keyboardShortcut, forKey: .kind)
            try container.encode(shortcut, forKey: .shortcut)
        case .presetSwitch(let id):
            try container.encode(Kind.presetSwitch, forKey: .kind)
            try container.encode(id, forKey: .targetPresetID)
        }
    }
}

struct ButtonPreset: Equatable {
    let id: String
    let name: String
    let bindings: [RemoteButton: ButtonBinding]
    let requiredButtons: Set<RemoteButton>
    let isBuiltIn: Bool

    func binding(for button: RemoteButton) -> ButtonBinding {
        bindings[button] ?? .action(.unmapped)
    }

    // Kept for hardware-profile validation and the existing CLI preview contract.
    func action(for button: RemoteButton) -> ButtonAction {
        binding(for: button).action
    }

    static func named(_ id: String) throws -> ButtonPreset {
        guard id == pointer.id else {
            throw BridgeError.configuration("未知内置按键预设：\(id)。请从 App 的“按键配置”页选择已保存的配置")
        }
        return pointer
    }

    static let pointer = ButtonPreset(
        id: "pointer",
        name: "默认 · 鼠标指针",
        bindings: [
            .voice: .action(.voicePushToTalk),
            .dpadUp: .action(.pointerMoveUp),
            .dpadDown: .action(.pointerMoveDown),
            .dpadLeft: .action(.pointerMoveLeft),
            .dpadRight: .action(.pointerMoveRight),
            .center: .action(.keyboardReturn),
            .back: .action(.keyboardEscape),
            .home: .action(.homePageNavigation),
            .menu: .action(.unmapped),
            .volumeUp: .action(.codexPreviousTask),
            .volumeDown: .action(.codexNextTask),
            .tv: .action(.modeTogglePointerDirectional),
            .power: .action(.codexLaunchOrFocus),
        ],
        requiredButtons: [.dpadUp, .dpadDown, .dpadLeft, .dpadRight, .center, .back],
        isBuiltIn: true
    )
}

struct ButtonPresetCatalog: Equatable {
    let userPresets: [ButtonPreset]

    static let builtIn = ButtonPresetCatalog(userPresets: [])

    var allPresets: [ButtonPreset] { [.pointer] + userPresets }

    func preset(id: String) throws -> ButtonPreset {
        guard let preset = allPresets.first(where: { $0.id == id }) else {
            throw BridgeError.configuration("找不到按键配置“\(id)”。请在“按键配置”页选择仍存在的配置")
        }
        return preset
    }

    func validate() throws {
        let identifiers = allPresets.map(\.id)
        guard Set(identifiers).count == identifiers.count else {
            throw BridgeError.configuration("按键配置标识重复，无法安全保存")
        }
        let knownIDs = Set(identifiers)
        for preset in userPresets {
            guard preset.id.hasPrefix("user."), preset.id.count > 5 else {
                throw BridgeError.configuration("自定义配置标识无效")
            }
            let name = preset.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, name.count <= 40 else {
                throw BridgeError.configuration("配置名称需为 1–40 个字符")
            }
            guard preset.binding(for: .voice) == .action(.voicePushToTalk) else {
                throw BridgeError.configuration("语音键必须保留为按住说话")
            }
            guard preset.binding(for: .menu) == .action(.unmapped) else {
                throw BridgeError.configuration("菜单键保留 macOS 原生右键，不能由米遥覆盖")
            }
            for (button, binding) in preset.bindings {
                switch binding {
                case .presetSwitch(let targetID):
                    guard button == .tv else {
                        throw BridgeError.configuration("只有 TV 键可以切换按键配置")
                    }
                    guard targetID != preset.id, knownIDs.contains(targetID) else {
                        throw BridgeError.configuration("TV 键的目标配置不存在或与当前配置相同")
                    }
                case .action(let action):
                    guard action != .presetCycle else {
                        throw BridgeError.configuration("旧版循环切换已移除；请为 TV 明确选择目标配置")
                    }
                    if action == .voicePushToTalk, button != .voice {
                        throw BridgeError.configuration("只有语音键可以使用按住说话")
                    }
                    if action == .homePageNavigation, button != .home {
                        throw BridgeError.configuration("HOME 双击导航只可分配给 HOME 键")
                    }
                    if action == .modeTogglePointerDirectional, button != .tv {
                        throw BridgeError.configuration("方向环模式切换只可分配给 TV 键")
                    }
                case .keyboardShortcut:
                    guard button.isUserEditable else {
                        throw BridgeError.configuration("语音键与菜单键不能使用自定义快捷键")
                    }
                }
            }
        }
    }
}
