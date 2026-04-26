import Foundation
import Testing
@testable import TransactionDomain

@Test("parses signed Vietnamese bank statement lines")
func parsesSignedVietnameseBankStatementLines() throws {
    let calendar = Calendar(identifier: .gregorian)
    let result = BankStatementParser.parse(
        text: """
        Ngày GD Nội dung Số tiền Số dư
        26/04/2026 Highlands Coffee -120.000 VND 9.880.000
        27/04/2026 GRAB BIKE -75.000 VND 9.805.000
        """,
        calendar: calendar
    )

    #expect(result.totalLineCount == 3)
    #expect(result.skippedLineCount == 1)
    #expect(result.drafts.count == 2)
    #expect(result.drafts[0].amount == 120_000)
    #expect(result.drafts[0].kind == .expense)
    #expect(result.drafts[0].category == .food)
    #expect(result.drafts[0].note == "Highlands Coffee")
    #expect(result.drafts[1].amount == 75_000)
    #expect(result.drafts[1].category == .transport)
}

@Test("infers income and redacts account-like numbers")
func infersIncomeAndRedactsAccountLikeNumbers() throws {
    let calendar = Calendar(identifier: .gregorian)
    let expectedDate = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 28).date
    )
    let result = BankStatementParser.parse(
        text: "28/04/2026 NHAN LUONG THANG 04 TK 0123456789 +20.000.000 VND",
        calendar: calendar
    )

    let draft = try #require(result.drafts.first)
    #expect(draft.amount == 20_000_000)
    #expect(draft.kind == .income)
    #expect(draft.category == .salary)
    #expect(draft.occurredAt == expectedDate)
    #expect(draft.note == "NHAN LUONG THANG 04 TK ••••")
}
