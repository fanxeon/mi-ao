// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import AppKit
import ApplicationServices
import Foundation

enum RemoteControlMode: String, Equatable {
    case pointer
    case directional
}

final class ButtonActionExecutor {
    private let preset: ButtonPreset
    private let debug: Bool
    private var timer: Timer?
    private var activeButton: RemoteButton?
    private var activeAction: ButtonAction?
    private var pressedAt: Date?
    private var lastTickAt = Date()
    private var lastScrollAt = Date.distantPast
    private var lastKeyRepeatAt = Date.distantPast
    private(set) var controlMode: RemoteControlMode = .pointer

    init(preset: ButtonPreset, debug: Bool = false) {
        self.preset = preset
        self.debug = debug
    }

    func start() {
        lastTickAt = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) {
            [weak self] _ in self?.tick()
        }
    }

    func stop() {
        if let activeAction, Self.isKeyboardAction(activeAction) {
            postKeyboard(action: activeAction, isDown: false)
        }
        timer?.invalidate()
        timer = nil
        clearActiveAction()
    }

    func buttonDown(_ button: RemoteButton) {
        let baseAction = preset.action(for: button)
        if baseAction == .modeTogglePointerDirectional {
            controlMode = controlMode == .pointer ? .directional : .pointer
            clearActiveAction()
            print(
                controlMode == .pointer
                    ? "控制模式：鼠标指针（方向移动，确认左击，返回右击）"
                    : "控制模式：方向键（上下左右，确认 Return，返回 Escape）"
            )
            return
        }

        let action = Self.resolvedAction(baseAction, mode: controlMode)
        activeButton = button
        activeAction = action
        pressedAt = Date()
        switch action {
        case .pointerMoveUp, .pointerMoveDown, .pointerMoveLeft, .pointerMoveRight:
            _ = CGDisplayShowCursor(CGMainDisplayID())
            movePointer(action: action, distance: 32, verify: debug)
        case .pointerLeftClick:
            postClick(button: .left)
        case .pointerRightClick:
            postClick(button: .right)
        case .pointerScrollUp:
            postScroll(lines: 2)
            lastScrollAt = Date()
        case .pointerScrollDown:
            postScroll(lines: -2)
            lastScrollAt = Date()
        case .keyboardArrowUp, .keyboardArrowDown, .keyboardArrowLeft,
            .keyboardArrowRight, .keyboardReturn, .keyboardEscape:
            postKeyboard(action: action, isDown: true)
            lastKeyRepeatAt = Date()
        case .codexFocus:
            print(CodexSubmitter().activateCodex() ? "已聚焦 Codex" : "Codex 未运行")
        case .codexLaunchOrFocus:
            switch CodexSubmitter().launchOrActivateCodex() {
            case .activated: print("已聚焦 Codex")
            case .launchRequested: print("正在启动 Codex")
            case .unavailable: print("未找到 Codex App，请先安装 Codex")
            }
        case .codexPreviousTask:
            print(
                CodexSubmitter().navigateTask(.previous)
                    ? "Codex：上一个会话" : "Codex 未运行或找不到会话菜单，未切换"
            )
        case .codexNextTask:
            print(
                CodexSubmitter().navigateTask(.next)
                    ? "Codex：下一个会话" : "Codex 未运行或找不到会话菜单，未切换"
            )
        case .presetCycle:
            print("当前只有 \(preset.name)（\(preset.id)）套装")
        case .voicePushToTalk, .modeTogglePointerDirectional, .unmapped:
            break
        }
    }

    func buttonUp(_ button: RemoteButton) {
        guard button == activeButton else { return }
        if let activeAction, Self.isKeyboardAction(activeAction) {
            postKeyboard(action: activeAction, isDown: false)
        }
        clearActiveAction()
    }

    static func resolvedAction(
        _ baseAction: ButtonAction,
        mode: RemoteControlMode
    ) -> ButtonAction {
        guard mode == .directional else { return baseAction }
        switch baseAction {
        case .pointerMoveUp: return .keyboardArrowUp
        case .pointerMoveDown: return .keyboardArrowDown
        case .pointerMoveLeft: return .keyboardArrowLeft
        case .pointerMoveRight: return .keyboardArrowRight
        case .pointerLeftClick: return .keyboardReturn
        case .pointerRightClick: return .keyboardEscape
        default: return baseAction
        }
    }

    private func tick(now: Date = Date()) {
        let delta = min(0.05, max(0, now.timeIntervalSince(lastTickAt)))
        lastTickAt = now
        guard let activeAction else { return }
        let held = pressedAt.map { now.timeIntervalSince($0) } ?? 0

        switch activeAction {
        case .pointerMoveUp, .pointerMoveDown, .pointerMoveLeft, .pointerMoveRight:
            let distance = Self.pointerSpeed(heldSeconds: held) * delta
            movePointer(action: activeAction, distance: distance)
        case .pointerScrollUp, .pointerScrollDown:
            guard now.timeIntervalSince(lastScrollAt) >= 0.12 else { return }
            postScroll(lines: activeAction == .pointerScrollUp ? 2 : -2)
            lastScrollAt = now
        case .keyboardArrowUp, .keyboardArrowDown, .keyboardArrowLeft,
            .keyboardArrowRight:
            guard held >= 0.35, now.timeIntervalSince(lastKeyRepeatAt) >= 0.07 else {
                return
            }
            postKeyboard(action: activeAction, isDown: true)
            lastKeyRepeatAt = now
        default:
            break
        }
    }

    static func pointerSpeed(heldSeconds: TimeInterval) -> Double {
        min(1_000, 260 + max(0, heldSeconds) * 620)
    }

    private static func isKeyboardAction(_ action: ButtonAction) -> Bool {
        switch action {
        case .keyboardArrowUp, .keyboardArrowDown, .keyboardArrowLeft,
            .keyboardArrowRight, .keyboardReturn, .keyboardEscape:
            return true
        default:
            return false
        }
    }

    private func clearActiveAction() {
        activeButton = nil
        activeAction = nil
        pressedAt = nil
    }

    private func movePointer(
        action: ButtonAction,
        distance: Double,
        verify: Bool = false
    ) {
        guard let current = CGEvent(source: nil)?.location else { return }
        var target = current
        switch action {
        case .pointerMoveUp: target.y -= distance
        case .pointerMoveDown: target.y += distance
        case .pointerMoveLeft: target.x -= distance
        case .pointerMoveRight: target.x += distance
        default: return
        }
        let warpResult = CGWarpMouseCursorPosition(target)
        let source = CGEventSource(stateID: .hidSystemState)
        CGEvent(
            mouseEventSource: source,
            mouseType: .mouseMoved,
            mouseCursorPosition: target,
            mouseButton: .left
        )?.post(tap: .cghidEventTap)
        if verify {
            let expected = target
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                guard let actual = CGEvent(source: nil)?.location else { return }
                print(
                    "鼠标动作：warp=\(warpResult.rawValue)，请求 (\(Int(expected.x)), \(Int(expected.y)))，实际 (\(Int(actual.x)), \(Int(actual.y)))"
                )
            }
        }
    }

    private func postClick(button: CGMouseButton) {
        guard let position = CGEvent(source: nil)?.location else { return }
        let source = CGEventSource(stateID: .hidSystemState)
        let downType: CGEventType = button == .left ? .leftMouseDown : .rightMouseDown
        let upType: CGEventType = button == .left ? .leftMouseUp : .rightMouseUp
        CGEvent(
            mouseEventSource: source,
            mouseType: downType,
            mouseCursorPosition: position,
            mouseButton: button
        )?.post(tap: .cghidEventTap)
        CGEvent(
            mouseEventSource: source,
            mouseType: upType,
            mouseCursorPosition: position,
            mouseButton: button
        )?.post(tap: .cghidEventTap)
    }

    private func postScroll(lines: Int32) {
        let source = CGEventSource(stateID: .hidSystemState)
        CGEvent(
            scrollWheelEvent2Source: source,
            units: .line,
            wheelCount: 1,
            wheel1: lines,
            wheel2: 0,
            wheel3: 0
        )?.post(tap: .cghidEventTap)
    }

    private func postKeyboard(action: ButtonAction, isDown: Bool) {
        guard let keyCode = Self.keyCode(for: action) else { return }
        let source = CGEventSource(stateID: .hidSystemState)
        guard
            let event = CGEvent(
                keyboardEventSource: source,
                virtualKey: keyCode,
                keyDown: isDown
            )
        else { return }
        event.post(tap: .cghidEventTap)
    }

    private static func keyCode(for action: ButtonAction) -> CGKeyCode? {
        switch action {
        case .keyboardArrowUp: return 126
        case .keyboardArrowDown: return 125
        case .keyboardArrowLeft: return 123
        case .keyboardArrowRight: return 124
        case .keyboardReturn: return 36
        case .keyboardEscape: return 53
        default: return nil
        }
    }
}
