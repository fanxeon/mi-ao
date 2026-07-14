// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import AppKit
import ApplicationServices
import Foundation

enum CodexActivationResult: Equatable {
    case activated
    case launchRequested
    case unavailable
}

enum CodexTaskDirection: Equatable {
    case previous
    case next

    var menuItemTitles: [String] {
        switch self {
        case .previous: return ["Previous Task", "上一个任务", "上一个会话"]
        case .next: return ["Next Task", "下一个任务", "下一个会话"]
        }
    }
}

struct CodexSubmitter {
    private let bundleIdentifier = "com.openai.codex"

    func submit(_ text: String, force: Bool) throws {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw BridgeError.submission("转写为空，已取消发送")
        }

        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        guard AXIsProcessTrustedWithOptions(options) else {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            throw BridgeError.submission("尚未授予辅助功能权限；transcript 已复制到剪贴板")
        }

        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first else {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            throw BridgeError.submission("Codex 未运行；transcript 已复制到剪贴板")
        }

        app.activate(options: [.activateAllWindows])
        Thread.sleep(forTimeInterval: 0.35)

        if !force {
            let applicationElement = AXUIElementCreateApplication(app.processIdentifier)
            guard focusCodexEditor(in: applicationElement) else {
                copyOnly(text)
                throw BridgeError.submission(
                    "无法安全聚焦唯一的 Codex 输入框；transcript 已复制到剪贴板"
                )
            }
        }

        let snapshot = PasteboardSnapshot.capture()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        postKey(keyCode: 9, flags: .maskCommand)  // Cmd+V
        Thread.sleep(forTimeInterval: 0.2)
        postKey(keyCode: 36, flags: [])  // Return
        Thread.sleep(forTimeInterval: 0.35)
        snapshot.restore()
    }

    @discardableResult
    func activateCodex() -> Bool {
        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first else {
            return false
        }
        return app.activate(options: [.activateAllWindows])
    }

    func launchOrActivateCodex() -> CodexActivationResult {
        if activateCodex() { return .activated }
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
        else { return .unavailable }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: configuration) { _, error in
            if let error {
                fputs("启动 Codex 失败：\(error.localizedDescription)\n", stderr)
            }
        }
        return .launchRequested
    }

    @discardableResult
    func navigateTask(_ direction: CodexTaskDirection) -> Bool {
        guard
            let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
                .first
        else { return false }
        let applicationElement = AXUIElementCreateApplication(app.processIdentifier)
        guard
            let menuBar = elementAttribute(applicationElement, kAXMenuBarAttribute),
            let menuItem = findMenuItem(in: menuBar, titles: direction.menuItemTitles)
        else { return false }
        app.activate(options: [.activateAllWindows])
        return AXUIElementPerformAction(menuItem, kAXPressAction as CFString) == .success
    }

    private func focusCodexEditor(in applicationElement: AXUIElement) -> Bool {
        let searchRoot = elementAttribute(applicationElement, kAXFocusedWindowAttribute) ?? applicationElement
        let candidates = findTextInputs(in: searchRoot)
        guard candidates.count == 1 else { return false }
        let result = AXUIElementSetAttributeValue(
            candidates[0],
            kAXFocusedAttribute as CFString,
            kCFBooleanTrue
        )
        guard result == .success else { return false }

        guard let focused = elementAttribute(applicationElement, kAXFocusedUIElementAttribute) else {
            return false
        }
        return CFEqual(focused, candidates[0])
    }

    private func findTextInputs(in root: AXUIElement) -> [AXUIElement] {
        var queue: [(element: AXUIElement, depth: Int)] = [(root, 0)]
        var cursor = 0
        var matches: [AXUIElement] = []

        while cursor < queue.count, cursor < 10_000 {
            let current = queue[cursor]
            cursor += 1

            if isAcceptedTextInput(current.element), isEnabled(current.element) {
                matches.append(current.element)
            }
            guard current.depth < 50 else { continue }
            for child in elementArrayAttribute(current.element, kAXChildrenAttribute) {
                queue.append((child, current.depth + 1))
            }
        }
        return matches
    }

    private func findMenuItem(in root: AXUIElement, titles: [String]) -> AXUIElement? {
        var queue: [(element: AXUIElement, depth: Int)] = [(root, 0)]
        var cursor = 0

        while cursor < queue.count, cursor < 1_000 {
            let current = queue[cursor]
            cursor += 1
            if stringAttribute(current.element, kAXRoleAttribute) == kAXMenuItemRole as String,
                let title = stringAttribute(current.element, kAXTitleAttribute),
                titles.contains(title)
            {
                return current.element
            }
            guard current.depth < 5 else { continue }
            for child in elementArrayAttribute(current.element, kAXChildrenAttribute) {
                queue.append((child, current.depth + 1))
            }
        }
        return nil
    }

    private func isAcceptedTextInput(_ element: AXUIElement) -> Bool {
        guard let role = stringAttribute(element, kAXRoleAttribute) else { return false }
        return [kAXTextAreaRole as String, kAXTextFieldRole as String].contains(role)
    }

    private func isEnabled(_ element: AXUIElement) -> Bool {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            element,
            kAXEnabledAttribute as CFString,
            &value
        )
        return result != .success || (value as? Bool) != false
    }

    private func elementAttribute(_ element: AXUIElement, _ attribute: String) -> AXUIElement? {
        var value: CFTypeRef?
        guard
            AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
            let value,
            CFGetTypeID(value) == AXUIElementGetTypeID()
        else { return nil }
        return (value as! AXUIElement)
    }

    private func elementArrayAttribute(_ element: AXUIElement, _ attribute: String) -> [AXUIElement] {
        var value: CFTypeRef?
        guard
            AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
            let values = value as? [AXUIElement]
        else { return [] }
        return values
    }

    private func stringAttribute(_ element: AXUIElement, _ attribute: String) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else {
            return nil
        }
        return value as? String
    }

    private func copyOnly(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func postKey(keyCode: CGKeyCode, flags: CGEventFlags) {
        let source = CGEventSource(stateID: .hidSystemState)
        let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        let up = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        down?.flags = flags
        up?.flags = flags
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }
}

private struct PasteboardSnapshot {
    let items: [[NSPasteboard.PasteboardType: Data]]

    static func capture() -> PasteboardSnapshot {
        let copied = (NSPasteboard.general.pasteboardItems ?? []).map { item in
            Dictionary(
                uniqueKeysWithValues: item.types.compactMap { type in
                    item.data(forType: type).map { (type, $0) }
                })
        }
        return PasteboardSnapshot(items: copied)
    }

    func restore() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let restored: [NSPasteboardItem] = items.map { values in
            let item = NSPasteboardItem()
            for (type, data) in values {
                item.setData(data, forType: type)
            }
            return item
        }
        if !restored.isEmpty { pasteboard.writeObjects(restored) }
    }
}
