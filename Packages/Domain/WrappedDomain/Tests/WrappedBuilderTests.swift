import Foundation
import Testing
@testable import WrappedDomain

struct WrappedBuilderTests {
    @Test("returns insufficient when transaction count is below minimum")
    func insufficientData() {
        let transactions = [
            WrappedTransactionInput(amount: 50_000, categoryID: "food", isExpense: true, occurredAt: Date()),
        ]

        let report = WrappedBuilder.build(transactions: transactions, scope: .month)
        #expect(report.isSufficient == false)
    }

    @Test("computes income, expense and net balance correctly")
    func incomeExpenseBalance() {
        let calendar = Calendar.current
        let now = Date()
        let transactions = (0 ..< 10).map { i -> WrappedTransactionInput in
            let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            return WrappedTransactionInput(
                amount: i == 0 ? 5_000_000 : 100_000,
                categoryID: i == 0 ? "salary" : "food",
                isExpense: i != 0,
                occurredAt: date
            )
        }

        let report = WrappedBuilder.build(transactions: transactions, scope: .month, referenceDate: now)

        #expect(report.isSufficient)
        #expect(report.totalIncome == 5_000_000)
        #expect(report.totalExpense == 900_000)
        #expect(report.netBalance == 4_100_000)
    }

    @Test("returns top 3 categories sorted by amount")
    func topCategoriesAreSorted() {
        let now = Date()
        let transactions: [WrappedTransactionInput] = [
            WrappedTransactionInput(amount: 100_000, categoryID: "food", isExpense: true, occurredAt: now),
            WrappedTransactionInput(amount: 200_000, categoryID: "food", isExpense: true, occurredAt: now),
            WrappedTransactionInput(amount: 500_000, categoryID: "transport", isExpense: true, occurredAt: now),
            WrappedTransactionInput(amount: 50_000, categoryID: "shopping", isExpense: true, occurredAt: now),
            WrappedTransactionInput(amount: 80_000, categoryID: "entertainment", isExpense: true, occurredAt: now),
            WrappedTransactionInput(amount: 30_000, categoryID: "other", isExpense: true, occurredAt: now),
        ]

        let report = WrappedBuilder.build(transactions: transactions, scope: .month, referenceDate: now)

        #expect(report.topCategories.count <= 3)
        if let first = report.topCategories.first {
            #expect(first.categoryID == "transport")
        }
    }
}
