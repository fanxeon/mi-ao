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
    private struct ElementSignature: Equatable {
        let page: Int
        let usage: Int
    }

    private let configuration: Configuration
    private let map: CalibratedButtonMap
    private let preset: ButtonPreset
    private let executor: ButtonActionExecutor
    private var manager: IOHIDManager?
    private var matchedDevice: IOHIDDevice?
    private var activeKey: HIDUsageKey?
    private var activeElement: ElementSignature?
    private var activeButton: RemoteButton?
    private let openOptions = IOOptionBits(kIOHIDOptionsTypeNone)

    init(
        configuration: Configuration,
        map: CalibratedButtonMap,
        preset: ButtonPreset,
        controlModeHandler: ((RemoteControlMode) -> Void)? = nil
    ) {
        self.configuration = configuration
        self.map = map
        self.preset = preset
        executor = ButtonActionExecutor(
            preset: preset,
            debug: configuration.debug,
            controlModeHandler: controlModeHandler
        )
    }

    deinit {
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
        print("按键套装：\(preset.name)（\(preset.id)），等待遥控器 HID…")
    }

    func stop() {
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
        print("实体按键已就绪：\(name)，默认套装 \(preset.id)")
    }

    fileprivate func valueReceived(_ value: IOHIDValue, result: IOReturn) {
        guard result == kIOReturnSuccess, let matchedDevice else { return }
        let element = IOHIDValueGetElement(value)
        guard IOHIDElementGetDevice(element) == matchedDevice else { return }
        let rawValue = IOHIDValueGetIntegerValue(value)
        let page = Int(IOHIDElementGetUsagePage(element))
        let elementUsage = Int(IOHIDElementGetUsage(element))
        let elementSignature = ElementSignature(page: page, usage: elementUsage)

        if rawValue == 0 {
            guard elementSignature == activeElement else { return }
            if let activeButton {
                if configuration.debug {
                    print("HID 松手：\(activeButton.rawValue)")
                }
                executor.buttonUp(activeButton)
            }
            activeKey = nil
            activeElement = nil
            activeButton = nil
            return
        }

        guard
            let usage = ButtonLearner.normalizedUsage(
                elementUsage: elementUsage,
                rawValues: [rawValue]
            )
        else { return }
        let key = HIDUsageKey(page: page, usage: usage)
        guard key != activeKey else { return }

        if let activeButton { executor.buttonUp(activeButton) }
        activeKey = key
        activeElement = elementSignature
        if let button = map.buttonsByUsage[key], preset.action(for: button) != .unmapped {
            activeButton = button
        } else {
            activeButton = nil
        }
        if let activeButton {
            if configuration.debug {
                print(
                    String(
                        format: "HID 按下：page 0x%02X usage 0x%02X → %@",
                        page,
                        usage,
                        activeButton.rawValue
                    )
                )
            }
            executor.buttonDown(activeButton)
        }
    }
}

enum ButtonRuntimeFactory {
    private static func resolvedMap(configuration: Configuration) throws -> CalibratedButtonMap? {
        let preset = try ButtonPreset.named(configuration.buttonPresetID)
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
        guard try resolvedMap(configuration: configuration) != nil else {
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
        guard let map = try resolvedMap(configuration: configuration) else {
            throw BridgeError.configuration("没有可用的按键硬件档案，无法导出映射")
        }
        try HardwareProfileStore.write(baseline.replacingUsages(with: map), to: path)
        print("已导出解析后的硬件档案：\(path)")
    }

    static func make(
        configuration: Configuration,
        controlModeHandler: ((RemoteControlMode) -> Void)? = nil
    ) throws -> HIDButtonController? {
        guard configuration.buttonsEnabled else {
            print("实体按键动作：已通过 --no-buttons 禁用")
            return nil
        }
        let preset = try ButtonPreset.named(configuration.buttonPresetID)
        let map = try resolvedMap(configuration: configuration)

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
            controlModeHandler: controlModeHandler
        )
    }
}
