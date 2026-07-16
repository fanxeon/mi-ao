// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import Foundation

enum MiAoProcessEnvironment {
    static func sanitizedForExternalProcess(
        _ environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> [String: String] {
        environment.filter { !$0.key.hasPrefix("MI_AO_") }
    }
}
