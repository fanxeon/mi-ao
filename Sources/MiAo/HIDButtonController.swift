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
    private let preset: ButtonPreset
    private let executor: PointerActionExecutor
    private let suppressor = RemoteEventSuppressor()
    private var manager: IOHIDManager?
    private var matchedDevice: IOHIDDevice?
    private var activeKey: HIDUsageKey?
    private var activeButton: RemoteButton?
    private let openOptions = IOOptionBits(kIOHIDOptionsTypeNone)

    init(configuration: Configuration, map: CalibratedButtonMap, preset: ButtonPreset) {
        self.configuration = configuration
        self.map = map
        self.preset = preset
        executor = PointerActionExecutor(preset: preset)
    }

    deinit {
        stop()
    }

    func start() throws {
        guard AXIsProcessTrusted() else {
            throw BridgeError.configuration("实体按键动作需要辅助功能权限；请先运行 scripts/authorize.sh")
        }
        try suppressor.start()
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
            suppressor.stop()
            throw BridgeError.configuration(
                "无法打开遥控器 HID（IOReturn \(result)）；实体按键动作已拒绝启动"
            )
        }
        executor.start()
        print("按键套装：\(preset.name)（\(preset.id)），等待遥控器 HID…")
    }

    func stop() {
        executor.stop()
        suppressor.stop()
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

        if rawValue == 0 {
            if let activeButton {
                suppressor.record(isDown: false)
                executor.buttonUp(activeButton)
            }
            activeKey = nil
            activeButton = nil
            return
        }

        let page = Int(IOHIDElementGetUsagePage(element))
        let elementUsage = Int(IOHIDElementGetUsage(element))
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
        if let button = map.buttonsByUsage[key], preset.action(for: button) != .unmapped {
            activeButton = button
        } else {
            activeButton = nil
        }
        if let activeButton {
            suppressor.record(isDown: true)
            executor.buttonDown(activeButton)
        }
    }
}

enum ButtonRuntimeFactory {
    static func make(configuration: Configuration) throws -> HIDButtonController? {
        guard configuration.buttonsEnabled else {
            print("实体按键动作：已通过 --no-buttons 禁用")
            return nil
        }
        let preset = try ButtonPreset.named(configuration.buttonPresetID)
        let map: CalibratedButtonMap?
        if let path = configuration.buttonProfilePath {
            map = try ButtonProfileStore.loadConfirmedMap(file: path, preset: preset)
        } else {
            map = try ButtonProfileStore.loadConfirmedMap(
                directory: configuration.buttonProfileDirectory,
                preset: preset,
                vendorID: configuration.hidVendorID,
                productID: configuration.hidProductID
            )
        }

        guard let map else {
            let required = preset.requiredButtons.map(\.rawValue).sorted().joined(separator: ", ")
            print("实体按键动作未启动：缺少 \(preset.id) 必需的人工确认校准（\(required)）")
            print("请运行：./scripts/debug-buttons.sh --name \"小米蓝牙语音遥控器\"")
            return nil
        }
        print("已加载 \(map.sourceFiles.count) 份人工确认校准档案")
        return HIDButtonController(configuration: configuration, map: map, preset: preset)
    }
}
