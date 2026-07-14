import Foundation

enum ATVVVersion: Equatable, CustomStringConvertible {
    case v04
    case v10

    var description: String { self == .v04 ? "0.4" : "1.0" }
}

enum ATVVCodec: UInt8, Equatable, CustomStringConvertible {
    case adpcm8k = 0x01
    case adpcm16k = 0x02

    var sampleRate: Int { self == .adpcm8k ? 8_000 : 16_000 }
    var description: String { self == .adpcm8k ? "ADPCM 8 kHz" : "ADPCM 16 kHz" }
}

struct ATVVCapabilities: Equatable {
    let version: ATVVVersion
    let codecs: UInt8
    let interactionModel: UInt8
    let frameSize: Int

    var selectedCodec: ATVVCodec? {
        if codecs & ATVVCodec.adpcm16k.rawValue != 0 { return .adpcm16k }
        if codecs & ATVVCodec.adpcm8k.rawValue != 0 { return .adpcm8k }
        return nil
    }
}

enum ATVVControlEvent: Equatable {
    case audioStop(reason: UInt8)
    case audioStart(reason: UInt8, codec: ATVVCodec, streamID: UInt8)
    case startSearch
    case audioSync(codec: ATVVCodec, sequence: UInt16, predictor: Int16, stepIndex: UInt8)
    case capabilities(ATVVCapabilities)
    case micOpenError(UInt16)
    case unknown(Data)
}

final class ATVVProtocol {
    static let serviceUUID = "AB5E0001-5A21-4F05-BC7D-AF01F617B664"
    static let txUUID = "AB5E0002-5A21-4F05-BC7D-AF01F617B664"
    static let rxUUID = "AB5E0003-5A21-4F05-BC7D-AF01F617B664"
    static let controlUUID = "AB5E0004-5A21-4F05-BC7D-AF01F617B664"

    private(set) var capabilities: ATVVCapabilities?
    private(set) var codec: ATVVCodec?
    private var decoder = ADPCMDecoder()
    private var v10Sequence: UInt16 = 0

    let getCapabilitiesCommand = Data([0x0A, 0x01, 0x00, 0x00, 0x03, 0x03])

    func acceptCapabilities(_ capabilities: ATVVCapabilities) throws {
        guard let selected = capabilities.selectedCodec else {
            throw BridgeError.protocolFailure("遥控器不支持 ADPCM 8/16 kHz")
        }
        self.capabilities = capabilities
        self.codec = selected
        decoder.reset(predictor: 0, stepIndex: 0)
        v10Sequence = 0
    }

    func micOpenCommand() throws -> Data {
        guard let capabilities, let codec else {
            throw BridgeError.protocolFailure("尚未完成 ATVV capabilities 协商")
        }
        switch capabilities.version {
        case .v04:
            return Data([0x0C, 0x00, codec.rawValue])
        case .v10:
            return Data([0x0C, 0x00])  // playback/realtime mode
        }
    }

    func micCloseCommand(streamID: UInt8) throws -> Data {
        guard let capabilities else {
            throw BridgeError.protocolFailure("尚未完成 ATVV capabilities 协商")
        }
        return capabilities.version == .v04 ? Data([0x0D]) : Data([0x0D, streamID])
    }

    func keepAliveCommand(streamID: UInt8) throws -> Data {
        guard let capabilities else {
            throw BridgeError.protocolFailure("尚未完成 ATVV capabilities 协商")
        }
        return capabilities.version == .v04 ? try micOpenCommand() : Data([0x0E, streamID])
    }

