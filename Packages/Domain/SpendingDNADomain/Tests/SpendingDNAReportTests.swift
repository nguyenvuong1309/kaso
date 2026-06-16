import Foundation
import Testing
@testable import SpendingDNADomain

struct SpendingDNAReportTests {
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

    // MARK: - SpendingDNAType

    @Test("type emoji is stable for every case")
    func typeEmoji() {
        #expect(SpendingDNAType.saver.emoji == "🪙")
        #expect(SpendingDNAType.foodie.emoji == "🍜")
        #expect(SpendingDNAType.explorer.emoji == "🧭")
        #expect(SpendingDNAType.spender.emoji == "💸")
        #expect(SpendingDNAType.balanced.emoji == "⚖️")
    }

    @Test("type localization keys derive from raw value")
    func typeLocalizationKeys() {
        #expect(SpendingDNAType.saver.titleKey == "dna.type.saver.title")
        #expect(SpendingDNAType.saver.taglineKey == "dna.type.saver.tagline")
        #expect(SpendingDNAType.foodie.titleKey == "dna.type.foodie.title")
        #expect(SpendingDNAType.explorer.taglineKey == "dna.type.explorer.tagline")
        #expect(SpendingDNAType.spender.titleKey == "dna.type.spender.title")
        #expect(SpendingDNAType.balanced.taglineKey == "dna.type.balanced.tagline")
    }

    @Test("type exposes all five cases")
    func typeAllCases() {
        #expect(SpendingDNAType.allCases.count == 5)
        #expect(Set(SpendingDNAType.allCases) == [.saver, .foodie, .explorer, .spender, .balanced])
    }

    @Test("type encodes and decodes via raw value")
    func typeCodableRoundTrip() throws {
        for type in SpendingDNAType.allCases {
            let data = try JSONEncoder().encode(type)
            let decoded = try JSONDecoder().decode(SpendingDNAType.self, from: data)
            #expect(decoded == type)
        }
    }

    @Test("type decodes from its raw string")
    func typeDecodesRawString() throws {
        let data = Data("\"foodie\"".utf8)
        let decoded = try JSONDecoder().decode(SpendingDNAType.self, from: data)
        #expect(decoded == .foodie)
    }

    // MARK: - SpendingDNACategory

    @Test("category derives identity from categoryID")
    func categoryIdentity() {
        let category = SpendingDNACategory(categoryID: "food", totalAmount: 5_000, percentage: 0.5)
        #expect(category.id == "food")
        #expect(category.categoryID == "food")
        #expect(category.totalAmount == 5_000)
        #expect(category.percentage == 0.5)
    }

    @Test("category equality compares all stored fields")
    func categoryEquality() {
        let lhs = SpendingDNACategory(categoryID: "food", totalAmount: 5_000, percentage: 0.5)
        let same = SpendingDNACategory(categoryID: "food", totalAmount: 5_000, percentage: 0.5)
        let differentAmount = SpendingDNACategory(categoryID: "food", totalAmount: 1, percentage: 0.5)
        let differentID = SpendingDNACategory(categoryID: "travel", totalAmount: 5_000, percentage: 0.5)
        #expect(lhs == same)
        #expect(lhs != differentAmount)
        #expect(lhs != differentID)
    }

    // MARK: - SpendingDNAReport

    @Test("report stores every initializer argument")
    func reportInit() throws {
        let generatedAt = try makeDate(year: 2026, month: 6, day: 16)
        let categories = [
            SpendingDNACategory(categoryID: "food", totalAmount: 300, percentage: 0.6),
        ]
        let report = SpendingDNAReport(
            year: 2026,
            totalIncome: 1_000,
            totalExpense: 500,
            savingsRate: 0.5,
            transactionCount: 42,
            topCategories: categories,
            largestTransaction: 250,
            mostActiveMonth: 6,
            bestSavingMonth: 3,
            type: .saver,
            generatedAt: generatedAt,
            isSufficient: true
        )
        #expect(report.year == 2026)
        #expect(report.totalIncome == 1_000)
        #expect(report.totalExpense == 500)
        #expect(report.savingsRate == 0.5)
        #expect(report.transactionCount == 42)
        #expect(report.topCategories == categories)
        #expect(report.largestTransaction == 250)
        #expect(report.mostActiveMonth == 6)
        #expect(report.bestSavingMonth == 3)
        #expect(report.type == .saver)
        #expect(report.generatedAt == generatedAt)
        #expect(report.isSufficient == true)
    }

    @Test("report allows a negative savings rate")
    func reportNegativeSavingsRate() {
        let report = SpendingDNAReport(
            year: 2026,
            totalIncome: 100,
            totalExpense: 300,
            savingsRate: -2.0,
            transactionCount: 5,
            topCategories: [],
            largestTransaction: 200,
            mostActiveMonth: 0,
            bestSavingMonth: 0,
            type: .spender,
            generatedAt: Date(timeIntervalSinceReferenceDate: 0),
            isSufficient: true
        )
        #expect(report.savingsRate == -2.0)
        #expect(report.type == .spender)
    }

    @Test("empty report is a zeroed insufficient balanced report")
    func reportEmpty() {
        let empty = SpendingDNAReport.empty
        #expect(empty.year == 0)
        #expect(empty.totalIncome == 0)
        #expect(empty.totalExpense == 0)
        #expect(empty.savingsRate == 0)
        #expect(empty.transactionCount == 0)
        #expect(empty.topCategories.isEmpty)
        #expect(empty.largestTransaction == 0)
        #expect(empty.mostActiveMonth == 0)
        #expect(empty.bestSavingMonth == 0)
        #expect(empty.type == .balanced)
        #expect(empty.generatedAt == Date(timeIntervalSinceReferenceDate: 0))
        #expect(empty.isSufficient == false)
    }

    @Test("report equality compares all fields")
    func reportEquality() {
        let base = SpendingDNAReport.empty
        let same = SpendingDNAReport.empty
        let changed = SpendingDNAReport(
            year: 1,
            totalIncome: 0,
            totalExpense: 0,
            savingsRate: 0,
            transactionCount: 0,
            topCategories: [],
            largestTransaction: 0,
            mostActiveMonth: 0,
            bestSavingMonth: 0,
            type: .balanced,
            generatedAt: Date(timeIntervalSinceReferenceDate: 0),
            isSufficient: false
        )
        #expect(base == same)
        #expect(base != changed)
    }
}
