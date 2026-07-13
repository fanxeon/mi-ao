import Foundation

struct ADPCMDecoder {
    private static let indexTable: [Int] = [
        -1, -1, -1, -1, 2, 4, 6, 8,
    ]

    private static let stepTable: [Int] = [
        7, 8, 9, 10, 11, 12, 13, 14, 16, 17,
        19, 21, 23, 25, 28, 31, 34, 37, 41, 45,
        50, 55, 60, 66, 73, 80, 88, 97, 107, 118,
        130, 143, 157, 173, 190, 209, 230, 253, 279, 307,
        337, 371, 408, 449, 494, 544, 598, 658, 724, 796,
        876, 963, 1_060, 1_166, 1_282, 1_411, 1_552, 1_707, 1_878, 2_066,
        2_272, 2_494, 2_740, 3_008, 3_307, 3_638, 4_002, 4_402, 4_842, 5_327,
        5_860, 6_446, 7_091, 7_800, 8_580, 9_438, 10_382, 11_420, 12_562, 13_818,
        15_200, 16_720, 18_392, 20_231, 22_254, 24_479, 26_927, 29_620, 32_767,
    ]

    private var predictor = 0
    private var stepIndex = 0

    mutating func reset(predictor: Int16, stepIndex: UInt8) {
        self.predictor = Int(predictor)
        self.stepIndex = min(88, Int(stepIndex))
    }

    mutating func decode<S: Sequence>(_ bytes: S) -> [Int16] where S.Element == UInt8 {
        var output: [Int16] = []
        for byte in bytes {
            output.append(decodeNibble(Int((byte >> 4) & 0x0f)))
            output.append(decodeNibble(Int(byte & 0x0f)))
        }
        return output
    }

    private mutating func decodeNibble(_ nibble: Int) -> Int16 {
        let step = Self.stepTable[stepIndex]
        var difference = step >> 3
        if nibble & 4 != 0 { difference += step }
        if nibble & 2 != 0 { difference += step >> 1 }
        if nibble & 1 != 0 { difference += step >> 2 }

        predictor += nibble & 8 != 0 ? -difference : difference
        predictor = max(Int(Int16.min), min(Int(Int16.max), predictor))

        stepIndex += Self.indexTable[nibble & 7]
        stepIndex = max(0, min(88, stepIndex))
        return Int16(predictor)
    }
}