    func parseControl(_ data: Data) -> ATVVControlEvent {
        let bytes = [UInt8](data)
        guard let opcode = bytes.first else { return .unknown(data) }
        switch opcode {
        case 0x00:
            return .audioStop(reason: bytes.count > 1 ? bytes[1] : 0)
        case 0x04:
            if capabilities?.version == .v10, bytes.count >= 4,
                let codec = ATVVCodec(rawValue: bytes[2])
            {
                return .audioStart(reason: bytes[1], codec: codec, streamID: bytes[3])
            }
            return .audioStart(reason: 0, codec: codec ?? .adpcm8k, streamID: 0)
        case 0x08:
            return .startSearch
        case 0x0A:
            if capabilities?.version == .v10, bytes.count >= 7,
                let codec = ATVVCodec(rawValue: bytes[1])
            {
                let sequence = UInt16(bytes[2]) << 8 | UInt16(bytes[3])
                let predictorBits = UInt16(bytes[4]) << 8 | UInt16(bytes[5])
                let predictor = Int16(bitPattern: predictorBits)
                return .audioSync(
                    codec: codec,
                    sequence: sequence,
                    predictor: predictor,
                    stepIndex: bytes[6]
                )
            }
            return .unknown(data)
        case 0x0B:
            guard let capabilities = Self.parseCapabilities(data) else { return .unknown(data) }
            return .capabilities(capabilities)
        case 0x0C:
            guard bytes.count >= 3 else { return .micOpenError(0xffff) }
            return .micOpenError(UInt16(bytes[1]) << 8 | UInt16(bytes[2]))
        default:
            return .unknown(data)
        }
    }

    static func parseCapabilities(_ data: Data) -> ATVVCapabilities? {
        let bytes = [UInt8](data)
        guard bytes.count >= 3, bytes[0] == 0x0B else { return nil }
        let version = UInt16(bytes[1]) << 8 | UInt16(bytes[2])
        switch version {
        case 0x0004:
            guard bytes.count >= 9 else { return nil }
            return ATVVCapabilities(
                version: .v04,
                codecs: bytes[4],
                interactionModel: 0,
                frameSize: Int(UInt16(bytes[5]) << 8 | UInt16(bytes[6]))
            )
        case 0x0100:
            guard bytes.count >= 7 else { return nil }
            let standardCodecs = bytes[3]
            let standardInteractionModel = bytes[4]
            // Xiaomi Remote firmware 2671 has occasionally been observed
            // returning these two fields in the opposite order. Only accept
            // that layout when the standard codec byte is unambiguously invalid.
            let hasKnownStandardCodec = standardCodecs & 0x03 != 0
            let hasKnownSwappedCodec = standardInteractionModel & 0x03 != 0
            let codecs = !hasKnownStandardCodec && hasKnownSwappedCodec ? standardInteractionModel : standardCodecs
            let interactionModel =
                !hasKnownStandardCodec && hasKnownSwappedCodec ? standardCodecs : standardInteractionModel
            return ATVVCapabilities(
                version: .v10,
                codecs: codecs,
                interactionModel: interactionModel,
                frameSize: Int(UInt16(bytes[5]) << 8 | UInt16(bytes[6]))
            )
        default:
            return nil
        }
    }

    func applyAudioSync(codec: ATVVCodec, sequence: UInt16, predictor: Int16, stepIndex: UInt8) {
        self.codec = codec
        v10Sequence = sequence
        decoder.reset(predictor: predictor, stepIndex: stepIndex)
    }

    func decodeAudio(_ data: Data) -> (sequence: UInt16, samples: [Int16])? {
        guard let capabilities, codec != nil else { return nil }
        let bytes = [UInt8](data)

        switch capabilities.version {
        case .v04:
            guard bytes.count == capabilities.frameSize, bytes.count >= 6 else { return nil }
            let sequence = UInt16(bytes[0]) << 8 | UInt16(bytes[1])
            let predictorBits = UInt16(bytes[3]) << 8 | UInt16(bytes[4])
            let predictor = Int16(bitPattern: predictorBits)
            decoder.reset(predictor: predictor, stepIndex: bytes[5])
            return (sequence, [predictor] + decoder.decode(bytes.dropFirst(6)))
        case .v10:
            guard !bytes.isEmpty else { return nil }
            let sequence = v10Sequence
            v10Sequence &+= 1
            return (sequence, decoder.decode(bytes[...]))
        }
    }
}
