// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import Testing

@testable import MiAo

@Test func codexLaunchUsesOnlyTheRendererAccessibilityArgument() {
    #expect(CodexSubmitter.accessibilityLaunchArgument == "--force-renderer-accessibility")
    #expect(!CodexSubmitter.accessibilityLaunchArgument.contains("remote-debugging"))
}
