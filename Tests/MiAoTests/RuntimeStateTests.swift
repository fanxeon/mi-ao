// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import Foundation
import Testing

@testable import MiAo

@Test func externalProcessEnvironmentDropsEveryInternalMiAoVariable() {
    let sanitized = MiAoProcessEnvironment.sanitizedForExternalProcess([
        "HOME": "/Users/test",
        "PATH": "/usr/bin",
        "VOICE_BRIDGE_MODEL_DIR": "/tmp/model",
        "MI_AO_APP_BUNDLE": "/stale",
        "MI_AO_FUTURE_INTERNAL_STATE": "must-not-leak",
        "MI_AO_RUNTIME_TOKEN": "secret",
    ])

    #expect(
        sanitized == [
            "HOME": "/Users/test",
            "PATH": "/usr/bin",
            "VOICE_BRIDGE_MODEL_DIR": "/tmp/model",
        ]
    )
}

@Test func runtimeLaunchPlanUsesInstalledRuntimePreferencesAndCleanEnvironment() throws {
    let context = MiAoInstallationContext(
        repositoryRoot: "/tmp/source",
        runtimeRoot: "/Applications/米遥.app/Contents/Resources/Runtime",
        version: "2.0.0",
        installedAt: "2026-07-16T00:00:00Z",
        codeHash: "hash"
    )
    var preferences = AppPreferences.defaults
    preferences.preferredPeripheralIdentifier = UUID(
        uuidString: "11111111-2222-3333-4444-555555555555"
    )
    let plan = AppRuntimeLaunchPlan.make(
        context: context,
        preferences: preferences,
        environment: ["PATH": "/usr/bin", "MI_AO_APP_BUNDLE": "/stale", "MI_AO_RUNTIME_TOKEN": "secret"]
    )

    #expect(plan.executableURL.path == "/bin/zsh")
    #expect(plan.currentDirectoryURL.path == "/Applications/米遥.app/Contents/Resources/Runtime")
    #expect(plan.arguments.first?.hasSuffix("/Runtime/scripts/start.sh") == true)
    #expect(plan.arguments.contains("11111111-2222-3333-4444-555555555555"))
    #expect(plan.environment == ["PATH": "/usr/bin"])
}

@Test func deviceSelectionHonorsPreferredIdentifierBeforeSignalStrength() {
    let preferred = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
    let other = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
    let candidates = [
        BLEDeviceCandidate(identifier: other, name: "Xiaomi Remote", rssi: -30, advertisesATVV: true),
        BLEDeviceCandidate(identifier: preferred, name: "Xiaomi Remote", rssi: -80, advertisesATVV: true),
    ]
    let policy = BLEDeviceSelectionPolicy(
        preferredIdentifier: preferred,
        nameFilter: "Xiaomi"
    )

    #expect(policy.bestCandidate(from: candidates)?.identifier == preferred)
    #expect(!policy.accepts(candidates[0]))
}

@Test func deviceSelectionArbitratesCompatibleDevicesDeterministically() {
    let weaker = BLEDeviceCandidate(
        identifier: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
        name: "Other ATVV",
        rssi: -70,
        advertisesATVV: true
    )
    let strongerNameMatch = BLEDeviceCandidate(
        identifier: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
        name: "小米蓝牙语音遥控器",
        rssi: -45,
        advertisesATVV: true
    )
    let unrelated = BLEDeviceCandidate(
        identifier: UUID(),
        name: "Headphones",
        rssi: -10,
        advertisesATVV: false
    )
    let policy = BLEDeviceSelectionPolicy(
        preferredIdentifier: nil,
        nameFilter: "小米蓝牙语音遥控器"
    )

    #expect(policy.bestCandidate(from: [weaker, unrelated, strongerNameMatch]) == strongerNameMatch)
}

@Test func reconnectBackoffCapsAndResets() {
    var backoff = ReconnectBackoff(initialDelay: 1, maximumDelay: 5)
    #expect(backoff.nextDelay() == 1)
    #expect(backoff.nextDelay() == 2)
    #expect(backoff.nextDelay() == 4)
    #expect(backoff.nextDelay() == 5)
    #expect(backoff.nextDelay() == 5)
    backoff.reset()
    #expect(backoff.nextDelay() == 1)
}

@Test func alwaysReadyReconnectsIndefinitelyAtItsLowFrequencyCeiling() {
    var policy = VoiceReconnectPolicy(mode: .alwaysReady)

    let decisions = (1...10).map { _ in policy.nextDecision() }

    #expect(
        decisions == [
            .retry(attempt: 1, delay: 1),
            .retry(attempt: 2, delay: 2),
            .retry(attempt: 3, delay: 4),
            .retry(attempt: 4, delay: 8),
            .retry(attempt: 5, delay: 16),
            .retry(attempt: 6, delay: 32),
            .retry(attempt: 7, delay: 60),
            .retry(attempt: 8, delay: 60),
            .retry(attempt: 9, delay: 60),
            .retry(attempt: 10, delay: 60),
        ]
    )
}

