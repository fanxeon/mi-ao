// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import AppKit
import ApplicationServices
import Foundation

final class PointerActionExecutor {
    private let preset: ButtonPreset
    private var timer: Timer?
    private var activeAction: ButtonAction?
    private var pressedAt: Date?
    private var lastTickAt = Date()
    private var lastScrollAt = Date.distantPast
    private(set) var isPointerEnabled = true

    init(preset: ButtonPreset) {
        self.preset = preset
    }

    func start() {
        lastTickAt = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) {
            [weak self] _ in self?.tick()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        activeAction = nil
    }

    func buttonDown(_ button: RemoteButton) {
        let action = preset.action(for: button)
        if action == .pointerToggle {
            isPointerEnabled.toggle()
            activeAction = nil
            print("指针模式：\(isPointerEnabled ? "开启" : "暂停")")
            return
        }

        guard isPointerEnabled else { return }
        activeAction = action
        pressedAt = Date()
        switch action {
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
        case .codexFocus:
            print(CodexSubmitter().activateCodex() ? "已聚焦 Codex" : "Codex 未运行")
        case .presetCycle:
            print("当前只有 \(preset.name)（\(preset.id)）套装")
        case .pointerMoveUp, .pointerMoveDown, .pointerMoveLeft, .pointerMoveRight,
            .voicePushToTalk, .pointerToggle, .unmapped:
            break
        }
    }

    func buttonUp(_ button: RemoteButton) {
        if preset.action(for: button) == activeAction {
            activeAction = nil
            pressedAt = nil
        }
    }

    private func tick(now: Date = Date()) {
        let delta = min(0.05, max(0, now.timeIntervalSince(lastTickAt)))
        lastTickAt = now
        guard isPointerEnabled, let activeAction else { return }
        let held = pressedAt.map { now.timeIntervalSince($0) } ?? 0

        switch activeAction {
        case .pointerMoveUp, .pointerMoveDown, .pointerMoveLeft, .pointerMoveRight:
            let distance = Self.pointerSpeed(heldSeconds: held) * delta
            movePointer(action: activeAction, distance: distance)
        case .pointerScrollUp, .pointerScrollDown:
            guard now.timeIntervalSince(lastScrollAt) >= 0.12 else { return }
            postScroll(lines: activeAction == .pointerScrollUp ? 2 : -2)
            lastScrollAt = now
        default:
            break
        }
    }

    static func pointerSpeed(heldSeconds: TimeInterval) -> Double {
        min(1_000, 260 + max(0, heldSeconds) * 620)
    }

    private func movePointer(action: ButtonAction, distance: Double) {
        guard let current = CGEvent(source: nil)?.location else { return }
        var target = current
        switch action {
        case .pointerMoveUp: target.y -= distance
        case .pointerMoveDown: target.y += distance
        case .pointerMoveLeft: target.x -= distance
        case .pointerMoveRight: target.x += distance
        default: return
        }
        let source = CGEventSource(stateID: .hidSystemState)
        CGEvent(
            mouseEventSource: source,
            mouseType: .mouseMoved,
            mouseCursorPosition: target,
            mouseButton: .left
        )?.post(tap: .cghidEventTap)
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
}
