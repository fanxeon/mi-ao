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
}

enum ButtonAction: String, Codable {
    case voicePushToTalk = "voice.push_to_talk"
    case pointerMoveUp = "pointer.move_up"
    case pointerMoveDown = "pointer.move_down"
    case pointerMoveLeft = "pointer.move_left"
    case pointerMoveRight = "pointer.move_right"
    case pointerLeftClick = "pointer.left_click"
    case pointerRightClick = "pointer.right_click"
    case pointerScrollUp = "pointer.scroll_up"
    case pointerScrollDown = "pointer.scroll_down"
    case pointerToggle = "pointer.toggle"
    case codexFocus = "codex.focus"
    case presetCycle = "preset.cycle"
    case unmapped
}

struct ButtonPreset: Equatable {
    let id: String
    let name: String
    let actions: [RemoteButton: ButtonAction]
    let requiredButtons: Set<RemoteButton>

    func action(for button: RemoteButton) -> ButtonAction {
        actions[button] ?? .unmapped
    }

    static func named(_ id: String) throws -> ButtonPreset {
        switch id {
        case pointer.id: return pointer
        default: throw BridgeError.configuration("未知按键预设：\(id)。当前可选：pointer")
        }
    }

    static let pointer = ButtonPreset(
        id: "pointer",
        name: "鼠标指针",
        actions: [
            .voice: .voicePushToTalk,
            .dpadUp: .pointerMoveUp,
            .dpadDown: .pointerMoveDown,
            .dpadLeft: .pointerMoveLeft,
            .dpadRight: .pointerMoveRight,
            .center: .pointerLeftClick,
            .back: .pointerRightClick,
            .home: .codexFocus,
            .menu: .presetCycle,
            .volumeUp: .pointerScrollUp,
            .volumeDown: .pointerScrollDown,
            .tv: .pointerToggle,
            .power: .unmapped,
        ],
        requiredButtons: [.dpadUp, .dpadDown, .dpadLeft, .dpadRight, .center, .back]
    )
}
