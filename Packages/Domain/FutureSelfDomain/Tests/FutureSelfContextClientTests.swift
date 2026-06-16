import Foundation
import Testing
@testable import FutureSelfDomain

struct FutureSelfContextClientTests {
    private let calendar = Calendar(identifier: .gregorian)

    // MARK: - Value types

    @Test("transaction input stores all fields")
    func transactionInputInit() throws {
        let date = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
        let input = FutureSelfTransactionInput(amount: 250_000, isExpense: true, occurredAt: date)
        #expect(input.amount == 250_000)
        #expect(input.isExpense == true)
        #expect(input.occurredAt == date)
    }

    @Test("identical transaction inputs are equal")
    func transactionInputEquatable() throws {
        let date = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
        let lhs = FutureSelfTransactionInput(amount: 100, isExpense: false, occurredAt: date)
        let rhs = FutureSelfTransactionInput(amount: 100, isExpense: false, occurredAt: date)
        #expect(lhs == rhs)
    }

    @Test("transaction inputs differing in amount are unequal")
    func transactionInputInequality() throws {
        let date = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
        let lhs = FutureSelfTransactionInput(amount: 100, isExpense: false, occurredAt: date)
        let rhs = FutureSelfTransactionInput(amount: 200, isExpense: false, occurredAt: date)
        #expect(lhs != rhs)
    }

    @Test("context stores transactions and age")
    func contextInit() throws {
        let date = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
        let txns = [FutureSelfTransactionInput(amount: 100, isExpense: true, occurredAt: date)]
        let context = FutureSelfContext(transactions: txns, currentAge: 42)
        #expect(context.transactions == txns)
        #expect(context.currentAge == 42)
    }

    @Test("context accepts nil age")
    func contextNilAge() {
        let context = FutureSelfContext(transactions: [], currentAge: nil)
        #expect(context.currentAge == nil)
        #expect(context.transactions.isEmpty)
    }

    @Test("identical contexts are equal")
    func contextEquatable() throws {
        let date = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
        let txns = [FutureSelfTransactionInput(amount: 100, isExpense: true, occurredAt: date)]
        #expect(
            FutureSelfContext(transactions: txns, currentAge: 30)
                == FutureSelfContext(transactions: txns, currentAge: 30)
        )
    }

    // MARK: - Clients

    @Test("empty client returns an empty context")
    func emptyClient() async throws {
        let context = try await FutureSelfContextClient.empty.loadContext()
        #expect(context.transactions.isEmpty)
        #expect(context.currentAge == nil)
    }

    @Test("preview client returns thirty transactions and a fixed age")
    func previewClientShape() async throws {
        let context = try await FutureSelfContextClient.preview.loadContext()
        #expect(context.transactions.count == 30)
        #expect(context.currentAge == 28)
    }

    @Test("preview client marks every fourth transaction as income")
    func previewClientIncomePattern() async throws {
        let context = try await FutureSelfContextClient.preview.loadContext()
        let incomeCount = context.transactions.filter { !$0.isExpense }.count
        let expenseCount = context.transactions.filter(\.isExpense).count
        // offsets 0,4,8,...28 are income => 8 income, 22 expense.
        #expect(incomeCount == 8)
        #expect(expenseCount == 22)
    }

    @Test("preview client produces a sufficient optimistic letter")
    func previewClientFeedsBuilder() async throws {
        let context = try await FutureSelfContextClient.preview.loadContext()
        let letter = FutureSelfLetterBuilder.build(context: context)
        #expect(letter.isSufficient == true)
        #expect(letter.tone == .optimistic)
        #expect(letter.projectedAge == 58)
    }

    @Test("custom client forwards an injected context")
    func customClientForwards() async throws {
        let date = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
        let txns = [FutureSelfTransactionInput(amount: 999, isExpense: true, occurredAt: date)]
        let client = FutureSelfContextClient(
            loadContext: { FutureSelfContext(transactions: txns, currentAge: 50) }
        )
        let context = try await client.loadContext()
        #expect(context.transactions == txns)
        #expect(context.currentAge == 50)
    }

    @Test("custom client can surface a thrown error")
    func customClientThrows() async {
        struct LoadError: Error {}
        let client = FutureSelfContextClient(loadContext: { throw LoadError() })
        await #expect(throws: LoadError.self) {
            _ = try await client.loadContext()
        }
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
