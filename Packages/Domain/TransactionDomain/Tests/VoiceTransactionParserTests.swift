import Foundation
import Testing
@testable import TransactionDomain

@Test("parses Vietnamese expense voice command")
func parsesVietnameseExpenseVoiceCommand() throws {
    let result = try #require(
        VoiceTransactionParser.parse("Ăn sáng 40 nghìn")
    )

    #expect(result.amount == 40_000)
    #expect(result.kind == .expense)
    #expect(result.category == .food)
    #expect(result.note == "Ăn sáng")
}

@Test("parses transport voice command with k suffix")
func parsesTransportVoiceCommandWithKSuffix() throws {
    let result = try #require(
        VoiceTransactionParser.parse("Grab đi làm 65k")
    )

    #expect(result.amount == 65_000)
    #expect(result.kind == .expense)
    #expect(result.category == .transport)
    #expect(result.note == "Grab đi làm")
}

@Test("parses income voice command with million unit")
func parsesIncomeVoiceCommandWithMillionUnit() throws {
    let result = try #require(
        VoiceTransactionParser.parse("Lương tháng này 20 triệu")
    )

    #expect(result.amount == 20_000_000)
    #expect(result.kind == .income)
    #expect(result.category == .salary)
    #expect(result.note == "Lương tháng này")
}

@Test("returns nil when voice command has no amount")
func returnsNilWhenVoiceCommandHasNoAmount() {
    #expect(VoiceTransactionParser.parse("Ăn sáng ở quán quen") == nil)
}
