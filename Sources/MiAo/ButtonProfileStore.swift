// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import Foundation

struct HIDUsageKey: Hashable {
    let page: Int
    let usage: Int
}

struct CalibratedButtonMap {
    let vendorID: Int
    let productID: Int
    let productName: String
    let buttonsByUsage: [HIDUsageKey: RemoteButton]
    let usagesByButton: [RemoteButton: HIDUsageKey]
    let sourceFiles: [URL]
}

enum ButtonProfileStore {
    static func loadConfirmedMap(
        file: String,
        preset: ButtonPreset
    ) throws -> CalibratedButtonMap? {
        let url = URL(fileURLWithPath: file)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let profile = try decoder.decode(ButtonProfile.self, from: Data(contentsOf: url))
        guard profile.captureMode == "confirmed_calibration" else {
            throw BridgeError.configuration("指定档案不是人工确认的 calibration：\(file)")
        }
        return try buildMap(from: [(profile, url)], preset: preset)
    }

    static func loadConfirmedMap(
        directory: String,
        preset: ButtonPreset,
        vendorID: Int,
        productID: Int,
        baseline: CalibratedButtonMap? = nil
    ) throws -> CalibratedButtonMap? {
        let directoryURL = URL(fileURLWithPath: directory, isDirectory: true)
        let urls =
            (try? FileManager.default.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: nil
            )) ?? []

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let profiles: [(ButtonProfile, URL)] =
            urls
            .filter { $0.pathExtension == "json" }
            .compactMap { url in
                guard let data = try? Data(contentsOf: url),
                    let profile = try? decoder.decode(ButtonProfile.self, from: data),
                    profile.captureMode == "confirmed_calibration",
                    profile.device.vendorID == vendorID,
                    profile.device.productID == productID
                else { return nil }
                return (profile, url)
            }
            .sorted { $0.0.generatedAt < $1.0.generatedAt }

        return try buildMap(from: profiles, preset: preset, baseline: baseline)
    }

    static func buildMap(
        from profiles: [(ButtonProfile, URL)],
        preset: ButtonPreset,
        baseline: CalibratedButtonMap? = nil
    ) throws -> CalibratedButtonMap? {
        guard let lastProfile = profiles.last?.0 else { return baseline }
        var usagesByButton = baseline?.usagesByButton ?? [:]
        var sourceByButton: [RemoteButton: URL] = [:]
        if let baseline, let sourceURL = baseline.sourceFiles.first {
            for button in baseline.usagesByButton.keys {
                sourceByButton[button] = sourceURL
            }
        }

        for (profile, url) in profiles {
            for observation in profile.observations {
                guard let button = RemoteButton(rawValue: observation.button) else { continue }
                guard observation.status == .observed,
                    observation.pressObserved,
                    observation.releaseObserved,
                    let page = observation.usagePage,
                    let usage = observation.usage
                else {
                    usagesByButton.removeValue(forKey: button)
                    sourceByButton.removeValue(forKey: button)
                    continue
                }
                usagesByButton[button] = HIDUsageKey(page: page, usage: usage)
                sourceByButton[button] = url
            }
        }

        guard preset.requiredButtons.isSubset(of: Set(usagesByButton.keys)) else { return nil }

        var buttonsByUsage: [HIDUsageKey: RemoteButton] = [:]
        for (button, key) in usagesByButton {
            if let existing = buttonsByUsage[key], existing != button {
                throw BridgeError.configuration(
                    String(
                        format: "按键校准冲突：%@ 与 %@ 都是 page 0x%02X usage 0x%02X，请分别重测",
                        existing.rawValue,
                        button.rawValue,
                        key.page,
                        key.usage
                    )
                )
            }
            buttonsByUsage[key] = button
        }

        return CalibratedButtonMap(
            vendorID: lastProfile.device.vendorID,
            productID: lastProfile.device.productID,
            productName: lastProfile.device.productName,
            buttonsByUsage: buttonsByUsage,
            usagesByButton: usagesByButton,
            sourceFiles: Array(Set(sourceByButton.values)).sorted { $0.path < $1.path }
        )
    }
}
