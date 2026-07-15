// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import AppKit
import Darwin
import Foundation

var runtimeSessionNeedsCleanup = false
do {
    let configuration = try Configuration.parse(CommandLine.arguments)
    if configuration.mode == .launch {
        let snapshot = AppPreferencesStore().load()
        do {
            let message = try AppRuntimeLauncher().start(preferences: snapshot.preferences)
            if !message.isEmpty { print(message) }
            exit(0)
        } catch {
            fputs("自动启动失败：\(error.localizedDescription)\n", stderr)
            let setupWindowController = SetupGuideWindowController(
                configuration: configuration,
                standalone: true
            )
            setupWindowController.showWindow(nil)
            NSApplication.shared.run()
            exit(1)
        }
    }
    if configuration.mode == .setup {
        let setupWindowController = SetupGuideWindowController(
            configuration: configuration,
            standalone: true
        )
        setupWindowController.showWindow(nil)
        NSApplication.shared.run()
        exit(0)
    }
    if configuration.mode == .learnButtons || configuration.mode == .debugButtons {
        let learner = ButtonLearner(configuration: configuration)
        try learner.start()
        while !learner.isFinished {
            _ = RunLoop.main.run(mode: .default, before: .distantFuture)
        }
        if learner.exitStatus != 0 { exit(learner.exitStatus) }
        exit(0)
    }
    if configuration.mode == .checkButtons {
        try ButtonRuntimeFactory.validate(configuration: configuration)
        if let path = configuration.resolvedProfilePath {
            try ButtonRuntimeFactory.writeResolvedProfile(configuration: configuration, to: path)
        }
        exit(0)
    }
    var menuBarController: MenuBarController?
    var terminationSignalSource: DispatchSourceSignal?
    if configuration.mode == .run {
        runtimeSessionNeedsCleanup = true
        menuBarController = MenuBarController(configuration: configuration)
    }
    let bridge = BLEVoiceBridge(
        configuration: configuration,
        statusHandler: { [weak menuBarController] status in
            menuBarController?.update(status: status)
        }
    )
    menuBarController?.onQuit = { [weak bridge] in bridge?.requestShutdown() }
    if configuration.mode == .run {
        signal(SIGTERM, SIG_IGN)
        terminationSignalSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        terminationSignalSource?.setEventHandler { [weak bridge] in bridge?.requestShutdown() }
        terminationSignalSource?.resume()
    }
    try bridge.start()
    var buttonController: HIDButtonController?
    if configuration.mode == .run {
        do {
            buttonController = try ButtonRuntimeFactory.make(
                configuration: configuration,
                controlModeHandler: { [weak menuBarController] mode in
                    menuBarController?.update(controlMode: mode)
                },
                presetChangeHandler: { [weak menuBarController] preset in
                    menuBarController?.update(preset: preset)
                }
            )
            try buttonController?.start()
        } catch {
            fputs("实体按键动作已禁用：\(error.localizedDescription)\n", stderr)
            buttonController = nil
        }
    }
    if configuration.mode == .scan || configuration.mode == .capture || configuration.mode == .run {
        while !bridge.isFinished {
            _ = RunLoop.main.run(mode: .default, before: .distantFuture)
        }
        buttonController?.stop()
        terminationSignalSource?.cancel()
        RuntimeSessionCleanup.perform()
        runtimeSessionNeedsCleanup = false
        if bridge.exitStatus != 0 { exit(bridge.exitStatus) }
    }
} catch {
    if runtimeSessionNeedsCleanup { RuntimeSessionCleanup.perform() }
    fputs("错误：\(error.localizedDescription)\n", stderr)
    exit(1)
}