@Test func smartSleepPausesAfterTwoAttemptsAndModeChangesResetTheBudget() {
    var policy = VoiceReconnectPolicy(mode: .smartSleep)

    #expect(policy.nextDecision() == .retry(attempt: 1, delay: 1))
    #expect(policy.nextDecision() == .retry(attempt: 2, delay: 2))
    #expect(policy.nextDecision() == .sleep)
    #expect(policy.nextDecision() == .sleep)

    policy.updateMode(.alwaysReady)
    #expect(policy.nextDecision() == .retry(attempt: 1, delay: 1))
}

@Test func capabilityNegotiationRetriesBeforeRequestingReconnect() {
    let policy = CapabilityNegotiationPolicy(retryDelay: 2, maximumRequests: 3)

    #expect(policy.retryDelay == 2)
    #expect(policy.decision(afterRequestCount: 1) == .retry)
    #expect(policy.decision(afterRequestCount: 2) == .retry)
    #expect(policy.decision(afterRequestCount: 3) == .reconnect)
}

@Test func capabilityNegotiationPolicyClampsUnsafeConfiguration() {
    let policy = CapabilityNegotiationPolicy(retryDelay: 0, maximumRequests: 0)

    #expect(policy.retryDelay == 0.1)
    #expect(policy.maximumRequests == 1)
    #expect(policy.decision(afterRequestCount: 1) == .reconnect)
}

@Test func remoteDeviceCatalogMergesDiscoveryAndRanksConnectedFirst() {
    let connectedID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
    let nearbyID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
    var catalog = RemoteDeviceCatalog()
    catalog.upsert(
        RemoteDeviceRecord(
            identifier: connectedID,
            name: "小米遥控器",
            rssi: -127,
            advertisesATVV: true,
            isConnected: true
        )
    )
    catalog.upsert(
        RemoteDeviceRecord(
            identifier: nearbyID,
            name: "附近遥控器",
            rssi: -20,
            advertisesATVV: true,
            isConnected: false
        )
    )
    catalog.upsert(
        RemoteDeviceRecord(
            identifier: connectedID,
            name: "小米蓝牙语音遥控器 2 Pro",
            rssi: -55,
            advertisesATVV: false,
            isConnected: false
        )
    )

    #expect(catalog.sortedRecords.first?.identifier == connectedID)
    #expect(catalog.sortedRecords.first?.name == "小米蓝牙语音遥控器 2 Pro")
    #expect(catalog.sortedRecords.first?.rssi == -55)
    #expect(catalog.sortedRecords.first?.isConnected == true)
}

@Test func hidEventReducerPairsPressReleaseAndIgnoresRepeats() {
    let key = HIDUsageKey(page: 0x0C, usage: 0xE9)
    let arrayUsage = Int(UInt32.max)
    var reducer = HIDButtonEventReducer()
    let map = [key: RemoteButton.volumeUp]

    #expect(
        reducer.reduce(page: 0x0C, elementUsage: arrayUsage, rawValue: 0xE9, buttonsByUsage: map)
            == [.buttonDown(.volumeUp)]
    )
    #expect(
        reducer.reduce(page: 0x0C, elementUsage: arrayUsage, rawValue: 0xE9, buttonsByUsage: map)
            .isEmpty
    )
    #expect(
        reducer.reduce(page: 0x0C, elementUsage: arrayUsage, rawValue: 0, buttonsByUsage: map)
            == [.buttonUp(.volumeUp)]
    )
    #expect(reducer.activeButton == nil)
}

@Test func hidEventReducerReleasesPreviousMappedButtonBeforeNext() {
    let firstKey = HIDUsageKey(page: 0x0C, usage: 0xE9)
    let secondKey = HIDUsageKey(page: 0x0C, usage: 0xEA)
    let map = [firstKey: RemoteButton.volumeUp, secondKey: RemoteButton.volumeDown]
    let arrayUsage = Int(UInt32.max)
    var reducer = HIDButtonEventReducer()

    _ = reducer.reduce(
        page: 0x0C,
        elementUsage: arrayUsage,
        rawValue: 0xE9,
        buttonsByUsage: map
    )
    #expect(
        reducer.reduce(page: 0x0C, elementUsage: arrayUsage, rawValue: 0xEA, buttonsByUsage: map)
            == [.buttonUp(.volumeUp), .buttonDown(.volumeDown)]
    )
}
