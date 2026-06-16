import Foundation
import Testing
@testable import FutureSelfDomain

struct FutureSelfLetterBuilderTests {
    private let calendar = Calendar(identifier: .gregorian)

    private func income(_ amount: Decimal, at date: Date) -> FutureSelfTransactionInput {
        FutureSelfTransactionInput(amount: amount, isExpense: false, occurredAt: date)
    }

    private func expense(_ amount: Decimal, at date: Date) -> FutureSelfTransactionInput {
        FutureSelfTransactionInput(amount: amount, isExpense: true, occurredAt: date)
    }

    // MARK: - Insufficiency

    @Test("fewer than minimum recent transactions yields insufficient letter")
    func belowMinimumIsInsufficient() throws {
        let ref = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
        let txns = (0 ..< 9).map { offset in
            expense(100_000, at: ref.addingTimeInterval(-Double(offset) * 86_400))
        }
        let letter = FutureSelfLetterBuilder.build(
            context: FutureSelfContext(transactions: txns, currentAge: 25),
            referenceDate: ref,
            calendar: calendar
        )
        #expect(letter.isSufficient == false)
        #expect(letter.tone == .steady)
        #expect(letter.projectedAge == 55)
        #expect(letter.projectedAnnualSavings == 0)
        #expect(letter.paragraphKeys.isEmpty)
        #expect(letter.savingsRate == 0)
        #expect(letter.generatedAt == ref)
        #expect(letter.quarterLabel == "Q2 2026")
    }

    @Test("exactly minimum recent transactions is sufficient")
    func exactlyMinimumIsSufficient() throws {
        let ref = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
        var txns = [FutureSelfTransactionInput]()
        txns += (0 ..< 5).map { income(1_000_000, at: ref.addingTimeInterval(-Double($0) * 86_400)) }
        txns += (0 ..< 5).map { expense(500_000, at: ref.addingTimeInterval(-Double($0) * 86_400)) }
        #expect(txns.count == FutureSelfLetterBuilder.minimumTransactionCount)
        let letter = FutureSelfLetterBuilder.build(
            context: FutureSelfContext(transactions: txns, currentAge: 40),
            referenceDate: ref,
            calendar: calendar
        )
        #expect(letter.isSufficient == true)
    }

    @Test("empty context yields insufficient letter")
    func emptyContext() throws {
        let ref = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
        let letter = FutureSelfLetterBuilder.build(
            context: FutureSelfContext(transactions: [], currentAge: 33),
            referenceDate: ref,
            calendar: calendar
        )
        #expect(letter.isSufficient == false)
        #expect(letter.projectedAge == 63)
    }

    @Test("transactions older than three months are excluded from the count")
    func oldTransactionsExcluded() throws {
        let ref = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
        // 20 old transactions (6 months ago) — should not count.
        let old = try makeDate(year: 2025, month: 12, day: 1, calendar: calendar)
        let txns = (0 ..< 20).map { _ in expense(100_000, at: old) }
        let letter = FutureSelfLetterBuilder.build(
            context: FutureSelfContext(transactions: txns, currentAge: 30),
            referenceDate: ref,
            calendar: calendar
        )
        #expect(letter.isSufficient == false)
    }

    @Test("transaction exactly at the three-month cutoff is included")
    func cutoffBoundaryIncluded() throws {
        let ref = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
        let cutoff = try #require(calendar.date(byAdding: .month, value: -3, to: ref))
        var txns = (0 ..< 5).map { _ in income(1_000_000, at: cutoff) }
        txns += (0 ..< 5).map { _ in expense(500_000, at: cutoff) }
        let letter = FutureSelfLetterBuilder.build(
            context: FutureSelfContext(transactions: txns, currentAge: 30),
            referenceDate: ref,
            calendar: calendar
        )
        #expect(letter.isSufficient == true)
    }

    @Test("transaction one second before the cutoff is excluded")
    func justBeforeCutoffExcluded() throws {
        let ref = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
        let cutoff = try #require(calendar.date(byAdding: .month, value: -3, to: ref))
        let justBefore = cutoff.addingTimeInterval(-1)
        var txns = (0 ..< 5).map { _ in income(1_000_000, at: justBefore) }
        txns += (0 ..< 5).map { _ in expense(500_000, at: justBefore) }
        let letter = FutureSelfLetterBuilder.build(
            context: FutureSelfContext(transactions: txns, currentAge: 30),
            referenceDate: ref,
            calendar: calendar
        )
        #expect(letter.isSufficient == false)
    }

    // MARK: - Tone boundaries

