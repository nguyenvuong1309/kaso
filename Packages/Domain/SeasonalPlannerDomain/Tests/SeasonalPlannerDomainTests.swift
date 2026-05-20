import Foundation
import Testing
@testable import SeasonalPlannerDomain

struct SeasonalPlannerDomainTests {
    private let calendar = Calendar(identifier: .gregorian)

    private func txn(year: Int, month: Int, amount: Decimal) -> SeasonalTransactionInput {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 10
        return SeasonalTransactionInput(
            amount: amount,
            isExpense: true,
            occurredAt: calendar.date(from: comps) ?? Date()
        )
    }

    @Test("single year of history is insufficient")
    func insufficientHistory() {
        let ref = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1)) ?? Date()
        let plan = SeasonalPlanBuilder.build(
            transactions: [txn(year: 2025, month: 2, amount: 1_000_000)],
            referenceDate: ref,
            calendar: calendar
        )
        #expect(plan.isSufficient == false)
    }

    @Test("detects Tết spike and suggests weekly saving")
    func detectsTetSpike() {
        var txns: [SeasonalTransactionInput] = []
        for year in 2024 ... 2025 {
            for month in 1 ... 12 {
                let isTet = month == 2
                txns.append(txn(year: year, month: month, amount: isTet ? 9_000_000 : 2_000_000))
            }
        }
        let ref = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1)) ?? Date()
        let plan = SeasonalPlanBuilder.build(transactions: txns, referenceDate: ref, calendar: calendar)

        #expect(plan.isSufficient == true)
        let tet = plan.spikes.first { $0.monthIndex == 2 }
        #expect(tet != nil)
        #expect(tet?.nameKey == "seasonal.name.tet")
        #expect((tet?.suggestedWeeklySaving ?? 0) > 0)
    }

    @Test("flat spending produces no spikes")
    func flatSpendingNoSpikes() {
        var txns: [SeasonalTransactionInput] = []
        for year in 2024 ... 2025 {
            for month in 1 ... 12 {
                txns.append(txn(year: year, month: month, amount: 2_000_000))
            }
        }
        let ref = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1)) ?? Date()
        let plan = SeasonalPlanBuilder.build(transactions: txns, referenceDate: ref, calendar: calendar)

        #expect(plan.isSufficient == true)
        #expect(plan.spikes.isEmpty)
    }
}
