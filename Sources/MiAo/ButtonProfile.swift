// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import Foundation

struct ButtonProfile: Codable, Equatable {
    struct Device: Codable, Equatable {
        let vendorID: Int
        let productID: Int
        let productName: String
    }

    struct Observation: Codable, Equatable {
        enum Status: String, Codable {
            case observed
            case notObserved = "not_observed"
        }

        let button: String
        let label: String
        let expectedTransport: String
        let status: Status
        let usagePage: Int?
        let usage: Int?
        let elementUsage: Int?
        let rawValues: [Int]
        let pressObserved: Bool
        let releaseObserved: Bool
        let repeatCount: Int
        let note: String?
    }

    let schemaVersion: Int
    let captureMode: String?
    let generatedAt: Date
    let device: Device
    let privacy: String
    let observations: [Observation]
}

enum ButtonProfileWriter {
    static func write(
        _ profile: ButtonProfile,
        to directory: String,
        now: Date = Date()
    ) throws -> URL {
        let directoryURL = URL(fileURLWithPath: directory, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let url = directoryURL.appendingPathComponent(
            "buttons-\(formatter.string(from: now)).json"
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(profile).write(to: url, options: .atomic)
        return url
    }
}
