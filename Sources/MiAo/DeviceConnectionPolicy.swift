// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import Foundation

struct BLEDeviceCandidate: Equatable {
    let identifier: UUID
    let name: String?
    let rssi: Int
    let advertisesATVV: Bool

    func matches(nameFilter: String?) -> Bool {
        guard let nameFilter = nameFilter?.trimmingCharacters(in: .whitespacesAndNewlines),
            !nameFilter.isEmpty
        else { return false }
        return name?.localizedCaseInsensitiveContains(nameFilter) == true
    }
}

struct BLEDeviceSelectionPolicy {
    let preferredIdentifier: UUID?
    let nameFilter: String?

    func accepts(_ candidate: BLEDeviceCandidate) -> Bool {
        if let preferredIdentifier {
            return candidate.identifier == preferredIdentifier
        }
        return candidate.advertisesATVV || candidate.matches(nameFilter: nameFilter)
    }

    func bestCandidate(from candidates: [BLEDeviceCandidate]) -> BLEDeviceCandidate? {
        candidates.filter(accepts).sorted(by: ranksBefore).first
    }

    private func ranksBefore(_ lhs: BLEDeviceCandidate, _ rhs: BLEDeviceCandidate) -> Bool {
        if let preferredIdentifier {
            let lhsPreferred = lhs.identifier == preferredIdentifier
            let rhsPreferred = rhs.identifier == preferredIdentifier
            if lhsPreferred != rhsPreferred { return lhsPreferred }
        }

        let lhsNameMatch = lhs.matches(nameFilter: nameFilter)
        let rhsNameMatch = rhs.matches(nameFilter: nameFilter)
        if lhsNameMatch != rhsNameMatch { return lhsNameMatch }
        if lhs.advertisesATVV != rhs.advertisesATVV { return lhs.advertisesATVV }
        if lhs.rssi != rhs.rssi { return lhs.rssi > rhs.rssi }
        return lhs.identifier.uuidString < rhs.identifier.uuidString
    }
}

struct ReconnectBackoff: Equatable {
    private(set) var attempt = 0
    let initialDelay: TimeInterval
    let maximumDelay: TimeInterval

    init(initialDelay: TimeInterval = 1, maximumDelay: TimeInterval = 20) {
        self.initialDelay = initialDelay
        self.maximumDelay = maximumDelay
    }

    mutating func nextDelay() -> TimeInterval {
        let exponent = min(attempt, 8)
        let delay = min(maximumDelay, initialDelay * pow(2, Double(exponent)))
        attempt += 1
        return delay
    }

    mutating func reset() {
        attempt = 0
    }
}

enum CapabilityNegotiationDecision: Equatable {
    case retry
    case reconnect
}

struct CapabilityNegotiationPolicy: Equatable {
    let retryDelay: TimeInterval
    let maximumRequests: Int

    init(retryDelay: TimeInterval = 1.5, maximumRequests: Int = 3) {
        self.retryDelay = max(0.1, retryDelay)
        self.maximumRequests = max(1, maximumRequests)
    }

    func decision(afterRequestCount requestCount: Int) -> CapabilityNegotiationDecision {
        requestCount < maximumRequests ? .retry : .reconnect
    }
}
