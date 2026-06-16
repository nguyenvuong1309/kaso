import Foundation
import Testing
@testable import SpendingCalendarDomain

private struct ContextClientTestError: Error, Equatable {}

@Test("empty context client returns empty transactions and recurring events")
func emptyContextClientReturnsEmpty() async throws {
    let client = SpendingCalendarContextClient.empty
    let transactions = try await client.fetchTransactions()
    let recurring = try await client.fetchRecurringEvents()
    #expect(transactions.isEmpty)
    #expect(recurring.isEmpty)
}

@Test("context client returns the values supplied by its closures")
func contextClientReturnsSuppliedValues() async throws {
    let tx = SpendingCalendarTransaction(
        amount: 42_000,
        occurredAt: try makeContextDate(2026, 3, 10),
        label: "Snack"
    )
    let event = SpendingCalendarRecurringEvent(
        label: "Gym",
        amount: 500_000,
        firstOccurrence: try makeContextDate(2026, 3, 1),
        intervalDays: 30
    )
    let client = SpendingCalendarContextClient(
        fetchTransactions: { [tx] },
        fetchRecurringEvents: { [event] }
    )
    let transactions = try await client.fetchTransactions()
    let recurring = try await client.fetchRecurringEvents()
    #expect(transactions == [tx])
    #expect(recurring == [event])
}

@Test("context client propagates errors thrown by fetchTransactions")
func contextClientPropagatesTransactionError() async {
    let client = SpendingCalendarContextClient(
        fetchTransactions: { throw ContextClientTestError() },
        fetchRecurringEvents: { [] }
    )
    await #expect(throws: ContextClientTestError.self) {
        _ = try await client.fetchTransactions()
    }
}

@Test("context client propagates errors thrown by fetchRecurringEvents")
func contextClientPropagatesRecurringError() async {
    let client = SpendingCalendarContextClient(
        fetchTransactions: { [] },
        fetchRecurringEvents: { throw ContextClientTestError() }
    )
    await #expect(throws: ContextClientTestError.self) {
        _ = try await client.fetchRecurringEvents()
    }
}

// MARK: - Helpers

private func makeContextCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
}

private func makeContextDate(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
    try #require(
        DateComponents(
            calendar: makeContextCalendar(),
            timeZone: TimeZone(secondsFromGMT: 0),
            year: year,
            month: month,
            day: day
        ).date
    )
}
