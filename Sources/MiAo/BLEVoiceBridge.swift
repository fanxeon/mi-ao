// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import AppKit
import ApplicationServices
@preconcurrency import CoreBluetooth
import Foundation

final class BLEVoiceBridge: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private enum SessionState: String {
        case disconnected, discovering, ready, opening, streaming, transcribing
    }

    private let configuration: Configuration
    private let protocolHandler = ATVVProtocol()
    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var txCharacteristic: CBCharacteristic?
    private var rxCharacteristic: CBCharacteristic?
    private var controlCharacteristic: CBCharacteristic?
    private var notificationReady = Set<String>()
    private var didSendCapabilitiesRequest = false
    private var state: SessionState = .disconnected
    private var streamID: UInt8 = 0
    private var samples: [Int16] = []
    private var lastSequence: UInt16?
    private var detectedSpeech = false
    private var lastSpeechAt = Date()
    private var silenceTimer: Timer?
    private var keepAliveTimer: Timer?
    private var scanStopTimer: Timer?
    private var captureStopTimer: Timer?
    private var discoveredIdentifiers = Set<UUID>()
    private var transcriber: WhisperTranscriber?
    private var captureRecorder: CaptureRecorder?
    private(set) var isFinished = false
    private(set) var exitStatus: Int32 = 0

    init(configuration: Configuration) {
        self.configuration = configuration
        super.init()
    }

    func start() throws {
        if configuration.mode == .doctor {
            try runDoctor()
            return
        }
        if configuration.mode == .authorize {
            requestAccessibilityAuthorization()
            return
        }

        if configuration.mode == .run {
            transcriber = try WhisperTranscriber(configuration: configuration)
            try FileManager.default.createDirectory(
                atPath: configuration.outputDirectory,
                withIntermediateDirectories: true
            )
        }
        if configuration.mode == .capture {
            captureRecorder = try CaptureRecorder(
                directory: configuration.captureDirectory,
                includeIdentifiers: configuration.includeIdentifiers,
                includeDeviceNames: configuration.includeDeviceNames
            )
            if let captureRecorder {
                log("采集目录：\(captureRecorder.sessionDirectory.path)")
                log("设备 UUID 与名称默认脱敏；原始 GATT payload 仅保存在本机，分享前必须复核")
            }
        }

        central = CBCentralManager(delegate: self, queue: .main)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            log("蓝牙已就绪")
            if (configuration.mode == .run || configuration.mode == .capture),
                let identifier = configuration.peripheralIdentifier,
                let known = central.retrievePeripherals(withIdentifiers: [identifier]).first
            {
                connect(known, reason: "指定 identifier")
                return
            }

            if configuration.mode == .capture, discoverConnectedPeripheralsForCapture() {
                return
            }

            if configuration.mode == .run {
                let connected = central.retrieveConnectedPeripherals(
                    withServices: [CBUUID(string: ATVVProtocol.serviceUUID)]
                )
                if let match = connected.first(where: { isCandidate($0) }) {
                    connect(match, reason: "已连接 ATVV 设备")
                    return
                }
            }
            startScan()
        case .unauthorized:
            fatal("没有蓝牙权限。请在 系统设置 → 隐私与安全性 → 蓝牙 中允许本程序。")
        case .unsupported:
            fatal("这台 Mac 不支持 CoreBluetooth")
        case .poweredOff:
            fatal("蓝牙已关闭")
        default:
            log("等待蓝牙状态：\(central.state.rawValue)")
        }
    }

    private func startScan() {
        state = .discovering
        central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        let scanMessage =
            configuration.mode == .run
            ? "正在寻找带 ATVV 服务的兼容遥控器…"
            : "正在扫描附近 BLE 设备…"
        log(scanMessage)
        captureRecorder?.recordEvent(type: "scan_started", detail: "seconds=\(configuration.scanSeconds)")
        scanStopTimer?.invalidate()
        scanStopTimer = Timer.scheduledTimer(withTimeInterval: configuration.scanSeconds, repeats: false) {
            [weak self] _ in
            guard let self else { return }
            switch self.configuration.mode {
            case .scan:
                self.log("扫描结束，共发现 \(self.discoveredIdentifiers.count) 个 BLE 设备")
                self.isFinished = true
                CFRunLoopStop(CFRunLoopGetMain())
            case .capture:
                let reason = self.peripheral == nil ? "scan-timeout" : "capture-timeout"
                self.finishCapture(reason: reason)
            case .run:
                if self.peripheral == nil {
                    self.fatal("没有发现匹配的遥控器。先运行 scan，或用 --name/--identifier 指定设备。")
                }
            case .doctor, .authorize, .learnButtons, .debugButtons:
                break
            }
        }
    }

    @discardableResult
    private func discoverConnectedPeripheralsForCapture() -> Bool {
        let queryServices = [
            "1800",  // Generic Access
            "1801",  // Generic Attribute
            "180A",  // Device Information
            "180F",  // Battery
            "1812",  // Human Interface Device
            ATVVProtocol.serviceUUID,
        ]
        var matches: [UUID: (peripheral: CBPeripheral, services: Set<String>)] = [:]

        for serviceUUID in queryServices {
            let service = CBUUID(string: serviceUUID)
            for peripheral in central.retrieveConnectedPeripherals(withServices: [service]) {
                var match = matches[peripheral.identifier] ?? (peripheral, [])
                match.services.insert(serviceUUID.uppercased())
                matches[peripheral.identifier] = match
            }
        }

        for match in matches.values.sorted(by: {
            ($0.peripheral.name ?? $0.peripheral.identifier.uuidString)
                < ($1.peripheral.name ?? $1.peripheral.identifier.uuidString)
        }) {
            let peripheral = match.peripheral
            let name = peripheral.name ?? "(unknown)"
            let services = match.services.sorted()
            discoveredIdentifiers.insert(peripheral.identifier)
            captureRecorder?.recordDiscovery(
                identifier: peripheral.identifier,
                name: name,
                rssi: 127,
                advertisedServices: []
            )
            captureRecorder?.recordEvent(
                type: "connected_peripheral_retrieved",
                detail: "services=\(services.joined(separator: ","))",
                deviceIdentifier: peripheral.identifier
            )
            print(
                "已连接 name=\(name) id=\(peripheral.identifier.uuidString) via_services=[\(services.joined(separator: ","))]"
            )

            if configuration.nameFilter != nil, isCandidate(peripheral, discoveredName: name) {
                connect(peripheral, reason: "已连接 BLE 设备名称匹配")
                return true
            }
        }
        return false
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let advertisedServices = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]) ?? []
        let name = peripheral.name ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? "(unknown)"
        let hasATVV = advertisedServices.contains(CBUUID(string: ATVVProtocol.serviceUUID))
        captureRecorder?.recordDiscovery(
            identifier: peripheral.identifier,
            name: name,
            rssi: RSSI.intValue,
            advertisedServices: advertisedServices.map(\.uuidString)
        )

        if discoveredIdentifiers.insert(peripheral.identifier).inserted || configuration.debug {
            let serviceList = advertisedServices.map(\.uuidString).joined(separator: ",")
            print(
                "发现 name=\(name) id=\(peripheral.identifier.uuidString) rssi=\(RSSI) atvv=\(hasATVV) services=[\(serviceList)]"
            )
        }

        guard self.peripheral == nil else { return }
        if configuration.mode == .run, isCandidate(peripheral, discoveredName: name) || hasATVV {
            connect(peripheral, reason: hasATVV ? "广播 ATVV 服务" : "名称匹配")
        } else if configuration.mode == .capture,
            (configuration.peripheralIdentifier != nil || configuration.nameFilter != nil),
            isCandidate(peripheral, discoveredName: name)
        {
            connect(peripheral, reason: "采集目标匹配")
        }
    }

    private func isCandidate(_ peripheral: CBPeripheral, discoveredName: String? = nil) -> Bool {
        if let identifier = configuration.peripheralIdentifier {
            return peripheral.identifier == identifier
        }
        guard let filter = configuration.nameFilter?.lowercased() else { return false }
        return (discoveredName ?? peripheral.name)?.lowercased().contains(filter) == true
    }

    private func connect(_ peripheral: CBPeripheral, reason: String) {
        central.stopScan()
        scanStopTimer?.invalidate()
        self.peripheral = peripheral
        peripheral.delegate = self
        captureRecorder?.setTarget(
            identifier: peripheral.identifier,
            name: peripheral.name ?? "(unknown)"
        )
        captureRecorder?.recordEvent(
            type: "connect_requested",
            detail: reason,
            deviceIdentifier: peripheral.identifier
        )
        log("连接 \(peripheral.name ?? peripheral.identifier.uuidString)（\(reason)）")
        central.connect(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log("已连接，枚举全部 GATT services")
        captureRecorder?.recordConnection(identifier: peripheral.identifier, connected: true)
        if configuration.mode == .capture {
            captureStopTimer?.invalidate()
            captureStopTimer = Timer.scheduledTimer(
                withTimeInterval: configuration.captureSeconds,
                repeats: false
            ) { [weak self] _ in
                self?.finishCapture(reason: "capture-timeout")
            }
        }
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        captureRecorder?.recordConnection(
            identifier: peripheral.identifier,
            connected: false,
            detail: error?.localizedDescription ?? "unknown"
        )
        fatal("连接失败：\(error?.localizedDescription ?? "unknown")")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        log("遥控器断开：\(error?.localizedDescription ?? "normal")")
        captureRecorder?.recordConnection(
            identifier: peripheral.identifier,
            connected: false,
            detail: error?.localizedDescription ?? "normal"
        )
        if configuration.mode == .capture, state == .streaming || state == .opening {
            finalizeRecording(reason: "device-disconnected")
        }
        state = .disconnected
        self.peripheral = nil
        txCharacteristic = nil
        rxCharacteristic = nil
        controlCharacteristic = nil
        notificationReady.removeAll()
        didSendCapabilitiesRequest = false
        stopTimers()
        if configuration.mode == .capture {
            finishCapture(reason: "device-disconnected")
            return
        }
        startScan()
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error { return fatal("枚举 service 失败：\(error.localizedDescription)") }
        guard let services = peripheral.services else { return fatal("设备没有暴露 GATT services") }
        for service in services {
            log("service \(service.uuid.uuidString)")
            captureRecorder?.recordService(service.uuid.uuidString, isPrimary: service.isPrimary)
            peripheral.discoverCharacteristics(nil, for: service)
        }
        guard services.contains(where: { $0.uuid == CBUUID(string: ATVVProtocol.serviceUUID) }) else {
            if configuration.mode == .capture {
                log("目标未暴露标准 ATVV 服务；继续采集全部 GATT，等待按键与通知事件")
                captureRecorder?.recordEvent(
                    type: "protocol_observation",
                    detail: "standard ATVV service not found"
                )
                return
            }
            fatal("该设备未暴露 Google ATVV 服务 \(ATVVProtocol.serviceUUID)。已输出所有 service 供继续逆向。")
            return
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error {
            if configuration.mode == .capture {
                log("枚举 characteristic 失败 \(service.uuid)：\(error.localizedDescription)")
                captureRecorder?.recordEvent(
                    type: "error",
                    detail: "characteristic discovery \(service.uuid): \(error.localizedDescription)"
                )
                return
            }
            return fatal("枚举 characteristic 失败：\(error.localizedDescription)")
        }
        for characteristic in service.characteristics ?? [] {
            let propertyNames = characteristicPropertyNames(characteristic.properties)
            log(
                "characteristic \(characteristic.uuid.uuidString) properties=\(propertyNames.joined(separator: ",")) raw=\(characteristic.properties.rawValue)"
            )
            captureRecorder?.recordCharacteristic(
                serviceUUID: service.uuid.uuidString,
                uuid: characteristic.uuid.uuidString,
                properties: propertyNames,
                rawProperties: characteristic.properties.rawValue
            )
            if configuration.mode == .capture {
                peripheral.discoverDescriptors(for: characteristic)
            }
            switch characteristic.uuid.uuidString.uppercased() {
            case ATVVProtocol.txUUID:
                txCharacteristic = characteristic
            case ATVVProtocol.rxUUID:
                rxCharacteristic = characteristic
            case ATVVProtocol.controlUUID:
                controlCharacteristic = characteristic
            default:
                break
            }

            if configuration.mode == .capture {
                if characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate) {
                    peripheral.setNotifyValue(true, for: characteristic)
                }
                if characteristic.properties.contains(.read) {
                    peripheral.readValue(for: characteristic)
                }
            } else if characteristic.uuid.uuidString.uppercased() == ATVVProtocol.rxUUID
                || characteristic.uuid.uuidString.uppercased() == ATVVProtocol.controlUUID
            {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
        negotiateIfReady()
    }

    func peripheral(
        _ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?
    ) {
        if let error {
            if configuration.mode == .capture {
                log("枚举 descriptor 失败 \(characteristic.uuid)：\(error.localizedDescription)")
                captureRecorder?.recordEvent(
                    type: "error",
                    detail: "descriptor discovery \(characteristic.uuid): \(error.localizedDescription)"
                )
                return
            }
            return
        }
        guard configuration.mode == .capture else { return }
        guard let service = characteristic.service else {
            captureRecorder?.recordEvent(
                type: "error",
                detail: "descriptor discovery missing parent service for \(characteristic.uuid)"
            )
            return
        }
        for descriptor in characteristic.descriptors ?? [] {
            log("descriptor \(descriptor.uuid.uuidString) for \(characteristic.uuid.uuidString)")
            captureRecorder?.recordDescriptor(
                serviceUUID: service.uuid.uuidString,
                characteristicUUID: characteristic.uuid.uuidString,
                uuid: descriptor.uuid.uuidString
            )
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?
    ) {
        if let error {
            if configuration.mode == .capture {
                log("订阅通知失败 \(characteristic.uuid)：\(error.localizedDescription)")
                captureRecorder?.recordEvent(
                    type: "notification_state",
                    detail: "error: \(error.localizedDescription)",
                    characteristicUUID: characteristic.uuid.uuidString
                )
                return
            }
            return fatal("订阅通知失败 \(characteristic.uuid)：\(error.localizedDescription)")
        }
        if characteristic.isNotifying {
            notificationReady.insert(characteristic.uuid.uuidString.uppercased())
            log("已订阅 \(characteristic.uuid.uuidString)")
        }
        captureRecorder?.recordEvent(
            type: "notification_state",
            detail: characteristic.isNotifying ? "subscribed" : "not-subscribed",
            characteristicUUID: characteristic.uuid.uuidString
        )
        negotiateIfReady()
    }

    private func negotiateIfReady() {
        guard !didSendCapabilitiesRequest,
            txCharacteristic != nil,
            notificationReady.contains(ATVVProtocol.rxUUID),
            notificationReady.contains(ATVVProtocol.controlUUID)
        else { return }
        didSendCapabilitiesRequest = true
        write(protocolHandler.getCapabilitiesCommand)
        log("TX GET_CAPS \(hex(protocolHandler.getCapabilitiesCommand))")
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            if configuration.mode == .capture {
                log("读取特征值失败 \(characteristic.uuid)：\(error.localizedDescription)")
                captureRecorder?.recordEvent(
                    type: "value_error",
                    detail: error.localizedDescription,
                    characteristicUUID: characteristic.uuid.uuidString
                )
                return
            }
            return fatal("读取通知失败 \(characteristic.uuid)：\(error.localizedDescription)")
        }
        guard let data = characteristic.value else { return }
        captureRecorder?.recordValue(
            characteristicUUID: characteristic.uuid.uuidString,
            data: data,
            detail: characteristic.isNotifying ? "notification" : "read"
        )
        if configuration.debug { log("RX \(characteristic.uuid.uuidString) \(hex(data))") }

        switch characteristic.uuid.uuidString.uppercased() {
        case ATVVProtocol.controlUUID:
            handleControl(protocolHandler.parseControl(data))
        case ATVVProtocol.rxUUID:
            handleAudio(data)
        default:
            break
        }
    }

    private func handleControl(_ event: ATVVControlEvent) {
        switch event {
        case .capabilities(let capabilities):
            do {
                try protocolHandler.acceptCapabilities(capabilities)
                state = .ready
                log(
                    "ATVV v\(capabilities.version)，codec=\(protocolHandler.codec!)，interaction=0x\(String(format: "%02x", capabilities.interactionModel))，frame=\(capabilities.frameSize)B"
                )
                log("桥接已就绪：按遥控器语音键开始说话")
            } catch { fatal(error.localizedDescription) }
        case .startSearch:
            if state == .streaming || state == .opening {
                log("第二次 START_SEARCH，结束本次语音")
                closeAndFinalize(reason: "second-press")
            } else {
                beginOpening()
            }
        case .audioStart(_, let codec, let newStreamID):
            streamID = newStreamID
            state = .streaming
            samples.removeAll(keepingCapacity: true)
            lastSequence = nil
            detectedSpeech = false
            lastSpeechAt = Date()
            log("AUDIO_START \(codec)，开始录音")
            startTimers()
        case .audioStop(let reason):
            log("AUDIO_STOP reason=0x\(String(format: "%02x", reason))")
            finalizeRecording(reason: "remote-release")
        case .audioSync(let codec, let sequence, let predictor, let stepIndex):
            protocolHandler.applyAudioSync(codec: codec, sequence: sequence, predictor: predictor, stepIndex: stepIndex)
        case .micOpenError(let code):
            state = .ready
            fatal("遥控器拒绝 MIC_OPEN，错误码 0x\(String(format: "%04x", code))")
        case .unknown(let data):
            if configuration.debug { log("未知 CTL \(hex(data))") }
        }
    }

    private func beginOpening() {
        do {
            let command = try protocolHandler.micOpenCommand()
            write(command)
            state = .opening
            samples.removeAll(keepingCapacity: true)
            lastSequence = nil
            detectedSpeech = false
            lastSpeechAt = Date()
            log("TX MIC_OPEN \(hex(command))")
        } catch { fatal(error.localizedDescription) }
    }

    private func handleAudio(_ data: Data) {
        let wasOpening = state == .opening
        guard state == .streaming || wasOpening,
            let frame = protocolHandler.decodeAudio(data)
        else { return }
        state = .streaming
        // ATVV v0.4 can start sending frames directly after MIC_OPEN without AUDIO_START.
        if wasOpening { startTimers() }
        if let lastSequence {
            let expected = lastSequence &+ 1
            if frame.sequence != expected {
                log("警告：音频丢帧 expected=\(expected) actual=\(frame.sequence)")
            }
        }
        lastSequence = frame.sequence
        samples.append(contentsOf: frame.samples)

        let rms = AudioPipeline.rootMeanSquare(frame.samples)
        if rms >= configuration.silenceThreshold {
            detectedSpeech = true
            lastSpeechAt = Date()
        }
    }

    private func startTimers() {
        stopTimers()
        if configuration.silenceTimeout > 0 {
            silenceTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self, self.state == .streaming, self.detectedSpeech else { return }
                if Date().timeIntervalSince(self.lastSpeechAt) >= self.configuration.silenceTimeout {
                    self.log("检测到持续静音，自动结束")
                    self.closeAndFinalize(reason: "silence")
                }
            }
        }
        keepAliveTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            guard let self, self.state == .streaming else { return }
            if let command = try? self.protocolHandler.keepAliveCommand(streamID: self.streamID) {
                self.write(command)
            }
        }
    }

    private func closeAndFinalize(reason: String) {
        if let command = try? protocolHandler.micCloseCommand(streamID: streamID) {
            write(command)
        }
        finalizeRecording(reason: reason)
    }

    private func finalizeRecording(reason: String) {
        guard state == .streaming || state == .opening else { return }
        stopTimers()
        state = .transcribing
        let captured = samples
        samples.removeAll(keepingCapacity: true)

        guard captured.count >= (protocolHandler.codec?.sampleRate ?? 8_000) / 4 else {
            log("录音过短，取消：\(captured.count) samples")
            captureRecorder?.recordEvent(
                type: "audio_discarded",
                detail: "reason=\(reason) samples=\(captured.count)"
            )
            state = .ready
            return
        }

        let rate = protocolHandler.codec?.sampleRate ?? 8_000
        if configuration.mode == .capture, let captureRecorder {
            let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
            let wavURL = captureRecorder.sessionDirectory.appendingPathComponent("audio-\(stamp).wav")
            do {
                try AudioPipeline.writeWAV(samples: captured, sampleRate: rate, to: wavURL)
                try FileManager.default.setAttributes(
                    [.posixPermissions: 0o600],
                    ofItemAtPath: wavURL.path
                )
                captureRecorder.recordEvent(
                    type: "audio_saved",
                    detail: "reason=\(reason) samples=\(captured.count) rate=\(rate) file=\(wavURL.lastPathComponent)"
                )
                log("采集音频已保存：\(wavURL.path)")
            } catch {
                captureRecorder.recordEvent(type: "error", detail: "audio save: \(error.localizedDescription)")
                log("采集音频保存失败：\(error.localizedDescription)")
            }
            state = .ready
            log("采集继续：再次按语音键可记录下一段")
            return
        }

        let prepared = AudioPipeline.prepareForWhisper(captured, sampleRate: rate, gainDB: configuration.gainDB)
        let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let wavURL = URL(fileURLWithPath: configuration.outputDirectory).appendingPathComponent("voice-\(stamp).wav")

        do {
            try AudioPipeline.writeWAV(samples: prepared, sampleRate: 16_000, to: wavURL)
            log("录音完成 reason=\(reason)，保存 \(wavURL.path)")
            guard let transcriber else { throw BridgeError.transcription("transcriber 未初始化") }
            let transcript = try transcriber.transcribe(wavURL: wavURL)
            let transcriptURL = wavURL.deletingPathExtension().appendingPathExtension("txt")
            try transcript.write(to: transcriptURL, atomically: true, encoding: .utf8)
            log("转写：\(transcript)")

            if configuration.submitToCodex {
                try CodexSubmitter().submit(transcript, force: configuration.forceSubmit)
                log("已发送到 Codex")
            }
        } catch {
            log("本次处理失败：\(error.localizedDescription)")
        }
        state = .ready
        log("桥接已就绪：按遥控器语音键继续")
    }

    private func write(_ data: Data) {
        guard let peripheral, let txCharacteristic else {
            return fatal("TX characteristic 尚未就绪")
        }
        let type: CBCharacteristicWriteType =
            txCharacteristic.properties.contains(.writeWithoutResponse)
            ? .withoutResponse
            : .withResponse
        captureRecorder?.recordEvent(
            type: "write",
            characteristicUUID: txCharacteristic.uuid.uuidString,
            data: data
        )
        peripheral.writeValue(data, for: txCharacteristic, type: type)
    }

    private func stopTimers() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        keepAliveTimer?.invalidate()
        keepAliveTimer = nil
    }

    private func finishCapture(reason: String, status: Int32 = 0) {
        guard configuration.mode == .capture, !isFinished else { return }
        if state == .streaming || state == .opening {
            closeAndFinalize(reason: reason)
        }
        central?.stopScan()
        scanStopTimer?.invalidate()
        scanStopTimer = nil
        captureStopTimer?.invalidate()
        captureStopTimer = nil
        stopTimers()

        do {
            guard let recorder = captureRecorder else {
                throw BridgeError.configuration("采集记录器未初始化")
            }
            let report = try recorder.finish(reason: reason)
            log(
                "采集完成：devices=\(report.summary.discoveredDevices) services=\(report.summary.services) characteristics=\(report.summary.characteristics) descriptors=\(report.summary.descriptors) values=\(report.summary.values) atvv=\(report.summary.atvvDetected)"
            )
            print("采集报告：\(recorder.reportURL.path)")
            print("原始事件：\(recorder.eventsURL.path)")
        } catch {
            fputs("错误：无法完成采集报告：\(error.localizedDescription)\n", stderr)
            exitStatus = 1
        }
        exitStatus = max(exitStatus, status)
        isFinished = true
        CFRunLoopStop(CFRunLoopGetMain())
    }

    private func characteristicPropertyNames(_ properties: CBCharacteristicProperties) -> [String] {
        let known: [(CBCharacteristicProperties, String)] = [
            (.broadcast, "broadcast"),
            (.read, "read"),
            (.writeWithoutResponse, "writeWithoutResponse"),
            (.write, "write"),
            (.notify, "notify"),
            (.indicate, "indicate"),
            (.authenticatedSignedWrites, "authenticatedSignedWrites"),
            (.extendedProperties, "extendedProperties"),
            (.notifyEncryptionRequired, "notifyEncryptionRequired"),
            (.indicateEncryptionRequired, "indicateEncryptionRequired"),
        ]
        return known.compactMap { properties.contains($0.0) ? $0.1 : nil }
    }

    private func runDoctor() throws {
        print("macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)")
        let codexRunning = !NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.openai.codex"
        ).isEmpty
        print("Codex: \(codexRunning ? "正在运行 (com.openai.codex)" : "未运行")")
        print("辅助功能: \(AXIsProcessTrusted() ? "已授权" : "未授权")")
        let bluetoothAuthorization: String
        switch CBManager.authorization {
        case .allowedAlways: bluetoothAuthorization = "已授权"
        case .denied: bluetoothAuthorization = "已拒绝"
        case .restricted: bluetoothAuthorization = "受限制"
        case .notDetermined: bluetoothAuthorization = "尚未请求"
        @unknown default: bluetoothAuthorization = "未知"
        }
        print("蓝牙权限: \(bluetoothAuthorization)")
        let whisper = configuration.whisperPath ?? "/opt/homebrew/bin/whisper-cli"
        print("whisper-cli: \(FileManager.default.isExecutableFile(atPath: whisper) ? whisper : "未安装")")
        if let attributes = try? FileManager.default.attributesOfItem(atPath: configuration.modelPath),
            let size = attributes[.size] as? NSNumber
        {
            print(
                "model: \(configuration.modelPath) (\(ByteCountFormatter.string(fromByteCount: size.int64Value, countStyle: .file)))"
            )
        } else {
            print("model: 未下载")
        }
        print("output: \(configuration.outputDirectory)")
    }

    private func requestAccessibilityAuthorization() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        if AXIsProcessTrustedWithOptions(options) {
            print("辅助功能权限已授权")
        } else {
            let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "语音桥接 App"
            print("已请求辅助功能权限。请在系统设置中启用 \(appName)，然后重新运行 doctor 检查。")
        }
    }

    private func hex(_ data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined(separator: " ")
    }

    private func log(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        print("[\(formatter.string(from: Date()))] \(message)")
        fflush(stdout)
    }

    private func fatal(_ message: String) {
        fputs("错误：\(message)\n", stderr)
        fflush(stderr)
        if configuration.mode == .capture {
            captureRecorder?.recordEvent(type: "fatal_error", detail: message)
            finishCapture(reason: "fatal-error", status: 1)
            return
        }
        central?.stopScan()
        stopTimers()
        exitStatus = 1
        isFinished = true
        CFRunLoopStop(CFRunLoopGetMain())
    }
}
