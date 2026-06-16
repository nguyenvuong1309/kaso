import Foundation
import Testing
import TransactionDomain
@testable import InsightDomain

@Test("ratio divides amount by baseline when baseline is positive")
func ratioWithPositiveBaseline() throws {
    let anomaly = makeAnomaly(amount: 300_000, baseline: 100_000)
    #expect(anomaly.ratio == 3)
}

@Test("ratio is zero when baseline is zero")
func ratioWithZeroBaseline() throws {
    let anomaly = makeAnomaly(amount: 300_000, baseline: 0)
    #expect(anomaly.ratio == 0)
}

@Test("ratio is zero when baseline is negative")
func ratioWithNegativeBaseline() throws {
    let anomaly = makeAnomaly(amount: 300_000, baseline: -50_000)
    #expect(anomaly.ratio == 0)
}

@Test("anomaly preserves identity and optional transaction id")
func anomalyPreservesFields() throws {
    let occurredAt = try makeDate(2026, 4, 20)
    let txID = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000AB"))
    let anomaly = SpendingAnomaly(
        id: "large-x",
        kind: .largeTransaction,
        category: .shopping,
        amount: 1_000_000,
        baselineAmount: 250_000,
        occurredAt: occurredAt,
        transactionID: txID
    )
    #expect(anomaly.id == "large-x")
    #expect(anomaly.kind == .largeTransaction)
    #expect(anomaly.category == .shopping)
    #expect(anomaly.occurredAt == occurredAt)
    #expect(anomaly.transactionID == txID)
}

@Test("anomaly transaction id defaults to nil")
func anomalyTransactionIdDefaultsNil() throws {
    let anomaly = makeAnomaly(amount: 1, baseline: 1)
    #expect(anomaly.transactionID == nil)
}

private func makeAnomaly(amount: Decimal, baseline: Decimal) -> SpendingAnomaly {
    SpendingAnomaly(
        id: "test",
        kind: .categorySpike,
        category: .food,
        amount: amount,
        baselineAmount: baseline,
        occurredAt: Date(timeIntervalSinceReferenceDate: 0)
    )
}

private func makeDate(
    _ year: Int,
    _ month: Int,
    _ day: Int
) throws -> Date {
    let calendar = Calendar(identifier: .gregorian)
    return try #require(
        DateComponents(calendar: calendar, year: year, month: month, day: day, hour: 12).date
    )
}
