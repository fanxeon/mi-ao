// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import Foundation

struct HIDElementSignature: Equatable {
    let page: Int
    let usage: Int
}

enum HIDButtonEvent: Equatable {
    case buttonDown(RemoteButton)
    case buttonUp(RemoteButton)
}

struct HIDButtonEventReducer {
    private(set) var activeKey: HIDUsageKey?
    private(set) var activeElement: HIDElementSignature?
    private(set) var activeButton: RemoteButton?

    mutating func reduce(
        page: Int,
        elementUsage: Int,
        rawValue: Int,
        buttonsByUsage: [HIDUsageKey: RemoteButton]
    ) -> [HIDButtonEvent] {
        let signature = HIDElementSignature(page: page, usage: elementUsage)
        if rawValue == 0 {
            guard signature == activeElement else { return [] }
            defer { clear() }
            return activeButton.map { [.buttonUp($0)] } ?? []
        }

        guard
            let usage = ButtonLearner.normalizedUsage(
                elementUsage: elementUsage,
                rawValues: [rawValue]
            )
        else { return [] }
        let key = HIDUsageKey(page: page, usage: usage)
        guard key != activeKey else { return [] }

        var events: [HIDButtonEvent] = []
        if let activeButton { events.append(.buttonUp(activeButton)) }
        activeKey = key
        activeElement = signature
        activeButton = buttonsByUsage[key]
        if let activeButton { events.append(.buttonDown(activeButton)) }
        return events
    }

    mutating func clear() {
        activeKey = nil
        activeElement = nil
        activeButton = nil
    }
}
