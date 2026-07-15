// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import AppKit
import ApplicationServices
import Foundation

enum RemoteControlMode: String, Equatable {
    case pointer
    case directional
}

enum HomeClickDecision: Equatable {
    case waitForSecondClick
    case pageUp
}

struct HomeClickArbiter {
    private(set) var isWaitingForSecondClick = false

    mutating func registerClick() -> HomeClickDecision {
        if isWaitingForSecondClick {
            isWaitingForSecondClick = false
            return .pageUp
        }
        isWaitingForSecondClick = true
        return .waitForSecondClick
    }

    mutating func commitSingleClick() -> Bool {
        guard isWaitingForSecondClick else { return false }
        isWaitingForSecondClick = false
        return true
    }

    mutating func reset() {
        isWaitingForSecondClick = false
    }
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
    private var homeClickArbiter = HomeClickArbiter()
    private var pendingHomeSingle: DispatchWorkItem?
    private(set) var controlMode: RemoteControlMode = .pointer

    static let homeDoubleClickInterval: TimeInterval = 0.35

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
        pendingHomeSingle?.cancel()
        pendingHomeSingle = nil
        homeClickArbiter.reset()
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
                    ? "控制模式：鼠标指针（仅方向环移动指针）"
                    : "控制模式：方向键（仅方向环发送上下左右）"
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
        case .pointerScrollUp:
            postScroll(lines: 2)
            lastScrollAt = Date()
        case .pointerScrollDown:
            postScroll(lines: -2)
            lastScrollAt = Date()
        case .keyboardArrowUp, .keyboardArrowDown, .keyboardArrowLeft,
            .keyboardArrowRight, .keyboardReturn, .keyboardEscape,
            .keyboardPageUp, .keyboardPageDown:
            postKeyboard(action: action, isDown: true)
            lastKeyRepeatAt = Date()
        case .homePageNavigation:
            break
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
        if activeAction == .homePageNavigation {
            handleHomeClick()
            clearActiveAction()
            return
        }
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
            .keyboardArrowRight, .keyboardReturn, .keyboardEscape,
            .keyboardPageUp, .keyboardPageDown:
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

    private func handleHomeClick() {
        switch homeClickArbiter.registerClick() {
        case .waitForSecondClick:
            let workItem = DispatchWorkItem { [weak self] in
                guard let self, self.homeClickArbiter.commitSingleClick() else { return }
                self.pendingHomeSingle = nil
                self.postKeyboardStroke(action: .keyboardPageDown)
                print("HOME 单击：Page Down")
            }
            pendingHomeSingle = workItem
            DispatchQueue.main.asyncAfter(
                deadline: .now() + Self.homeDoubleClickInterval,
                execute: workItem
            )
        case .pageUp:
            pendingHomeSingle?.cancel()
            pendingHomeSingle = nil
            postKeyboardStroke(action: .keyboardPageUp)
            print("HOME 双击：Page Up")
        }
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

    private func postKeyboardStroke(action: ButtonAction) {
        postKeyboard(action: action, isDown: true)
        postKeyboard(action: action, isDown: false)
    }

    private static func keyCode(for action: ButtonAction) -> CGKeyCode? {
        switch action {
        case .keyboardArrowUp: return 126
        case .keyboardArrowDown: return 125
        case .keyboardArrowLeft: return 123
        case .keyboardArrowRight: return 124
        case .keyboardReturn: return 36
        case .keyboardEscape: return 53
        case .keyboardPageUp: return 116
        case .keyboardPageDown: return 121
        default: return nil
        }
    }
}
