import Foundation
import Testing
@testable import SpendingDNADomain

struct SpendingDNADomainTests {
    private func make(year: Int, count: Int, categoryID: String, isExpense: Bool, amount: Decimal)
        -> [SpendingDNATransactionInput] {
        var comps = DateComponents()
        comps.year = year
        comps.month = 6
        comps.day = 15
        let date = Calendar(identifier: .gregorian).date(from: comps) ?? Date()
        return (0 ..< count).map { _ in
            SpendingDNATransactionInput(
                amount: amount,
                categoryID: categoryID,
                isExpense: isExpense,
                occurredAt: date
            )
        }
    }

    @Test("insufficient transactions yields non-sufficient report")
    func insufficient() {
        let calendar = Calendar(identifier: .gregorian)
        let ref = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1)) ?? Date()
        let report = SpendingDNABuilder.build(
            transactions: make(year: 2026, count: 3, categoryID: "food", isExpense: true, amount: 100),
            referenceDate: ref,
            calendar: calendar
        )
        #expect(report.isSufficient == false)
        #expect(report.year == 2026)
    }

    @Test("high savings rate classifies as saver")
    func saverClassification() {
        let type = SpendingDNABuilder.classify(
            savingsRate: 0.5,
            dominantCategory: "food",
            dominantShare: 0.9
        )
        #expect(type == .saver)
    }

    @Test("negative savings rate classifies as spender")
    func spenderClassification() {
        let type = SpendingDNABuilder.classify(
            savingsRate: -0.2,
            dominantCategory: "shopping",
            dominantShare: 0.5
        )
        #expect(type == .spender)
    }

    @Test("dominant food share classifies as foodie")
    func foodieClassification() {
        let type = SpendingDNABuilder.classify(
            savingsRate: 0.1,
            dominantCategory: "food",
            dominantShare: 0.4
        )
        #expect(type == .foodie)
    }

    @Test("build aggregates income, expense and savings rate")
    func buildAggregates() {
        let calendar = Calendar(identifier: .gregorian)
        let ref = calendar.date(from: DateComponents(year: 2026, month: 12, day: 31)) ?? Date()
        var txns = make(year: 2026, count: 10, categoryID: "food", isExpense: true, amount: 100_000)
        txns += make(year: 2026, count: 5, categoryID: "salary", isExpense: false, amount: 1_000_000)
        let report = SpendingDNABuilder.build(transactions: txns, referenceDate: ref, calendar: calendar)

        #expect(report.isSufficient == true)
        #expect(report.totalExpense == 1_000_000)
        #expect(report.totalIncome == 5_000_000)
        #expect(report.topCategories.first?.categoryID == "food")
    }
}
