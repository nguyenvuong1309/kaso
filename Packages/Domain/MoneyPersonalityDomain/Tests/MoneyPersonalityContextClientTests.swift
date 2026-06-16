import Foundation
import Testing
@testable import MoneyPersonalityDomain

struct MoneyPersonalityContextTests {
    @Test("init stores all properties verbatim")
    func initStoresProperties() throws {
        let calendar = Calendar(identifier: .gregorian)
        let occurredAt = try makeDate(year: 2026, month: 6, day: 10, calendar: calendar)
        let input = PersonalityTransactionInput(
            amount: 75_000,
            categoryID: "food",
            isExpense: true,
            occurredAt: occurredAt,
            calendar: calendar
        )
        let context = MoneyPersonalityContext(
            transactions: [input],
            budgetUtilizationRatio: 0.9,
            savingsRate: 0.12
        )
        #expect(context.transactions == [input])
        #expect(context.budgetUtilizationRatio == 0.9)
        #expect(context.savingsRate == 0.12)
    }

    @Test("contexts with identical fields are equatable")
    func equatable() throws {
        let calendar = Calendar(identifier: .gregorian)
        let occurredAt = try makeDate(year: 2026, month: 1, day: 1, calendar: calendar)
        let input = PersonalityTransactionInput(
            amount: 10_000,
            categoryID: "transport",
            isExpense: true,
            occurredAt: occurredAt,
            calendar: calendar
        )
        let a = MoneyPersonalityContext(transactions: [input], budgetUtilizationRatio: 0.5, savingsRate: 0.1)
        let b = MoneyPersonalityContext(transactions: [input], budgetUtilizationRatio: 0.5, savingsRate: 0.1)
        let c = MoneyPersonalityContext(transactions: [], budgetUtilizationRatio: 0.5, savingsRate: 0.1)
        #expect(a == b)
        #expect(a != c)
    }
}

struct MoneyPersonalityContextClientTests {
    @Test("empty client loads an empty context")
    func emptyClient() async throws {
        let context = try await MoneyPersonalityContextClient.empty.load()
        #expect(context.transactions.isEmpty)
        #expect(context.budgetUtilizationRatio == 0)
        #expect(context.savingsRate == 0)
    }

    @Test("preview client loads 60 expense transactions")
    func previewClientTransactions() async throws {
        let context = try await MoneyPersonalityContextClient.preview.load()
        #expect(context.transactions.count == 60)
        #expect(context.transactions.allSatisfy(\.isExpense))
    }

    @Test("preview client exposes the documented ratios")
    func previewClientRatios() async throws {
        let context = try await MoneyPersonalityContextClient.preview.load()
        #expect(context.budgetUtilizationRatio == 0.85)
        #expect(context.savingsRate == 0.15)
    }

    @Test("preview client cycles through the expected categories")
    func previewClientCategories() async throws {
        let context = try await MoneyPersonalityContextClient.preview.load()
        let categories = Set(context.transactions.map(\.categoryID))
        #expect(categories == ["food", "transport", "shopping", "entertainment"])
    }

    @Test("custom client returns the injected context")
    func customClientLoad() async throws {
        let calendar = Calendar(identifier: .gregorian)
        let occurredAt = try makeDate(year: 2026, month: 3, day: 3, calendar: calendar)
        let input = PersonalityTransactionInput(
            amount: 99_000,
            categoryID: "shopping",
            isExpense: false,
            occurredAt: occurredAt,
            calendar: calendar
        )
        let expected = MoneyPersonalityContext(
            transactions: [input],
            budgetUtilizationRatio: 1.2,
            savingsRate: -0.05
        )
        let client = MoneyPersonalityContextClient(load: { expected })
        let loaded = try await client.load()
        #expect(loaded == expected)
    }
}

private func makeDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 12,
    calendar: Calendar
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
