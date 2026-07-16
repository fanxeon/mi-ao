// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import ApplicationServices
import Foundation
import IOKit.hid

private func miAoRuntimeDeviceMatched(
    context: UnsafeMutableRawPointer?,
    result: IOReturn,
    sender: UnsafeMutableRawPointer?,
    device: IOHIDDevice
) {
    guard let context else { return }
    Unmanaged<HIDButtonController>.fromOpaque(context).takeUnretainedValue()
        .deviceMatched(device, result: result)
}

private func miAoRuntimeValueReceived(
    context: UnsafeMutableRawPointer?,
    result: IOReturn,
    sender: UnsafeMutableRawPointer?,
    value: IOHIDValue
) {
    guard let context else { return }
    Unmanaged<HIDButtonController>.fromOpaque(context).takeUnretainedValue()
        .valueReceived(value, result: result)
}

final class HIDButtonController {
    private let configuration: Configuration
    private let map: CalibratedButtonMap
    private let executor: ButtonActionExecutor
    private var manager: IOHIDManager?
    private var matchedDevice: IOHIDDevice?
    private var eventReducer = HIDButtonEventReducer()
    private let openOptions = IOOptionBits(kIOHIDOptionsTypeNone)

    init(
        configuration: Configuration,
        map: CalibratedButtonMap,
        preset: ButtonPreset,
        catalog: ButtonPresetCatalog,
        controlModeHandler: ((RemoteControlMode) -> Void)? = nil,
        presetChangeHandler: ((ButtonPreset) -> Void)? = nil,
        activityHandler: ((MiAoCommandActivity) -> Void)? = nil
    ) {
        self.configuration = configuration
        self.map = map
        executor = ButtonActionExecutor(
            preset: preset,
            catalog: catalog,
            debug: configuration.debug,
            controlModeHandler: controlModeHandler,
            presetChangeHandler: presetChangeHandler,
            activityHandler: activityHandler
        )
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(buttonConfigurationChanged),
            name: MiAoRuntimeNotifications.buttonConfigurationChanged,
            object: nil
        )
    }

    deinit {
        DistributedNotificationCenter.default().removeObserver(self)
        stop()
    }

    func start() throws {
        guard AXIsProcessTrusted() else {
            throw BridgeError.configuration("实体按键动作需要辅助功能权限；请先运行 scripts/authorize.sh")
        }
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        self.manager = manager
        IOHIDManagerSetDeviceMatching(
            manager,
            [
                kIOHIDVendorIDKey: map.vendorID,
                kIOHIDProductIDKey: map.productID,
            ] as CFDictionary
        )
        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(manager, miAoRuntimeDeviceMatched, context)
        IOHIDManagerRegisterInputValueCallback(manager, miAoRuntimeValueReceived, context)
        IOHIDManagerScheduleWithRunLoop(
            manager,
            CFRunLoopGetMain(),
            CFRunLoopMode.defaultMode.rawValue
        )
        let result = IOHIDManagerOpen(manager, openOptions)
        guard result == kIOReturnSuccess else {
            throw BridgeError.configuration(
                "无法打开遥控器 HID（IOReturn \(result)）；实体按键动作已拒绝启动"
            )
        }
        executor.start()
        print("按键配置：\(executor.preset.name)（\(executor.preset.id)），等待遥控器 HID…")
    }

    func stop() {
        if let activeButton = eventReducer.activeButton {
            executor.buttonUp(activeButton)
        }
        eventReducer.clear()
        executor.stop()
        guard let manager else { return }
        IOHIDManagerUnscheduleFromRunLoop(
            manager,
            CFRunLoopGetMain(),
            CFRunLoopMode.defaultMode.rawValue
        )
        IOHIDManagerClose(manager, openOptions)
        self.manager = nil
    }

    fileprivate func deviceMatched(_ device: IOHIDDevice, result: IOReturn) {
        guard result == kIOReturnSuccess, matchedDevice == nil else { return }
        let name = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String ?? "(unknown)"
        if let filter = configuration.nameFilter?.lowercased(),
            !name.lowercased().contains(filter)
        {
            return
        }
        matchedDevice = device
        print("实体按键已就绪：\(name)")
    }

    fileprivate func valueReceived(_ value: IOHIDValue, result: IOReturn) {
        guard result == kIOReturnSuccess, let matchedDevice else { return }
        let element = IOHIDValueGetElement(value)
        guard IOHIDElementGetDevice(element) == matchedDevice else { return }
        let rawValue = IOHIDValueGetIntegerValue(value)
        let page = Int(IOHIDElementGetUsagePage(element))
        let elementUsage = Int(IOHIDElementGetUsage(element))
        let events = eventReducer.reduce(
            page: page,
            elementUsage: elementUsage,
            rawValue: rawValue,
            buttonsByUsage: map.buttonsByUsage
        )
        for event in events {
            switch event {
            case .buttonDown(let button):
                MiAoRuntimeNotifications.postButtonActivity(button: button, isPressed: true)
                if configuration.debug {
                    print(
                        String(
                            format: "HID 按下：page 0x%02X usage 0x%02X → %@",
                            page,
                            eventReducer.activeKey?.usage ?? elementUsage,
                            button.rawValue
                        )
                    )
                }
                executor.buttonDown(button)
            case .buttonUp(let button):
                MiAoRuntimeNotifications.postButtonActivity(button: button, isPressed: false)
                if configuration.debug { print("HID 松手：\(button.rawValue)") }
                executor.buttonUp(button)
            }
        }
    }

    @objc private func buttonConfigurationChanged(_ notification: Notification) {
        let presetSnapshot = ButtonPresetStore().load()
        if case .unsupportedVersion(let version) = presetSnapshot.state {
            fputs("运行时未重载按键配置：schema v\(version) 过新\n", stderr)
            return
        }
        let preferencesSnapshot = AppPreferencesStore().load()
        if case .unsupportedVersion(let version) = preferencesSnapshot.state {
            fputs("运行时未重载按键选择：schema v\(version) 过新\n", stderr)
            return
        }
        do {
            let selected = try executor.replaceCatalog(
                presetSnapshot.catalog,
                selecting: preferencesSnapshot.preferences.selectedPresetID
            )
            print("按键配置已热更新：\(selected.name)")
        } catch {
            fputs("按键配置热更新失败：\(error.localizedDescription)\n", stderr)
        }
    }
}

