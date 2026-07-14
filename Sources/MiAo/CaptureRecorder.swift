// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import CryptoKit
import Foundation

struct CaptureDeviceRecord: Codable, Equatable {
    let id: String
    var name: String
    var firstSeenAt: Date
    var lastSeenAt: Date
    var strongestRSSI: Int
    var latestRSSI: Int
    var advertisedServices: [String]
}

struct CaptureCharacteristicRecord: Codable, Equatable {
    let uuid: String
    let properties: [String]
    let rawProperties: UInt
    var descriptors: [String]
}

struct CaptureServiceRecord: Codable, Equatable {
    let uuid: String
    let isPrimary: Bool
    var characteristics: [CaptureCharacteristicRecord]
}

struct CapturePrivacyRecord: Codable, Equatable {
    let identifiers: String
    let deviceNames: String
    let payloads: String
}

struct CaptureSummaryRecord: Codable, Equatable {
    let discoveredDevices: Int
    let connected: Bool
    let services: Int
    let characteristics: Int
    let descriptors: Int
    let values: Int
    let payloadBytes: Int
    let atvvDetected: Bool
    let ioErrors: [String]
}

struct CaptureReport: Codable, Equatable {
    let schemaVersion: Int
    let sessionID: String
    let startedAt: Date
    let endedAt: Date
    let finishReason: String
    let appVersion: String
    let operatingSystem: String
    let privacy: CapturePrivacyRecord
    let target: CaptureDeviceRecord?
    let devices: [CaptureDeviceRecord]
    let services: [CaptureServiceRecord]
    let summary: CaptureSummaryRecord
    let eventsFile: String
}

struct CaptureEventRecord: Codable, Equatable {
    let timestamp: Date
    let type: String
    let detail: String?
    let deviceID: String?
    let serviceUUID: String?
    let characteristicUUID: String?
    let dataHex: String?
    let byteCount: Int?
}

final class CaptureRecorder {
    let sessionDirectory: URL
    let reportURL: URL
    let eventsURL: URL

    private let includeIdentifiers: Bool
    private let includeDeviceNames: Bool
    private let sessionID: UUID
    private let startedAt: Date
    private let appVersion: String
    private let eventEncoder: JSONEncoder
    private let eventHandle: FileHandle
    private var devices: [String: CaptureDeviceRecord] = [:]
    private var targetID: String?
    private var services: [String: CaptureServiceRecord] = [:]
    private var connected = false
    private var valueCount = 0
    private var payloadBytes = 0
    private var atvvDetected = false
    private var ioErrors: [String] = []
    private var finished = false

