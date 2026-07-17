// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import Foundation

enum MiAoMenuBarTone: Equatable {
    case neutral
    case ready
    case command
    case success
    case warning
    case recording
    case processing
    case failure
}

enum MiAoMenuBarIcon: Equatable {
    case brand
    case systemSymbol(String)
}

struct MiAoMenuBarPresentation: Equatable {
    let label: String
    let icon: MiAoMenuBarIcon
    let tone: MiAoMenuBarTone

    static func resolved(
        status: MiAoRuntimeStatus,
        activity: MiAoCommandActivity?
    ) -> MiAoMenuBarPresentation {
        if status.allowsTransientCommandActivity, let activity {
            return activity.presentation
        }
        return status.menuBarPresentation
    }
}

struct MiAoCommandActivity: Equatable {
    static let displayDuration: TimeInterval = 1.2

    let presentation: MiAoMenuBarPresentation

    static func executed(action: ButtonAction) -> MiAoCommandActivity? {
        let symbol: String
        switch action {
        case .pointerMoveUp, .keyboardArrowUp: symbol = "arrow.up"
        case .pointerMoveDown, .keyboardArrowDown: symbol = "arrow.down"
        case .pointerMoveLeft, .keyboardArrowLeft: symbol = "arrow.left"
        case .pointerMoveRight, .keyboardArrowRight: symbol = "arrow.right"
        case .pointerScrollUp, .keyboardPageUp: symbol = "arrow.up.to.line"
        case .pointerScrollDown, .keyboardPageDown: symbol = "arrow.down.to.line"
        case .keyboardReturn: symbol = "return"
        case .keyboardEscape: symbol = "escape"
        case .homePageNavigation:
            return nil
        case .modeTogglePointerDirectional, .codexFocus, .codexLaunchOrFocus,
            .codexPreviousTask, .codexNextTask, .presetCycle, .voicePushToTalk,
            .unmapped:
            return nil
        }
        return command(label: action.displayName, symbol: symbol)
    }

    static func keyboardShortcut(_ shortcut: KeyboardShortcutSpec) -> MiAoCommandActivity {
        command(label: "快捷键 · \(shortcut.displayName)", symbol: "keyboard")
    }

    static func controlMode(_ mode: RemoteControlMode) -> MiAoCommandActivity {
        command(
            label: mode == .pointer ? "方向环 · 鼠标指针" : "方向环 · 上下左右",
            symbol: mode == .pointer ? "cursorarrow" : "arrow.up.arrow.down"
        )
    }

    static func presetChanged(name: String) -> MiAoCommandActivity {
        success(label: "已切换配置 · \(name)", symbol: "square.stack.3d.up")
    }

    static func presetAlreadySelected(name: String) -> MiAoCommandActivity {
        command(label: "当前配置 · \(name)", symbol: "square.stack.3d.up")
    }

    static func presetUnavailable(id: String) -> MiAoCommandActivity {
        failure(label: "配置不可用 · \(id)", symbol: "square.stack.3d.up")
    }

    static func codexFocus(succeeded: Bool) -> MiAoCommandActivity {
        succeeded
            ? success(label: "已聚焦 Codex", symbol: "rectangle.and.hand.point.up.left")
            : failure(label: "Codex 未运行", symbol: "rectangle.and.hand.point.up.left")
    }

    static func codexActivation(_ result: CodexActivationResult) -> MiAoCommandActivity {
        switch result {
        case .activated:
            return success(label: "已聚焦 Codex", symbol: "rectangle.and.hand.point.up.left")
        case .launchRequested:
            return command(label: "正在启动 Codex", symbol: "power")
        case .unavailable:
            return failure(label: "未找到 Codex App", symbol: "power")
        }
    }

    static func codexTask(
        _ direction: CodexTaskDirection,
        succeeded: Bool
    ) -> MiAoCommandActivity {
        let label = direction == .previous ? "Codex · 上一个会话" : "Codex · 下一个会话"
        let symbol = direction == .previous ? "chevron.backward.2" : "chevron.forward.2"
        return succeeded
            ? success(label: label, symbol: symbol)
            : failure(label: "Codex 会话切换失败", symbol: symbol)
    }

    static func homePage(up: Bool) -> MiAoCommandActivity {
        command(
            label: up ? "HOME 双击 · 向上翻页" : "HOME 单击 · 向下翻页",
            symbol: up ? "arrow.up.to.line" : "arrow.down.to.line"
        )
    }

    static func legacyPresetCycleUnavailable() -> MiAoCommandActivity {
        failure(label: "旧版配置循环已停用", symbol: "square.stack.3d.up")
    }

    private static func command(label: String, symbol: String) -> MiAoCommandActivity {
        MiAoCommandActivity(
            presentation: MiAoMenuBarPresentation(
                label: label,
                icon: .systemSymbol(symbol),
                tone: .command
            )
        )
    }

    private static func success(label: String, symbol: String) -> MiAoCommandActivity {
        MiAoCommandActivity(
            presentation: MiAoMenuBarPresentation(
                label: label,
                icon: .systemSymbol(symbol),
                tone: .success
            )
        )
    }

    private static func failure(label: String, symbol: String) -> MiAoCommandActivity {
        MiAoCommandActivity(
            presentation: MiAoMenuBarPresentation(
                label: label,
                icon: .systemSymbol(symbol),
                tone: .failure
            )
        )
    }
}

extension MiAoRuntimeStatus {
    var allowsTransientCommandActivity: Bool {
        switch self {
        case .recording, .stopping:
            return false
        case .starting, .searching, .connecting, .ready, .processing, .sent,
            .disconnected, .reconnecting, .voiceSleeping, .error:
            return true
        }
    }

    var menuBarPresentation: MiAoMenuBarPresentation {
        let tone: MiAoMenuBarTone
        switch self {
        case .ready: tone = .ready
        case .recording: tone = .recording
        case .processing: tone = .processing
        case .sent: tone = .success
        case .disconnected, .reconnecting, .voiceSleeping: tone = .warning
        case .error: tone = .failure
        case .starting, .searching, .connecting, .stopping: tone = .neutral
        }
        return MiAoMenuBarPresentation(
            label: label,
            icon: .brand,
            tone: tone
        )
    }
}
