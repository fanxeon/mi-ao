// Copyright (c) 2026 FanXeon@Poemcoder with Codex
@preconcurrency import CoreBluetooth
import Foundation

struct RemoteDeviceRecord: Equatable {
    let identifier: UUID
    let name: String
    let rssi: Int
    let advertisesATVV: Bool
    let isConnected: Bool
}

struct RemoteDeviceCatalog {
    private(set) var records: [UUID: RemoteDeviceRecord] = [:]

    mutating func upsert(_ record: RemoteDeviceRecord) {
        guard let existing = records[record.identifier] else {
            records[record.identifier] = record
            return
        }
        records[record.identifier] = RemoteDeviceRecord(
            identifier: record.identifier,
            name: record.name == "未知遥控器" ? existing.name : record.name,
            rssi: record.rssi == -127 ? existing.rssi : record.rssi,
            advertisesATVV: existing.advertisesATVV || record.advertisesATVV,
            isConnected: existing.isConnected || record.isConnected
        )
    }

    var sortedRecords: [RemoteDeviceRecord] {
        records.values.sorted {
            if $0.isConnected != $1.isConnected { return $0.isConnected }
            if $0.rssi != $1.rssi { return $0.rssi > $1.rssi }
            return $0.identifier.uuidString < $1.identifier.uuidString
        }
    }
}

enum RemoteDeviceDiscoveryState: Equatable {
    case idle
    case waitingForBluetooth
    case scanning
    case finished
    case unavailable(String)
}

final class RemoteDeviceDiscoveryController: NSObject, CBCentralManagerDelegate, @unchecked Sendable {
    var onUpdate: ((RemoteDeviceDiscoveryState, [RemoteDeviceRecord]) -> Void)?

    private var central: CBCentralManager?
    private var stopTimer: Timer?
    private var catalog = RemoteDeviceCatalog()
    private var preferredIdentifier: UUID?
    private var isScanning = false
    private var scanDuration: TimeInterval = 8

    func start(preferredIdentifier: UUID?, duration: TimeInterval = 8) {
        stop()
        catalog = RemoteDeviceCatalog()
        self.preferredIdentifier = preferredIdentifier
        scanDuration = duration
        publish(.waitingForBluetooth)
        let central = CBCentralManager(
            delegate: self,
            queue: .main,
            options: [CBCentralManagerOptionShowPowerAlertKey: false]
        )
        self.central = central
        if central.state == .poweredOn { beginScan(duration: duration) }
    }

    func stop() {
        stopTimer?.invalidate()
        stopTimer = nil
        central?.stopScan()
        central = nil
        isScanning = false
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            beginScan(duration: scanDuration)
        case .poweredOff:
            publish(.unavailable("蓝牙已关闭；开启后再扫描"))
        case .unauthorized:
            publish(.unavailable("米遥没有蓝牙权限"))
        case .unsupported:
            publish(.unavailable("这台 Mac 不支持蓝牙扫描"))
        default:
            publish(.waitingForBluetooth)
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let services =
            advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []
        let hasATVV = services.contains(CBUUID(string: ATVVProtocol.serviceUUID))
        let advertisedName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let name = peripheral.name ?? advertisedName ?? "未知遥控器"
        let candidate = BLEDeviceCandidate(
            identifier: peripheral.identifier,
            name: name,
            rssi: RSSI.intValue,
            advertisesATVV: hasATVV
        )
        let policy = BLEDeviceSelectionPolicy(
            preferredIdentifier: preferredIdentifier,
            nameFilter: "小米蓝牙语音遥控器"
        )
        guard policy.accepts(candidate) else { return }
        catalog.upsert(
            RemoteDeviceRecord(
                identifier: peripheral.identifier,
                name: name,
                rssi: RSSI.intValue,
                advertisesATVV: hasATVV,
                isConnected: peripheral.state == .connected
            )
        )
        publish(.scanning)
    }

    private func beginScan(duration: TimeInterval) {
        guard let central, !isScanning else { return }
        isScanning = true
        addConnectedDevices(from: central)
        central.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
        publish(.scanning)
        stopTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) {
            [weak self] _ in
            guard let self else { return }
            self.central?.stopScan()
            self.isScanning = false
            self.stopTimer = nil
            self.publish(.finished)
        }
    }

    private func addConnectedDevices(from central: CBCentralManager) {
        let connected = central.retrieveConnectedPeripherals(
            withServices: [CBUUID(string: ATVVProtocol.serviceUUID)]
        )
        for peripheral in connected {
            catalog.upsert(
                RemoteDeviceRecord(
                    identifier: peripheral.identifier,
                    name: peripheral.name ?? "未知遥控器",
                    rssi: -127,
                    advertisesATVV: true,
                    isConnected: true
                )
            )
        }
        if let preferredIdentifier,
            let preferred = central.retrievePeripherals(withIdentifiers: [preferredIdentifier]).first
        {
            catalog.upsert(
                RemoteDeviceRecord(
                    identifier: preferred.identifier,
                    name: preferred.name ?? "已保存遥控器",
                    rssi: -127,
                    advertisesATVV: false,
                    isConnected: preferred.state == .connected
                )
            )
        }
    }

    private func publish(_ state: RemoteDeviceDiscoveryState) {
        onUpdate?(state, catalog.sortedRecords)
    }
}