    init(
        directory: String,
        includeIdentifiers: Bool,
        includeDeviceNames: Bool,
        sessionID: UUID = UUID(),
        startedAt: Date = Date(),
        appVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "development"
    ) throws {
        self.includeIdentifiers = includeIdentifiers
        self.includeDeviceNames = includeDeviceNames
        self.sessionID = sessionID
        self.startedAt = startedAt
        self.appVersion = appVersion

        let root = URL(fileURLWithPath: directory, isDirectory: true)
        let stamp = Self.fileStamp(startedAt)
        sessionDirectory = root.appendingPathComponent(
            "capture-\(stamp)-\(sessionID.uuidString.lowercased().prefix(8))",
            isDirectory: true
        )
        reportURL = sessionDirectory.appendingPathComponent("report.json")
        eventsURL = sessionDirectory.appendingPathComponent("events.jsonl")

        try FileManager.default.createDirectory(
            at: sessionDirectory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        guard
            FileManager.default.createFile(
                atPath: eventsURL.path,
                contents: nil,
                attributes: [.posixPermissions: 0o600]
            )
        else {
            throw BridgeError.configuration("无法创建采集事件文件：\(eventsURL.path)")
        }
        eventHandle = try FileHandle(forWritingTo: eventsURL)
        eventEncoder = JSONEncoder()
        eventEncoder.dateEncodingStrategy = .iso8601

        appendEvent(type: "session_started", detail: "capture session created")
    }

    deinit {
        try? eventHandle.close()
    }

    @discardableResult
    func recordDiscovery(
        identifier: UUID,
        name: String,
        rssi: Int,
        advertisedServices: [String],
        at date: Date = Date()
    ) -> Bool {
        let id = persistedIdentifier(identifier)
        let persistedName = self.persistedName(name)
        let normalizedServices = Array(Set(advertisedServices.map { $0.uppercased() })).sorted()
        let isNew = devices[id] == nil

        if var device = devices[id] {
            device.lastSeenAt = date
            device.latestRSSI = rssi
            device.strongestRSSI = max(device.strongestRSSI, rssi)
            device.advertisedServices = Array(Set(device.advertisedServices + normalizedServices)).sorted()
            devices[id] = device
        } else {
            devices[id] = CaptureDeviceRecord(
                id: id,
                name: persistedName,
                firstSeenAt: date,
                lastSeenAt: date,
                strongestRSSI: rssi,
                latestRSSI: rssi,
                advertisedServices: normalizedServices
            )
            appendEvent(
                type: "device_discovered",
                detail: "rssi=\(rssi)",
                persistedDeviceID: id
            )
        }
        return isNew
    }

    func setTarget(identifier: UUID, name: String, at date: Date = Date()) {
        let id = persistedIdentifier(identifier)
        targetID = id
        if devices[id] == nil {
            devices[id] = CaptureDeviceRecord(
                id: id,
                name: persistedName(name),
                firstSeenAt: date,
                lastSeenAt: date,
                strongestRSSI: 0,
                latestRSSI: 0,
                advertisedServices: []
            )
        }
        appendEvent(type: "target_selected", persistedDeviceID: id)
    }

    func recordConnection(identifier: UUID, connected: Bool, detail: String? = nil) {
        self.connected = self.connected || connected
        appendEvent(
            type: connected ? "connected" : "disconnected",
            detail: detail,
            persistedDeviceID: persistedIdentifier(identifier)
        )
    }

    func recordService(_ uuid: String, isPrimary: Bool) {
        let normalized = uuid.uppercased()
        if services[normalized] == nil {
            services[normalized] = CaptureServiceRecord(
                uuid: normalized,
                isPrimary: isPrimary,
                characteristics: []
            )
            appendEvent(
                type: "service_discovered",
                detail: isPrimary ? "primary" : "secondary",
                serviceUUID: normalized
            )
        }
        if normalized == ATVVProtocol.serviceUUID { atvvDetected = true }
    }

    func recordCharacteristic(
        serviceUUID: String,
        uuid: String,
        properties: [String],
        rawProperties: UInt
    ) {
        let normalizedService = serviceUUID.uppercased()
        let normalizedUUID = uuid.uppercased()
        if services[normalizedService] == nil {
            services[normalizedService] = CaptureServiceRecord(
                uuid: normalizedService,
                isPrimary: true,
                characteristics: []
            )
        }
        let record = CaptureCharacteristicRecord(
            uuid: normalizedUUID,
            properties: properties.sorted(),
            rawProperties: rawProperties,
            descriptors: []
        )
        if services[normalizedService]?.characteristics.contains(where: { $0.uuid == normalizedUUID }) == false {
            services[normalizedService]?.characteristics.append(record)
        }
        appendEvent(
            type: "characteristic_discovered",
            detail: properties.sorted().joined(separator: ","),
            serviceUUID: normalizedService,
            characteristicUUID: normalizedUUID
        )
    }

    func recordDescriptor(serviceUUID: String, characteristicUUID: String, uuid: String) {
        let normalizedService = serviceUUID.uppercased()
        let normalizedCharacteristic = characteristicUUID.uppercased()
        let normalizedDescriptor = uuid.uppercased()
        guard var service = services[normalizedService],
            let index = service.characteristics.firstIndex(where: { $0.uuid == normalizedCharacteristic })
        else { return }
        if !service.characteristics[index].descriptors.contains(normalizedDescriptor) {
            service.characteristics[index].descriptors.append(normalizedDescriptor)
            service.characteristics[index].descriptors.sort()
            services[normalizedService] = service
            appendEvent(
                type: "descriptor_discovered",
                detail: normalizedDescriptor,
                serviceUUID: normalizedService,
                characteristicUUID: normalizedCharacteristic
            )
        }
    }

    func recordValue(
        characteristicUUID: String,
        data: Data,
        detail: String? = nil
    ) {
        valueCount += 1
        payloadBytes += data.count
        appendEvent(
            type: "value",
            detail: detail,
            characteristicUUID: characteristicUUID.uppercased(),
            data: data
        )
    }

    func recordEvent(
        type: String,
        detail: String? = nil,
        deviceIdentifier: UUID? = nil,
        serviceUUID: String? = nil,
        characteristicUUID: String? = nil,
        data: Data? = nil
    ) {
        appendEvent(
            type: type,
            detail: detail,
            persistedDeviceID: deviceIdentifier.map(persistedIdentifier),
            serviceUUID: serviceUUID,
            characteristicUUID: characteristicUUID,
            data: data
        )
    }

    func finish(reason: String, at endedAt: Date = Date()) throws -> CaptureReport {
        if !finished {
            appendEvent(type: "session_finished", detail: reason)
            finished = true
            try eventHandle.synchronize()
            try eventHandle.close()
        }

        let sortedDevices = devices.values.sorted { $0.id < $1.id }
        let sortedServices = services.values
            .map { service in
                CaptureServiceRecord(
                    uuid: service.uuid,
                    isPrimary: service.isPrimary,
                    characteristics: service.characteristics.sorted { $0.uuid < $1.uuid }
                )
            }
            .sorted { $0.uuid < $1.uuid }
        let report = CaptureReport(
            schemaVersion: 1,
            sessionID: sessionID.uuidString.lowercased(),
            startedAt: startedAt,
            endedAt: endedAt,
            finishReason: reason,
            appVersion: appVersion,
            operatingSystem: ProcessInfo.processInfo.operatingSystemVersionString,
            privacy: CapturePrivacyRecord(
                identifiers: includeIdentifiers ? "included" : "sha256-prefix",
                deviceNames: includeDeviceNames ? "included" : "redacted",
                payloads: "included-locally-review-before-sharing"
            ),
            target: targetID.flatMap { devices[$0] },
            devices: sortedDevices,
            services: sortedServices,
            summary: CaptureSummaryRecord(
                discoveredDevices: sortedDevices.count,
                connected: connected,
                services: sortedServices.count,
                characteristics: sortedServices.reduce(0) { $0 + $1.characteristics.count },
                descriptors: sortedServices.reduce(0) { result, service in
                    result + service.characteristics.reduce(0) { $0 + $1.descriptors.count }
                },
                values: valueCount,
                payloadBytes: payloadBytes,
                atvvDetected: atvvDetected,
                ioErrors: ioErrors
            ),
            eventsFile: eventsURL.lastPathComponent
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        try encoder.encode(report).write(to: reportURL, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: reportURL.path)
        return report
    }

    private func appendEvent(
        type: String,
        detail: String? = nil,
        persistedDeviceID: String? = nil,
        serviceUUID: String? = nil,
        characteristicUUID: String? = nil,
        data: Data? = nil
    ) {
        guard !finished else { return }
        let event = CaptureEventRecord(
            timestamp: Date(),
            type: type,
            detail: detail,
            deviceID: persistedDeviceID,
            serviceUUID: serviceUUID?.uppercased(),
            characteristicUUID: characteristicUUID?.uppercased(),
            dataHex: data.map(Self.hex),
            byteCount: data?.count
        )
        do {
            var encoded = try eventEncoder.encode(event)
            encoded.append(0x0A)
            try eventHandle.write(contentsOf: encoded)
        } catch {
            ioErrors.append(error.localizedDescription)
        }
    }

    private func persistedIdentifier(_ identifier: UUID) -> String {
        if includeIdentifiers { return identifier.uuidString.lowercased() }
        let scopedIdentity = "\(sessionID.uuidString.lowercased()):\(identifier.uuidString.lowercased())"
        let digest = SHA256.hash(data: Data(scopedIdentity.utf8))
        return "device-\(digest.prefix(6).map { String(format: "%02x", $0) }.joined())"
    }

    private func persistedName(_ name: String) -> String {
        includeDeviceNames ? name : "(redacted)"
    }

    private static func hex(_ data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined(separator: " ")
    }

    private static func fileStamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        return formatter.string(from: date)
    }
}
