// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import Testing

@testable import MiAo

@Test func codexLaunchUsesOnlyTheRendererAccessibilityArgument() {
    #expect(CodexSubmitter.accessibilityLaunchArgument == "--force-renderer-accessibility")
    #expect(!CodexSubmitter.accessibilityLaunchArgument.contains("remote-debugging"))
}

@Test func codexLaunchEnvironmentDropsInternalMiAoState() {
    let sanitized = CodexSubmitter.sanitizedLaunchEnvironment([
        "HOME": "/Users/test",
        "PATH": "/usr/bin",
        "MI_AO_APP_BUNDLE": "/Applications/米遥.app",
        "MI_AO_RUNTIME_TOKEN": "secret-runtime-token",
    ])

    #expect(sanitized == ["HOME": "/Users/test", "PATH": "/usr/bin"])
}
