import AppKit
import ApplicationServices
import Foundation

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
            var focused: CFTypeRef?
            let focusedResult = AXUIElementCopyAttributeValue(
                applicationElement,
                kAXFocusedUIElementAttribute as CFString,
                &focused
            )
            guard focusedResult == .success, let focused else {
                copyOnly(text)
                throw BridgeError.submission("无法确认 Codex 输入框焦点；transcript 已复制到剪贴板")
            }
            var roleValue: CFTypeRef?
            let roleResult = AXUIElementCopyAttributeValue(
                focused as! AXUIElement,
                kAXRoleAttribute as CFString,
                &roleValue
            )
            let role = roleResult == .success ? roleValue as? String : nil
            let acceptedRoles = [kAXTextAreaRole as String, kAXTextFieldRole as String]
            guard role.map(acceptedRoles.contains) == true else {
                copyOnly(text)
                throw BridgeError.submission(
                    "当前焦点不是 Codex 文本输入框（role=\(role ?? "unknown")）；transcript 已复制到剪贴板"
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
