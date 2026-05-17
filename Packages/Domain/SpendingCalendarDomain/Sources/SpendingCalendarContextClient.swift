import Foundation

public struct SpendingCalendarContextClient: Sendable {
    public var fetchTransactions: @Sendable () async throws -> [SpendingCalendarTransaction]
    public var fetchRecurringEvents: @Sendable () async throws -> [SpendingCalendarRecurringEvent]

    public init(
        fetchTransactions: @escaping @Sendable () async throws -> [SpendingCalendarTransaction],
        fetchRecurringEvents: @escaping @Sendable () async throws -> [SpendingCalendarRecurringEvent]
    ) {
        self.fetchTransactions = fetchTransactions
        self.fetchRecurringEvents = fetchRecurringEvents
    }
}

public extension SpendingCalendarContextClient {
    static let empty = SpendingCalendarContextClient(
        fetchTransactions: { [] },
        fetchRecurringEvents: { [] }
    )
}
