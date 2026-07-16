// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import AppKit

@MainActor
final class RuntimeApplicationDelegate: NSObject, NSApplicationDelegate {
    private let reopenHandler: () -> Void

    init(reopenHandler: @escaping () -> Void) {
        self.reopenHandler = reopenHandler
        super.init()
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        reopenHandler()
        return true
    }

}
