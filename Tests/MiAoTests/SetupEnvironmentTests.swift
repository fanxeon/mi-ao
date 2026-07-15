// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import Foundation
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

@Test func installationContextStillReadsPreFingerprintFormat() throws {
    let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0"><dict>
          <key>repositoryRoot</key><string>/tmp/mi-ao</string>
          <key>version</key><string>0.1.0</string>
          <key>installedAt</key><string>2026-07-15T00:00:00Z</string>
        </dict></plist>
        """
    let context = try PropertyListDecoder().decode(
        MiAoInstallationContext.self,
        from: Data(plist.utf8)
    )
    #expect(context.repositoryRoot == "/tmp/mi-ao")
    #expect(context.runtimeRoot == nil)
    #expect(context.codeHash == nil)
}

@Test func installationContextReadsSelfContainedRuntimeRoot() throws {
    let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0"><dict>
          <key>repositoryRoot</key><string>/tmp/mi-ao-source</string>
          <key>runtimeRoot</key><string>/Applications/米遥.app/Contents/Resources/Runtime</string>
          <key>version</key><string>0.1.0</string>
          <key>installedAt</key><string>2026-07-15T00:00:00Z</string>
          <key>codeHash</key><string>example</string>
        </dict></plist>
        """
    let context = try PropertyListDecoder().decode(
        MiAoInstallationContext.self,
        from: Data(plist.utf8)
    )
    #expect(context.repositoryRoot == "/tmp/mi-ao-source")
    #expect(context.runtimeRoot == "/Applications/米遥.app/Contents/Resources/Runtime")
    #expect(context.isSelfContained)
}
