// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import Foundation

do {
    let configuration = try Configuration.parse(CommandLine.arguments)
    if configuration.mode == .learnButtons {
        let learner = ButtonLearner(configuration: configuration)
        try learner.start()
        while !learner.isFinished {
            _ = RunLoop.main.run(mode: .default, before: .distantFuture)
        }
        if learner.exitStatus != 0 { exit(learner.exitStatus) }
        exit(0)
    }
    let bridge = BLEVoiceBridge(configuration: configuration)
    try bridge.start()
    if configuration.mode == .scan || configuration.mode == .capture || configuration.mode == .run {
        while !bridge.isFinished {
            _ = RunLoop.main.run(mode: .default, before: .distantFuture)
        }
        if bridge.exitStatus != 0 { exit(bridge.exitStatus) }
    }
} catch {
    fputs("错误：\(error.localizedDescription)\n", stderr)
    exit(1)
}
