import Foundation
import Testing
@testable import FutureSelfDomain

struct FutureSelfDomainTests {
    private func inputs(count: Int, income: Bool, amount: Decimal, now: Date)
        -> [FutureSelfTransactionInput] {
        (0 ..< count).map { offset in
            FutureSelfTransactionInput(
                amount: amount,
                isExpense: !income,
                occurredAt: now.addingTimeInterval(-Double(offset) * 86_400)
            )
        }
    }

    @Test("insufficient data yields non-sufficient letter")
    func insufficient() {
        let now = Date()
        let letter = FutureSelfLetterBuilder.build(
            context: FutureSelfContext(
                transactions: inputs(count: 3, income: false, amount: 100, now: now),
                currentAge: 25
            ),
            referenceDate: now
        )
        #expect(letter.isSufficient == false)
        #expect(letter.projectedAge == 55)
    }

    @Test("high savings rate produces optimistic tone")
    func optimisticTone() {
        let now = Date()
        var txns = inputs(count: 6, income: true, amount: 5_000_000, now: now)
        txns += inputs(count: 10, income: false, amount: 200_000, now: now)
        let letter = FutureSelfLetterBuilder.build(
            context: FutureSelfContext(transactions: txns, currentAge: 30),
            referenceDate: now
        )
        #expect(letter.isSufficient == true)
        #expect(letter.tone == .optimistic)
        #expect(letter.paragraphKeys.count == 3)
    }

    @Test("spending more than income produces cautionary tone")
    func cautionaryTone() {
        let now = Date()
        var txns = inputs(count: 4, income: true, amount: 1_000_000, now: now)
        txns += inputs(count: 12, income: false, amount: 1_000_000, now: now)
        let letter = FutureSelfLetterBuilder.build(
            context: FutureSelfContext(transactions: txns, currentAge: nil),
            referenceDate: now
        )
        #expect(letter.tone == .cautionary)
        #expect(letter.projectedAge == 60)
    }
}