enum ButtonRuntimeFactory {
    private static func resolvedCatalog() throws -> ButtonPresetCatalog {
        let snapshot = ButtonPresetStore().load()
        if case .unsupportedVersion(let version) = snapshot.state {
            throw ButtonPresetStoreError.unsupportedVersion(version)
        }
        return snapshot.catalog
    }

    private static func resolvedPreset(
        configuration: Configuration,
        catalog: ButtonPresetCatalog
    ) throws -> ButtonPreset {
        do {
            return try catalog.preset(id: configuration.buttonPresetID)
        } catch {
            guard configuration.buttonPresetID != ButtonPreset.pointer.id else { throw error }
            fputs(
                "找不到已保存的按键配置 \(configuration.buttonPresetID)，已安全回退到官方默认\n",
                stderr
            )
            return .pointer
        }
    }

    private static func resolvedMap(
        configuration: Configuration,
        preset: ButtonPreset
    ) throws -> CalibratedButtonMap? {
        if let path = configuration.buttonProfilePath {
            return try ButtonProfileStore.loadConfirmedMap(file: path, preset: preset)
        }

        let baseline = try HardwareProfileStore.loadBuiltIn(
            vendorID: configuration.hidVendorID,
            productID: configuration.hidProductID,
            preset: preset
        )
        return try ButtonProfileStore.loadConfirmedMap(
            directory: configuration.buttonProfileDirectory,
            preset: preset,
            vendorID: configuration.hidVendorID,
            productID: configuration.hidProductID,
            baseline: baseline
        )
    }

    static func validate(configuration: Configuration) throws {
        guard configuration.buttonsEnabled else {
            throw BridgeError.configuration("check-buttons 不能与 --no-buttons 同时使用")
        }
        guard AXIsProcessTrusted() else {
            throw BridgeError.configuration("实体按键动作需要辅助功能权限；请先运行 scripts/authorize.sh")
        }
        let catalog = try resolvedCatalog()
        let preset = try resolvedPreset(configuration: configuration, catalog: catalog)
        guard try resolvedMap(configuration: configuration, preset: preset) != nil else {
            throw BridgeError.configuration("没有可用的按键硬件档案，未修改系统映射")
        }
        print("按键运行时检查通过：权限和硬件档案均已就绪")
    }

    static func writeResolvedProfile(configuration: Configuration, to path: String) throws {
        guard
            let baseline = try HardwareProfileStore.loadBuiltInProfile(
                vendorID: configuration.hidVendorID,
                productID: configuration.hidProductID
            )
        else {
            throw BridgeError.configuration("没有匹配的内置硬件档案，无法导出映射")
        }
        let catalog = try resolvedCatalog()
        let preset = try resolvedPreset(configuration: configuration, catalog: catalog)
        guard let map = try resolvedMap(configuration: configuration, preset: preset) else {
            throw BridgeError.configuration("没有可用的按键硬件档案，无法导出映射")
        }
        try HardwareProfileStore.write(baseline.replacingUsages(with: map), to: path)
        print("已导出解析后的硬件档案：\(path)")
    }

    static func make(
        configuration: Configuration,
        controlModeHandler: ((RemoteControlMode) -> Void)? = nil,
        presetChangeHandler: ((ButtonPreset) -> Void)? = nil,
        activityHandler: ((MiAoCommandActivity) -> Void)? = nil
    ) throws -> HIDButtonController? {
        guard configuration.buttonsEnabled else {
            print("实体按键动作：已通过 --no-buttons 禁用")
            return nil
        }
        let catalog = try resolvedCatalog()
        let preset = try resolvedPreset(configuration: configuration, catalog: catalog)
        let map = try resolvedMap(configuration: configuration, preset: preset)

        guard let map else {
            let required = preset.requiredButtons.map(\.rawValue).sorted().joined(separator: ", ")
            print("实体按键动作未启动：缺少 \(preset.id) 必需的人工确认校准（\(required)）")
            print("请运行：./scripts/debug-buttons.sh --name \"小米蓝牙语音遥控器\"")
            return nil
        }
        print("已加载 \(map.sourceFiles.count) 份人工确认校准档案")
        return HIDButtonController(
            configuration: configuration,
            map: map,
            preset: preset,
            catalog: catalog,
            controlModeHandler: controlModeHandler,
            presetChangeHandler: { preset in
                let preferencesStore = AppPreferencesStore()
                let snapshot = preferencesStore.load()
                guard case .unsupportedVersion = snapshot.state else {
                    var preferences = snapshot.preferences
                    preferences.selectedPresetID = preset.id
                    do {
                        try preferencesStore.save(preferences)
                    } catch {
                        fputs("当前配置未能保存：\(error.localizedDescription)\n", stderr)
                    }
                    presetChangeHandler?(preset)
                    return
                }
                fputs("当前配置没有写入：偏好文件来自更新版本\n", stderr)
            },
            activityHandler: activityHandler
        )
    }
}
