import Foundation

enum AudioPipeline {
    static func rootMeanSquare(_ samples: [Int16]) -> Double {
        guard !samples.isEmpty else { return 0 }
        let power = samples.reduce(0.0) { partial, sample in
            let value = Double(sample)
            return partial + value * value
        }
        return sqrt(power / Double(samples.count))
    }

    static func prepareForWhisper(_ samples: [Int16], sampleRate: Int, gainDB: Double) -> [Int16] {
        let gain = pow(10.0, gainDB / 20.0)
        let amplified = samples.map { sample -> Int16 in
            let value = Int((Double(sample) * gain).rounded())
            return Int16(max(Int(Int16.min), min(Int(Int16.max), value)))
        }

        guard sampleRate != 16_000, !amplified.isEmpty else { return amplified }
        return linearResample(amplified, from: sampleRate, to: 16_000)
    }

    static func linearResample(_ input: [Int16], from sourceRate: Int, to destinationRate: Int) -> [Int16] {
        guard sourceRate > 0, destinationRate > 0, input.count > 1 else { return input }
        let outputCount = Int((Double(input.count) * Double(destinationRate) / Double(sourceRate)).rounded())
        var output = [Int16]()
        output.reserveCapacity(outputCount)
        let ratio = Double(sourceRate) / Double(destinationRate)

        for outputIndex in 0..<outputCount {
            let sourcePosition = Double(outputIndex) * ratio
            let lower = min(input.count - 1, Int(sourcePosition))
            let upper = min(input.count - 1, lower + 1)
            let fraction = sourcePosition - Double(lower)
            let value = Double(input[lower]) * (1 - fraction) + Double(input[upper]) * fraction
            output.append(Int16(max(Double(Int16.min), min(Double(Int16.max), value.rounded()))))
        }
        return output
    }

    static func writeWAV(samples: [Int16], sampleRate: Int, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let dataSize = UInt32(samples.count * MemoryLayout<Int16>.size)
        var data = Data()
        data.appendASCII("RIFF")
        data.appendLittleEndian(UInt32(36) + dataSize)
        data.appendASCII("WAVE")
        data.appendASCII("fmt ")
        data.appendLittleEndian(UInt32(16))
        data.appendLittleEndian(UInt16(1))
        data.appendLittleEndian(UInt16(1))
        data.appendLittleEndian(UInt32(sampleRate))
        data.appendLittleEndian(UInt32(sampleRate * 2))
        data.appendLittleEndian(UInt16(2))
        data.appendLittleEndian(UInt16(16))
        data.appendASCII("data")
        data.appendLittleEndian(dataSize)
        for sample in samples {
            data.appendLittleEndian(UInt16(bitPattern: sample))
        }
        try data.write(to: url, options: .atomic)
    }
}

private extension Data {
    mutating func appendASCII(_ string: String) {
        append(string.data(using: .ascii)!)
    }

    mutating func appendLittleEndian<T: FixedWidthInteger>(_ value: T) {
        var littleEndian = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndian) { append(contentsOf: $0) }
    }
}
