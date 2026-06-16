import Foundation
import Testing
@testable import SpendingDNADomain

struct SpendingDNABuilderTests {
    private let calendar = Calendar(identifier: .gregorian)

    private func makeDate(
        year: Int,
        month: Int = 1,
        day: Int = 1,
        hour: Int = 0,
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) throws -> Date {
        try #require(
            DateComponents(
                calendar: calendar,
                year: year,
                month: month,
                day: day,
                hour: hour
            ).date
        )
    }

    private func txn(
        amount: Decimal,
        category: String,
        isExpense: Bool,
        on date: Date
    ) -> SpendingDNATransactionInput {
        SpendingDNATransactionInput(
            amount: amount,
            categoryID: category,
            isExpense: isExpense,
            occurredAt: date
        )
    }

    // MARK: - classify boundaries

    @Test("savings rate exactly 0.3 classifies as saver")
    func saverBoundary() {
        let type = SpendingDNABuilder.classify(savingsRate: 0.3, dominantCategory: "food", dominantShare: 0.9)
        #expect(type == .saver)
    }

    @Test("savings rate of zero with no dominant share is balanced")
    func balancedAtZeroSavings() {
        let type = SpendingDNABuilder.classify(savingsRate: 0, dominantCategory: "shopping", dominantShare: 0.2)
        #expect(type == .balanced)
    }

    @Test("dominant explore share classifies as explorer")
    func explorerClassification() {
        let type = SpendingDNABuilder.classify(savingsRate: 0.1, dominantCategory: "travel", dominantShare: 0.5)
        #expect(type == .explorer)
    }

    @Test("dominant share at the 0.35 threshold triggers the category type")
    func dominantShareBoundary() {
        let foodie = SpendingDNABuilder.classify(savingsRate: 0.1, dominantCategory: "coffee", dominantShare: 0.35)
        #expect(foodie == .foodie)
    }

    @Test("dominant share just below threshold stays balanced")
    func dominantShareBelowThreshold() {
        let type = SpendingDNABuilder.classify(savingsRate: 0.1, dominantCategory: "food", dominantShare: 0.349)
        #expect(type == .balanced)
    }

    @Test("dominant category outside known sets stays balanced")
    func unknownDominantCategory() {
        let type = SpendingDNABuilder.classify(savingsRate: 0.1, dominantCategory: "shopping", dominantShare: 0.8)
        #expect(type == .balanced)
    }

    @Test("nil dominant category with positive savings stays balanced")
    func nilDominantCategory() {
        let type = SpendingDNABuilder.classify(savingsRate: 0.1, dominantCategory: nil, dominantShare: 0.9)
        #expect(type == .balanced)
    }

    @Test("vietnamese food category alias classifies as foodie")
    func vietnameseFoodAlias() {
        let type = SpendingDNABuilder.classify(savingsRate: 0.2, dominantCategory: "anuong", dominantShare: 0.5)
        #expect(type == .foodie)
    }

    @Test("vietnamese explore category alias classifies as explorer")
    func vietnameseExploreAlias() {
        let type = SpendingDNABuilder.classify(savingsRate: 0.2, dominantCategory: "dulich", dominantShare: 0.5)
        #expect(type == .explorer)
    }

    @Test("negative savings outranks a dominant food share")
    func negativeSavingsBeatsCategory() {
        let type = SpendingDNABuilder.classify(savingsRate: -0.01, dominantCategory: "food", dominantShare: 0.9)
        #expect(type == .spender)
    }

    // MARK: - minimum threshold

    @Test("exactly the minimum count is sufficient")
    func minimumCountIsSufficient() throws {
        let ref = try makeDate(year: 2026, month: 12, day: 31)
        let date = try makeDate(year: 2026, month: 6, day: 15)
        let txns = (0 ..< SpendingDNABuilder.minimumTransactionCount).map { _ in
            txn(amount: 100, category: "food", isExpense: true, on: date)
        }
        let report = SpendingDNABuilder.build(transactions: txns, referenceDate: ref, calendar: calendar)
        #expect(report.isSufficient == true)
        #expect(report.transactionCount == SpendingDNABuilder.minimumTransactionCount)
    }

    @Test("one below the minimum is insufficient with zeroed aggregates")
    func belowMinimumIsInsufficient() throws {
        let ref = try makeDate(year: 2026, month: 12, day: 31)
        let date = try makeDate(year: 2026, month: 6, day: 15)
        let txns = (0 ..< (SpendingDNABuilder.minimumTransactionCount - 1)).map { _ in
            txn(amount: 100, category: "food", isExpense: true, on: date)
        }
        let report = SpendingDNABuilder.build(transactions: txns, referenceDate: ref, calendar: calendar)
        #expect(report.isSufficient == false)
        #expect(report.transactionCount == SpendingDNABuilder.minimumTransactionCount - 1)
        #expect(report.totalExpense == 0)
        #expect(report.topCategories.isEmpty)
        #expect(report.mostActiveMonth == 0)
        #expect(report.bestSavingMonth == 0)
        #expect(report.year == 2026)
    }

    @Test("empty transactions yields an insufficient report")
    func emptyTransactions() throws {
        let ref = try makeDate(year: 2026, month: 5, day: 1)
        let report = SpendingDNABuilder.build(transactions: [], referenceDate: ref, calendar: calendar)
        #expect(report.isSufficient == false)
        #expect(report.transactionCount == 0)
        #expect(report.year == 2026)
    }

    // MARK: - year scoping

    @Test("transactions outside the reference year are excluded")
    func yearScoping() throws {
        let ref = try makeDate(year: 2026, month: 12, day: 31)
        let inYear = try makeDate(year: 2026, month: 6, day: 15)
        let priorYear = try makeDate(year: 2025, month: 6, day: 15)
        var txns = (0 ..< 12).map { _ in txn(amount: 100, category: "food", isExpense: true, on: inYear) }
        txns += (0 ..< 20).map { _ in txn(amount: 100, category: "food", isExpense: true, on: priorYear) }
        let report = SpendingDNABuilder.build(transactions: txns, referenceDate: ref, calendar: calendar)
        #expect(report.transactionCount == 12)
        #expect(report.totalExpense == 1_200)
    }

    @Test("falling below the minimum after year filtering is insufficient")
    func belowMinimumAfterFiltering() throws {
        let ref = try makeDate(year: 2026, month: 12, day: 31)
        let inYear = try makeDate(year: 2026, month: 6, day: 15)
        let priorYear = try makeDate(year: 2025, month: 6, day: 15)
        var txns = (0 ..< 5).map { _ in txn(amount: 100, category: "food", isExpense: true, on: inYear) }
        txns += (0 ..< 20).map { _ in txn(amount: 100, category: "food", isExpense: true, on: priorYear) }
        let report = SpendingDNABuilder.build(transactions: txns, referenceDate: ref, calendar: calendar)
        #expect(report.isSufficient == false)
        #expect(report.transactionCount == 5)
    }

    // MARK: - aggregation details

    @Test("category percentages are computed against total expense")
    func categoryPercentages() throws {
        let ref = try makeDate(year: 2026, month: 12, day: 31)
        let date = try makeDate(year: 2026, month: 6, day: 15)
        var txns = (0 ..< 6).map { _ in txn(amount: 100, category: "food", isExpense: true, on: date) }
        txns += (0 ..< 6).map { _ in txn(amount: 100, category: "transport", isExpense: true, on: date) }
        let report = SpendingDNABuilder.build(transactions: txns, referenceDate: ref, calendar: calendar)
        #expect(report.totalExpense == 1_200)
        let food = try #require(report.topCategories.first { $0.categoryID == "food" })
        #expect(abs(food.percentage - 0.5) < 0.0001)
        #expect(food.totalAmount == 600)
    }

    @Test("top categories are limited to three and sorted descending by amount")
    func topCategoriesLimitAndOrder() throws {
        let ref = try makeDate(year: 2026, month: 12, day: 31)
        let date = try makeDate(year: 2026, month: 6, day: 15)
        var txns: [SpendingDNATransactionInput] = []
        txns += (0 ..< 4).map { _ in txn(amount: 400, category: "a", isExpense: true, on: date) }
        txns += (0 ..< 4).map { _ in txn(amount: 300, category: "b", isExpense: true, on: date) }
        txns += (0 ..< 2).map { _ in txn(amount: 200, category: "c", isExpense: true, on: date) }
        txns += (0 ..< 2).map { _ in txn(amount: 100, category: "d", isExpense: true, on: date) }
        let report = SpendingDNABuilder.build(transactions: txns, referenceDate: ref, calendar: calendar)
        #expect(report.topCategories.count == 3)
        #expect(report.topCategories.map(\.categoryID) == ["a", "b", "c"])
        #expect(report.topCategories[0].totalAmount == 1_600)
    }

    @Test("largest transaction is the maximum expense amount")
    func largestTransaction() throws {
        let ref = try makeDate(year: 2026, month: 12, day: 31)
        let date = try makeDate(year: 2026, month: 6, day: 15)
        var txns = (0 ..< 11).map { _ in txn(amount: 100, category: "food", isExpense: true, on: date) }
        txns.append(txn(amount: 999_999, category: "food", isExpense: true, on: date))
        txns.append(txn(amount: 5_000_000, category: "salary", isExpense: false, on: date))
        let report = SpendingDNABuilder.build(transactions: txns, referenceDate: ref, calendar: calendar)
        #expect(report.largestTransaction == 999_999)
    }

    @Test("savings rate is zero when there is no income")
    func savingsRateNoIncome() throws {
        let ref = try makeDate(year: 2026, month: 12, day: 31)
        let date = try makeDate(year: 2026, month: 6, day: 15)
        let txns = (0 ..< 12).map { _ in txn(amount: 100, category: "food", isExpense: true, on: date) }
        let report = SpendingDNABuilder.build(transactions: txns, referenceDate: ref, calendar: calendar)
        #expect(report.savingsRate == 0)
        #expect(report.totalIncome == 0)
    }

    @Test("negative savings rate when expense exceeds income")
    func negativeSavingsRate() throws {
        let ref = try makeDate(year: 2026, month: 12, day: 31)
        let date = try makeDate(year: 2026, month: 6, day: 15)
        var txns = (0 ..< 11).map { _ in txn(amount: 1_000, category: "shopping", isExpense: true, on: date) }
        txns.append(txn(amount: 1_000, category: "salary", isExpense: false, on: date))
        let report = SpendingDNABuilder.build(transactions: txns, referenceDate: ref, calendar: calendar)
        #expect(report.savingsRate < 0)
        #expect(report.type == .spender)
    }

    // MARK: - month aggregation

    @Test("most active month is the month with the most transactions")
    func mostActiveMonth() throws {
        let ref = try makeDate(year: 2026, month: 12, day: 31)
        let march = try makeDate(year: 2026, month: 3, day: 10)
        let july = try makeDate(year: 2026, month: 7, day: 10)
        var txns = (0 ..< 9).map { _ in txn(amount: 100, category: "food", isExpense: true, on: july) }
        txns += (0 ..< 3).map { _ in txn(amount: 100, category: "food", isExpense: true, on: march) }
        let report = SpendingDNABuilder.build(transactions: txns, referenceDate: ref, calendar: calendar)
        #expect(report.mostActiveMonth == 7)
    }

    @Test("best saving month is the month with the highest net income")
    func bestSavingMonth() throws {
        let ref = try makeDate(year: 2026, month: 12, day: 31)
        let april = try makeDate(year: 2026, month: 4, day: 10)
        let september = try makeDate(year: 2026, month: 9, day: 10)
        var txns: [SpendingDNATransactionInput] = []
        // April: high income, low expense -> best net
        txns.append(txn(amount: 5_000_000, category: "salary", isExpense: false, on: april))
        txns += (0 ..< 5).map { _ in txn(amount: 100, category: "food", isExpense: true, on: april) }
        // September: only expenses -> negative net
        txns += (0 ..< 6).map { _ in txn(amount: 200_000, category: "shopping", isExpense: true, on: september) }
        let report = SpendingDNABuilder.build(transactions: txns, referenceDate: ref, calendar: calendar)
        #expect(report.bestSavingMonth == 4)
    }

    @Test("generatedAt and year mirror the reference date")
    func generatedAtMirrorsReference() throws {
        let ref = try makeDate(year: 2026, month: 8, day: 20, hour: 14)
        let date = try makeDate(year: 2026, month: 6, day: 15)
        let txns = (0 ..< 12).map { _ in txn(amount: 100, category: "food", isExpense: true, on: date) }
        let report = SpendingDNABuilder.build(transactions: txns, referenceDate: ref, calendar: calendar)
        #expect(report.generatedAt == ref)
        #expect(report.year == 2026)
    }

    // MARK: - input value type

    @Test("transaction input stores all fields and is equatable")
    func transactionInputEquatable() throws {
        let date = try makeDate(year: 2026, month: 6, day: 15)
        let lhs = txn(amount: 100, category: "food", isExpense: true, on: date)
        let same = txn(amount: 100, category: "food", isExpense: true, on: date)
        let different = txn(amount: 100, category: "food", isExpense: false, on: date)
        #expect(lhs.amount == 100)
        #expect(lhs.categoryID == "food")
        #expect(lhs.isExpense == true)
        #expect(lhs.occurredAt == date)
        #expect(lhs == same)
        #expect(lhs != different)
    }
}
