// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import Testing

@testable import MiAo

@Test func setupReportStartsOnlyWhenEveryRealCheckIsReady() {
    let readyChecks = SetupCheckID.allCases.map {
        SetupCheck(
            id: $0,
            title: $0.rawValue,
            detail: "ready",
            state: .ready,
            action: nil,
            actionTitle: nil
        )
    }
    #expect(SetupEnvironmentReport(checks: readyChecks, runtimeActive: false).canStart)
    #expect(!SetupEnvironmentReport(checks: readyChecks, runtimeActive: true).canStart)

    var incompleteChecks = readyChecks
    incompleteChecks[2] = SetupCheck(
        id: .accessibility,
        title: "accessibility",
        detail: "missing",
        state: .actionRequired,
        action: .requestAccessibility,
        actionTitle: "request"
    )
    #expect(!SetupEnvironmentReport(checks: incompleteChecks, runtimeActive: false).canStart)
}

@Test func parsesSetupGuideModeExplicitly() throws {
    let configuration = try Configuration.parse(["mi-ao", "setup"])
    #expect(configuration.mode == .setup)
}