    @Test("savings rate at exactly 0.2 produces optimistic tone")
    func optimisticBoundary() throws {
        let ref = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
        // income 1_000_000, expense 800_000 => rate 0.2 exactly.
        var txns = (0 ..< 8).map { _ in income(1_000_000, at: ref) }
        txns += (0 ..< 8).map { _ in expense(800_000, at: ref) }
        let letter = FutureSelfLetterBuilder.build(
            context: FutureSelfContext(transactions: txns, currentAge: 30),
            referenceDate: ref,
            calendar: calendar
        )
        #expect(letter.tone == .optimistic)
        #expect(abs(letter.savingsRate - 0.2) < 0.0001)
        #expect(letter.paragraphKeys == [
            "futureSelf.body.optimistic.1",
            "futureSelf.body.optimistic.2",
            "futureSelf.body.optimistic.3",
        ])
    }

    @Test("savings rate just below 0.2 produces steady tone")
    func steadyJustBelowOptimistic() throws {
        let ref = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
        // income 1_000_000, expense 850_000 => rate 0.15.
        var txns = (0 ..< 8).map { _ in income(1_000_000, at: ref) }
        txns += (0 ..< 8).map { _ in expense(850_000, at: ref) }
        let letter = FutureSelfLetterBuilder.build(
            context: FutureSelfContext(transactions: txns, currentAge: 30),
            referenceDate: ref,
            calendar: calendar
        )
        #expect(letter.tone == .steady)
        #expect(letter.paragraphKeys.first == "futureSelf.body.steady.1")
    }

    @Test("savings rate at exactly 0 produces steady tone")
    func steadyAtZero() throws {
        let ref = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
        // income == expense => rate 0.
        var txns = (0 ..< 8).map { _ in income(1_000_000, at: ref) }
        txns += (0 ..< 8).map { _ in expense(1_000_000, at: ref) }
        let letter = FutureSelfLetterBuilder.build(
            context: FutureSelfContext(transactions: txns, currentAge: 30),
            referenceDate: ref,
            calendar: calendar
        )
        #expect(letter.tone == .steady)
        #expect(letter.savingsRate == 0)
        #expect(letter.projectedAnnualSavings == 0)
    }

    @Test("expense exceeding income produces cautionary tone")
    func cautionaryNegativeRate() throws {
        let ref = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
        var txns = (0 ..< 8).map { _ in income(1_000_000, at: ref) }
        txns += (0 ..< 8).map { _ in expense(1_500_000, at: ref) }
        let letter = FutureSelfLetterBuilder.build(
            context: FutureSelfContext(transactions: txns, currentAge: 30),
            referenceDate: ref,
            calendar: calendar
        )
        #expect(letter.tone == .cautionary)
        #expect(letter.savingsRate < 0)
        #expect(letter.projectedAnnualSavings == 0)
        #expect(letter.paragraphKeys == [
            "futureSelf.body.cautionary.1",
            "futureSelf.body.cautionary.2",
            "futureSelf.body.cautionary.3",
        ])
    }

    @Test("zero income with expenses yields cautionary tone and rate of -1")
    func zeroIncomeCautionary() throws {
        let ref = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
        let txns = (0 ..< 12).map { _ in expense(200_000, at: ref) }
        let letter = FutureSelfLetterBuilder.build(
            context: FutureSelfContext(transactions: txns, currentAge: 30),
            referenceDate: ref,
            calendar: calendar
        )
        #expect(letter.tone == .cautionary)
        #expect(letter.savingsRate == -1)
        #expect(letter.projectedAnnualSavings == 0)
    }

    // MARK: - Projection math

    @Test("projected annual savings equals monthly net times twelve")
    func projectedAnnualSavings() throws {
        let ref = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
        // income 10 x 900_000 = 9_000_000; expense 10 x 300_000 = 3_000_000.
        // net over 3 months = 6_000_000; monthly = 2_000_000; annual = 24_000_000.
        var txns = (0 ..< 10).map { _ in income(900_000, at: ref) }
        txns += (0 ..< 10).map { _ in expense(300_000, at: ref) }
        let letter = FutureSelfLetterBuilder.build(
            context: FutureSelfContext(transactions: txns, currentAge: 30),
            referenceDate: ref,
            calendar: calendar
        )
        #expect(letter.projectedAnnualSavings == 24_000_000)
        #expect(letter.tone == .optimistic)
    }

    @Test("nil current age uses default of 30 plus 30 projection years")
    func defaultAgeApplied() throws {
        let ref = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
        var txns = (0 ..< 8).map { _ in income(1_000_000, at: ref) }
        txns += (0 ..< 8).map { _ in expense(500_000, at: ref) }
        let letter = FutureSelfLetterBuilder.build(
            context: FutureSelfContext(transactions: txns, currentAge: nil),
            referenceDate: ref,
            calendar: calendar
        )
        #expect(letter.projectedAge == 60)
    }

    @Test("explicit current age adds 30 projection years")
    func explicitAgeApplied() throws {
        let ref = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
        var txns = (0 ..< 8).map { _ in income(1_000_000, at: ref) }
        txns += (0 ..< 8).map { _ in expense(500_000, at: ref) }
        let letter = FutureSelfLetterBuilder.build(
            context: FutureSelfContext(transactions: txns, currentAge: 45),
            referenceDate: ref,
            calendar: calendar
        )
        #expect(letter.projectedAge == 75)
    }

    // MARK: - Quarter labels

    @Test("quarter label reflects reference date quarter", arguments: [
        (1, "Q1"), (3, "Q1"), (4, "Q2"), (6, "Q2"),
        (7, "Q3"), (9, "Q3"), (10, "Q4"), (12, "Q4"),
    ])
    func quarterLabel(month: Int, expectedQuarter: String) throws {
        let ref = try makeDate(year: 2027, month: month, day: 15, calendar: calendar)
        let letter = FutureSelfLetterBuilder.build(
            context: FutureSelfContext(transactions: [], currentAge: 30),
            referenceDate: ref,
            calendar: calendar
        )
        #expect(letter.quarterLabel == "\(expectedQuarter) 2027")
    }

    @Test("generatedAt mirrors the reference date")
    func generatedAtMirrorsReference() throws {
        let ref = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
        let letter = FutureSelfLetterBuilder.build(
            context: FutureSelfContext(transactions: [], currentAge: 30),
            referenceDate: ref,
            calendar: calendar
        )
        #expect(letter.generatedAt == ref)
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
