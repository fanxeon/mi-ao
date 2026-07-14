// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import Foundation
import IOKit.hid

private func miAoHIDDeviceMatched(
    context: UnsafeMutableRawPointer?,
    result: IOReturn,
    sender: UnsafeMutableRawPointer?,
    device: IOHIDDevice
) {
    guard let context else { return }
    Unmanaged<ButtonLearner>.fromOpaque(context).takeUnretainedValue()
        .deviceMatched(device, result: result)
}

private func miAoHIDValueReceived(
    context: UnsafeMutableRawPointer?,
    result: IOReturn,
    sender: UnsafeMutableRawPointer?,
    value: IOHIDValue
) {
    guard let context else { return }
    Unmanaged<ButtonLearner>.fromOpaque(context).takeUnretainedValue()
        .valueReceived(value, result: result)
}

final class ButtonLearner {
    private struct Step {
        let id: String
        let label: String
        let expectedTransport: String
        let timeoutNote: String
    }

    private struct ActiveInput: Equatable {
        let usagePage: Int
        let usage: Int
    }

    private static let steps = [
        Step(id: "voice", label: "语音键", expectedTransport: "hid_or_atvv", timeoutNote: "未观察到 HID；语音链路可能仅通过 ATVV"),
        Step(id: "dpad_up", label: "方向上", expectedTransport: "hid", timeoutNote: "等待期内没有 HID 事件"),
        Step(id: "dpad_down", label: "方向下", expectedTransport: "hid", timeoutNote: "等待期内没有 HID 事件"),
        Step(id: "dpad_left", label: "方向左", expectedTransport: "hid", timeoutNote: "等待期内没有 HID 事件"),
        Step(id: "dpad_right", label: "方向右", expectedTransport: "hid", timeoutNote: "等待期内没有 HID 事件"),
        Step(id: "center", label: "中间确认键", expectedTransport: "hid", timeoutNote: "等待期内没有 HID 事件"),
        Step(id: "back", label: "返回键", expectedTransport: "hid", timeoutNote: "等待期内没有 HID 事件"),
        Step(id: "home", label: "主页键", expectedTransport: "hid", timeoutNote: "等待期内没有 HID 事件"),
        Step(id: "menu", label: "菜单键", expectedTransport: "hid", timeoutNote: "等待期内没有 HID 事件"),
        Step(id: "volume_up", label: "音量加", expectedTransport: "hid", timeoutNote: "等待期内没有 HID 事件"),
        Step(id: "volume_down", label: "音量减", expectedTransport: "hid", timeoutNote: "等待期内没有 HID 事件"),
        Step(id: "tv", label: "电视键", expectedTransport: "hid_or_ir", timeoutNote: "未观察到 HID；可能是红外键"),
        Step(id: "power", label: "电源键", expectedTransport: "hid_or_ir", timeoutNote: "未观察到 HID；可能是红外键"),
    ]

    private let configuration: Configuration
    private var manager: IOHIDManager?
    private var matchedDevice: IOHIDDevice?
    private var productName = "(redacted model name)"
    private var deviceWaitTimer: Timer?
    private var stepTimer: Timer?
    private var stepIndex = 0
    private var activeInput: ActiveInput?
    private var rawValues: [Int] = []
    private var repeatCount = 0
    private var observations: [ButtonProfile.Observation] = []
    private(set) var isFinished = false
    private(set) var exitStatus: Int32 = 0

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    deinit {
        closeManager()
    }

    func start() throws {
        try FileManager.default.createDirectory(
            atPath: configuration.buttonProfileDirectory,
            withIntermediateDirectories: true
        )

        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        self.manager = manager
        let matching: [String: Any] = [
            kIOHIDVendorIDKey: configuration.hidVendorID,
            kIOHIDProductIDKey: configuration.hidProductID,
        ]
        IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)
        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(manager, miAoHIDDeviceMatched, context)
        IOHIDManagerRegisterInputValueCallback(manager, miAoHIDValueReceived, context)
        IOHIDManagerScheduleWithRunLoop(
            manager,
            CFRunLoopGetMain(),
            CFRunLoopMode.defaultMode.rawValue
        )

        let result = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        guard result == kIOReturnSuccess else {
            throw BridgeError.configuration(
                "无法打开 HID 监听（IOReturn \(result)）。请在系统设置 → 隐私与安全性 → 输入监控中允许米遥。"
            )
        }

        print("米遥按键学习器")
        print(
            String(format: "只监听 Vendor 0x%04X / Product 0x%04X", configuration.hidVendorID, configuration.hidProductID))
        print("不会记录 MAC、蓝牙 UUID、序列号或 Mac 键盘输入。")
        print("正在等待遥控器 HID 设备…")

        deviceWaitTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: false) {
            [weak self] _ in
            guard let self, self.matchedDevice == nil else { return }
            self.fail(
                "15 秒内没有找到指定 HID 设备。请确认遥控器已连接，并检查输入监控权限。"
            )
        }
    }

    fileprivate func deviceMatched(_ device: IOHIDDevice, result: IOReturn) {
        guard result == kIOReturnSuccess, matchedDevice == nil else { return }
        let name = propertyString(device, key: kIOHIDProductKey) ?? "(unknown)"
        if let filter = configuration.nameFilter?.lowercased(),
            !name.lowercased().contains(filter)
        {
            return
        }

        matchedDevice = device
        productName = name
        deviceWaitTimer?.invalidate()
        print("已找到目标遥控器：\(name)")
        print("每一步请只按提示按钮一次；松手后自动进入下一项。")
        beginCurrentStep()
    }

    fileprivate func valueReceived(_ value: IOHIDValue, result: IOReturn) {
        guard result == kIOReturnSuccess, matchedDevice != nil, !isFinished else { return }
        let element = IOHIDValueGetElement(value)
        let device = IOHIDElementGetDevice(element)
        guard device == matchedDevice else { return }

        let usagePage = Int(IOHIDElementGetUsagePage(element))
        let usage = Int(IOHIDElementGetUsage(element))
        guard usagePage != 0 else { return }
        let rawValue = IOHIDValueGetIntegerValue(value)
        let signature = ActiveInput(usagePage: usagePage, usage: usage)

        if activeInput == nil {
            guard rawValue != 0 else { return }
            activeInput = signature
            rawValues.append(rawValue)
            return
        }
        guard activeInput == signature else { return }

        rawValues.append(rawValue)
        if rawValue == 0 {
            finishCurrentStep(releaseObserved: true)
        } else {
            repeatCount += 1
        }
    }

    private func beginCurrentStep() {
        guard stepIndex < Self.steps.count else {
            finishProfile()
            return
        }

        activeInput = nil
        rawValues = []
        repeatCount = 0
        let step = Self.steps[stepIndex]
        print("\n[\(stepIndex + 1)/\(Self.steps.count)] 请按一下「\(step.label)」并松手（\(Int(configuration.buttonSeconds)) 秒）")
        stepTimer?.invalidate()
        stepTimer = Timer.scheduledTimer(
            withTimeInterval: configuration.buttonSeconds,
            repeats: false
        ) { [weak self] _ in
            guard let self else { return }
            if self.activeInput == nil {
                self.finishCurrentStep(releaseObserved: false, timedOut: true)
            } else {
                self.finishCurrentStep(releaseObserved: false)
            }
        }
    }

    private func finishCurrentStep(releaseObserved: Bool, timedOut: Bool = false) {
        guard stepIndex < Self.steps.count else { return }
        stepTimer?.invalidate()
        let step = Self.steps[stepIndex]
        let observed = activeInput != nil
        observations.append(
            ButtonProfile.Observation(
                button: step.id,
                label: step.label,
                expectedTransport: step.expectedTransport,
                status: observed ? .observed : .notObserved,
                usagePage: activeInput?.usagePage,
                usage: activeInput?.usage,
                rawValues: rawValues,
                pressObserved: observed,
                releaseObserved: releaseObserved,
                repeatCount: repeatCount,
                note: observed
                    ? (releaseObserved ? nil : "观察到按下，但等待期内没有观察到松手")
                    : step.timeoutNote
            ))

        if let input = activeInput {
            let release = releaseObserved ? "含松手" : "未见松手"
            print(String(format: "✓ page 0x%02X usage 0x%02X（%@）", input.usagePage, input.usage, release))
        } else if timedOut {
            print("– 未观察到 HID 事件：\(step.timeoutNote)")
        }

        stepIndex += 1
        beginCurrentStep()
    }

    private func finishProfile() {
        let profile = ButtonProfile(
            schemaVersion: 1,
            generatedAt: Date(),
            device: .init(
                vendorID: configuration.hidVendorID,
                productID: configuration.hidProductID,
                productName: productName
            ),
            privacy: "No MAC address, Bluetooth UUID, serial number, or host keyboard events are stored.",
            observations: observations
        )

        do {
            let url = try ButtonProfileWriter.write(
                profile,
                to: configuration.buttonProfileDirectory
            )
            print("\n学习完成：\(url.path)")
            print("已观察 \(observations.filter { $0.status == .observed }.count)/\(observations.count) 个按钮的 HID 事件。")
            finish(status: 0)
        } catch {
            fail("按键报告写入失败：\(error.localizedDescription)")
        }
    }

    private func propertyString(_ device: IOHIDDevice, key: String) -> String? {
        IOHIDDeviceGetProperty(device, key as CFString) as? String
    }

    private func fail(_ message: String) {
        fputs("错误：\(message)\n", stderr)
        finish(status: 1)
    }

    private func finish(status: Int32) {
        exitStatus = status
        isFinished = true
        stepTimer?.invalidate()
        deviceWaitTimer?.invalidate()
        closeManager()
        CFRunLoopStop(CFRunLoopGetMain())
    }

    private func closeManager() {
        guard let manager else { return }
        IOHIDManagerUnscheduleFromRunLoop(
            manager,
            CFRunLoopGetMain(),
            CFRunLoopMode.defaultMode.rawValue
        )
        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        self.manager = nil
    }
}
