import Foundation
import Testing
@testable import SeasonalPlannerDomain

@Test("empty client loads no transactions")
func emptyClientLoadsNothing() async throws {
    let client = SeasonalContextClient.empty
    let result = try await client.loadTransactions()
    #expect(result.isEmpty)
}

@Test("custom client returns the injected closure result")
func customClientReturnsInjected() async throws {
    let date = try #require(
        DateComponents(calendar: Calendar(identifier: .gregorian), year: 2025, month: 4, day: 1).date
    )
    let expected = [SeasonalTransactionInput(amount: 500_000, isExpense: true, occurredAt: date)]
    let client = SeasonalContextClient(loadTransactions: { expected })
    let result = try await client.loadTransactions()
    #expect(result == expected)
}

@Test("custom client can surface thrown errors")
func customClientThrows() async {
    struct SampleError: Error {}
    let client = SeasonalContextClient(loadTransactions: { throw SampleError() })
    await #expect(throws: SampleError.self) {
        _ = try await client.loadTransactions()
    }
}

@Test("preview client produces 24 expense rows across two years")
func previewClientShape() async throws {
    let client = SeasonalContextClient.preview
    let result = try await client.loadTransactions()
    // Two prior years x twelve months.
    #expect(result.count == 24)
    #expect(result.allSatisfy(\.isExpense))
}

@Test("preview client marks Tết months with the larger amount")
func previewClientTetAmounts() async throws {
    let calendar = Calendar.current
    let client = SeasonalContextClient.preview
    let result = try await client.loadTransactions()

    for input in result {
        let month = calendar.component(.month, from: input.occurredAt)
        if month == 1 || month == 2 {
            #expect(input.amount == Decimal(9_000_000))
        } else {
            #expect(input.amount == Decimal(3_000_000))
        }
    }
    // Four Tết rows total (Jan + Feb across two years).
    let tetCount = result.filter { input in
        let month = calendar.component(.month, from: input.occurredAt)
        return month == 1 || month == 2
    }.count
    #expect(tetCount == 4)
}
