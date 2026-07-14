// Copyright (c) 2026 FanXeon@Poemcoder with Codex
import Foundation
import Testing

@testable import MiAo

@Test func parsesV04Capabilities() {
    let data = Data([0x0B, 0x00, 0x04, 0x00, 0x01, 0x00, 0x86, 0x00, 0x14])
    let capabilities = ATVVProtocol.parseCapabilities(data)
    #expect(
        capabilities
            == ATVVCapabilities(
                version: .v04,
                codecs: 0x01,
                interactionModel: 0,
                frameSize: 134
            ))
}

@Test func parsesV10Capabilities() {
    let data = Data([0x0B, 0x01, 0x00, 0x03, 0x03, 0x00, 0x80])
    let capabilities = ATVVProtocol.parseCapabilities(data)
    #expect(
        capabilities
            == ATVVCapabilities(
                version: .v10,
                codecs: 0x03,
                interactionModel: 0x03,
                frameSize: 128
            ))
    #expect(capabilities?.selectedCodec == .adpcm16k)
}

@Test func parsesXiaomiFirmware2671SwappedV10Capabilities() {
    let data = Data([0x0B, 0x01, 0x00, 0x00, 0x03, 0x00, 0x78, 0x00, 0x00])
    let capabilities = ATVVProtocol.parseCapabilities(data)
    #expect(
        capabilities
            == ATVVCapabilities(
                version: .v10,
                codecs: 0x03,
                interactionModel: 0x00,
                frameSize: 120
            ))
    #expect(capabilities?.selectedCodec == .adpcm16k)
}

@Test func decodesSilentV04Frame() throws {
    let handler = ATVVProtocol()
    try handler.acceptCapabilities(
        ATVVCapabilities(
            version: .v04,
            codecs: 0x01,
            interactionModel: 0,
            frameSize: 134
        ))
    var frame = Data(repeating: 0, count: 134)
    frame[1] = 1
    let decoded = handler.decodeAudio(frame)
    #expect(decoded?.sequence == 1)
    #expect(decoded?.samples.count == 257)
    #expect(decoded?.samples.allSatisfy { abs(Int($0)) < 256 } == true)
}

@Test func resamplesEightToSixteenKilohertz() {
    let input: [Int16] = [0, 100, 200, 300]
    let output = AudioPipeline.linearResample(input, from: 8_000, to: 16_000)
    #expect(output.count == 8)
    #expect(output.first == 0)
}
