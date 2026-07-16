// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import CryptoKit
import Foundation

enum ModelIntegrityStatus: Equatable {
    case valid(byteCount: Int64)
    case missing
    case tooSmall(byteCount: Int64)
    case hashMismatch(actualSHA256: String)
    case contractMissing
    case unreadable
}

/// Verifies the exact speech model pinned by the release contract.
/// Setup may reuse a metadata-keyed result to avoid hashing the 148 MB model on
/// every UI refresh. The transcription boundary always requests a fresh hash.
final class ModelIntegrityVerifier {
    static let productionMinimumByteCount: Int64 = 1_000_000

    private struct CacheKey: Equatable {
        let path: String
        let byteCount: Int64
        let modificationDate: Date?
        let fileNumber: UInt64
    }

    private let expectedSHA256: String?
    private let minimumByteCount: Int64
    private let fileManager: FileManager
    private let cacheLock = NSLock()
    private var cachedResult: (key: CacheKey, status: ModelIntegrityStatus)?

    init(
        expectedSHA256: String?,
        minimumByteCount: Int64 = ModelIntegrityVerifier.productionMinimumByteCount,
        fileManager: FileManager = .default
    ) {
        let normalized = expectedSHA256?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        self.expectedSHA256 = Self.isValidSHA256(normalized) ? normalized : nil
        self.minimumByteCount = minimumByteCount
        self.fileManager = fileManager
    }

    static func production(fileManager: FileManager = .default) -> ModelIntegrityVerifier {
        ModelIntegrityVerifier(
            expectedSHA256: productionContractSHA256(fileManager: fileManager),
            fileManager: fileManager
        )
    }

    func verify(modelPath: String, useMetadataCache: Bool = false) -> ModelIntegrityStatus {
        guard let expectedSHA256 else { return .contractMissing }
        guard fileManager.fileExists(atPath: modelPath) else { return .missing }
        guard
            let attributes = try? fileManager.attributesOfItem(atPath: modelPath),
            let size = attributes[.size] as? NSNumber
        else {
            return .unreadable
        }

        let byteCount = size.int64Value
        guard byteCount > minimumByteCount else { return .tooSmall(byteCount: byteCount) }

        let key = CacheKey(
            path: URL(fileURLWithPath: modelPath).standardizedFileURL.path,
            byteCount: byteCount,
            modificationDate: attributes[.modificationDate] as? Date,
            fileNumber: (attributes[.systemFileNumber] as? NSNumber)?.uint64Value ?? 0
        )
        if useMetadataCache, let cached = cachedStatus(for: key) {
            return cached
        }

        let status: ModelIntegrityStatus
        guard let actualSHA256 = sha256(of: URL(fileURLWithPath: modelPath)) else {
            status = .unreadable
            store(status, for: key, when: useMetadataCache)
            return status
        }
        if actualSHA256 == expectedSHA256 {
            status = .valid(byteCount: byteCount)
        } else {
            status = .hashMismatch(actualSHA256: actualSHA256)
        }
        store(status, for: key, when: useMetadataCache)
        return status
    }

    private func cachedStatus(for key: CacheKey) -> ModelIntegrityStatus? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        guard cachedResult?.key == key else { return nil }
        return cachedResult?.status
    }

    private func store(
        _ status: ModelIntegrityStatus,
        for key: CacheKey,
        when shouldCache: Bool
    ) {
        guard shouldCache else { return }
        cacheLock.lock()
        cachedResult = (key, status)
        cacheLock.unlock()
    }

    private func sha256(of url: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        var hasher = SHA256()
        do {
            while true {
                let data = try handle.read(upToCount: 1_048_576) ?? Data()
                if data.isEmpty { break }
                hasher.update(data: data)
            }
        } catch {
            return nil
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    private static func productionContractSHA256(fileManager: FileManager) -> String? {
        let candidates = [
            Bundle.main.resourceURL?.appendingPathComponent("WhisperModel.sha256"),
            URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
                .appendingPathComponent("Resources/WhisperModel.sha256"),
        ].compactMap { $0 }

        for candidate in candidates {
            guard
                let value = try? String(contentsOf: candidate, encoding: .utf8)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased(),
                isValidSHA256(value)
            else { continue }
            return value
        }
        return nil
    }

    private static func isValidSHA256(_ value: String?) -> Bool {
        guard let value, value.count == 64 else { return false }
        return value.allSatisfy { $0.isHexDigit && !$0.isUppercase }
    }
}
