import Foundation
import Testing
@testable import RoundUpDomain

@Test("step raw values map to VND amounts")
func stepRawValuesMapToAmounts() {
    #expect(RoundUpStep.oneThousand.rawValue == 1_000)
    #expect(RoundUpStep.fiveThousand.rawValue == 5_000)
    #expect(RoundUpStep.tenThousand.rawValue == 10_000)
    #expect(RoundUpStep.fiftyThousand.rawValue == 50_000)
}

@Test("step amount returns Decimal of raw value")
func stepAmountReturnsDecimal() {
    #expect(RoundUpStep.oneThousand.amount == Decimal(1_000))
    #expect(RoundUpStep.fiveThousand.amount == Decimal(5_000))
    #expect(RoundUpStep.tenThousand.amount == Decimal(10_000))
    #expect(RoundUpStep.fiftyThousand.amount == Decimal(50_000))
}

@Test("step id equals raw value")
func stepIDEqualsRawValue() {
    for step in RoundUpStep.allCases {
        #expect(step.id == step.rawValue)
    }
}

@Test("step nameKey is localization key per raw value")
func stepNameKeyFormat() {
    #expect(RoundUpStep.oneThousand.nameKey == "roundUp.step.1000")
    #expect(RoundUpStep.fiveThousand.nameKey == "roundUp.step.5000")
    #expect(RoundUpStep.tenThousand.nameKey == "roundUp.step.10000")
    #expect(RoundUpStep.fiftyThousand.nameKey == "roundUp.step.50000")
}

@Test("step allCases contains exactly the four cases")
func stepAllCasesContent() {
    #expect(RoundUpStep.allCases.count == 4)
    #expect(RoundUpStep.allCases == [.oneThousand, .fiveThousand, .tenThousand, .fiftyThousand])
}

@Test("step is constructable from raw value")
func stepFromRawValue() {
    #expect(RoundUpStep(rawValue: 1_000) == .oneThousand)
    #expect(RoundUpStep(rawValue: 50_000) == .fiftyThousand)
    #expect(RoundUpStep(rawValue: 12_345) == nil)
}

@Test("step Codable round-trips through JSON as raw int")
func stepCodableRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    for step in RoundUpStep.allCases {
        let data = try encoder.encode(step)
        let decoded = try decoder.decode(RoundUpStep.self, from: data)
        #expect(decoded == step)
    }
}

@Test("step encodes as bare integer")
func stepEncodesAsInteger() throws {
    let data = try JSONEncoder().encode(RoundUpStep.tenThousand)
    let string = try #require(String(data: data, encoding: .utf8))
    #expect(string == "10000")
}
