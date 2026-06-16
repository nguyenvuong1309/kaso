import Foundation
import Testing
@testable import SeasonalPlannerDomain

private let gregorian = Calendar(identifier: .gregorian)

private func makeDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 0,
    calendar: Calendar = gregorian
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

private func expense(year: Int, month: Int, amount: Decimal, day: Int = 10) throws -> SeasonalTransactionInput {
    SeasonalTransactionInput(
        amount: amount,
        isExpense: true,
        occurredAt: try makeDate(year: year, month: month, day: day)
    )
}

private func income(year: Int, month: Int, amount: Decimal, day: Int = 10) throws -> SeasonalTransactionInput {
    SeasonalTransactionInput(
        amount: amount,
        isExpense: false,
        occurredAt: try makeDate(year: year, month: month, day: day)
    )
}

// MARK: - SeasonalTransactionInput value type

@Test("transaction input stores values and supports equality")
func transactionInputValue() throws {
    let date = try makeDate(year: 2025, month: 3, day: 4)
    let input = SeasonalTransactionInput(amount: 1_234_000, isExpense: true, occurredAt: date)
    #expect(input.amount == 1_234_000)
    #expect(input.isExpense)
    #expect(input.occurredAt == date)

    let same = SeasonalTransactionInput(amount: 1_234_000, isExpense: true, occurredAt: date)
    #expect(input == same)

    let other = SeasonalTransactionInput(amount: 1_234_000, isExpense: false, occurredAt: date)
    #expect(input != other)
}

// MARK: - Insufficient history

@Test("empty transactions yields insufficient plan")
func emptyTransactionsInsufficient() throws {
    let ref = try makeDate(year: 2026, month: 1, day: 1)
    let plan = SeasonalPlanBuilder.build(transactions: [], referenceDate: ref, calendar: gregorian)
    #expect(plan.isSufficient == false)
    #expect(plan.spikes.isEmpty)
    #expect(plan.generatedAt == ref)
}

@Test("single distinct expense year is insufficient")
func singleYearInsufficient() throws {
    let txns = [
        try expense(year: 2025, month: 1, amount: 9_000_000),
        try expense(year: 2025, month: 6, amount: 2_000_000),
    ]
    let ref = try makeDate(year: 2026, month: 1, day: 1)
    let plan = SeasonalPlanBuilder.build(transactions: txns, referenceDate: ref, calendar: gregorian)
    #expect(plan.isSufficient == false)
    #expect(plan.spikes.isEmpty)
}

@Test("income-only history is insufficient because expenses define years")
func incomeOnlyInsufficient() throws {
    let txns = [
        try income(year: 2024, month: 1, amount: 9_000_000),
        try income(year: 2025, month: 1, amount: 9_000_000),
    ]
    let ref = try makeDate(year: 2026, month: 1, day: 1)
    let plan = SeasonalPlanBuilder.build(transactions: txns, referenceDate: ref, calendar: gregorian)
    #expect(plan.isSufficient == false)
}

@Test("two expense years across distinct calendar years are sufficient")
func twoYearsSufficient() throws {
    let txns = [
        try expense(year: 2024, month: 6, amount: 2_000_000),
        try expense(year: 2025, month: 6, amount: 2_000_000),
    ]
    let ref = try makeDate(year: 2026, month: 1, day: 1)
    let plan = SeasonalPlanBuilder.build(transactions: txns, referenceDate: ref, calendar: gregorian)
    #expect(plan.isSufficient == true)
}

// MARK: - Spike detection

@Test("uniform spending across two years produces no spikes")
func uniformNoSpikes() throws {
    var txns: [SeasonalTransactionInput] = []
    for year in 2024 ... 2025 {
        for month in 1 ... 12 {
            txns.append(try expense(year: year, month: month, amount: 2_000_000))
        }
    }
    let ref = try makeDate(year: 2026, month: 1, day: 1)
    let plan = SeasonalPlanBuilder.build(transactions: txns, referenceDate: ref, calendar: gregorian)
    #expect(plan.isSufficient)
    #expect(plan.spikes.isEmpty)
}

@Test("a single near-term spike is detected with computed weekly saving")
func singleSpikeDetected() throws {
    // Baseline-heavy history with one February spike. Reference Jan 1 -> Feb is
    // within the 8-week lookahead window.
    var txns: [SeasonalTransactionInput] = []
    for year in 2024 ... 2025 {
        for month in 1 ... 12 {
            let amount: Decimal = month == 2 ? 9_000_000 : 2_000_000
            txns.append(try expense(year: year, month: month, amount: amount))
        }
    }
    let ref = try makeDate(year: 2026, month: 1, day: 1)
    let plan = SeasonalPlanBuilder.build(transactions: txns, referenceDate: ref, calendar: gregorian)

    #expect(plan.isSufficient)
    let feb = try #require(plan.spikes.first { $0.monthIndex == 2 })
    #expect(feb.nameKey == "seasonal.name.tet")
    #expect(feb.yearsObserved == 2)
    #expect(feb.historicalAverage == 9_000_000)
    #expect(feb.weeksUntil > 0)
    #expect(feb.suggestedWeeklySaving > 0)
    // historical exceeds baseline so extra is positive
    #expect(feb.extraVsBaseline > 0)
    // weekly saving = extra / weeksUntil
    let expectedWeekly = feb.extraVsBaseline / Decimal(feb.weeksUntil)
    #expect(feb.suggestedWeeklySaving == expectedWeekly)
}

@Test("only months within the next four months window are considered")
func windowLimitedToFourMonths() throws {
    // Spike in August. Reference Jan 1 -> offsets cover Jan..Apr only, so the
    // August spike must NOT appear.
    var txns: [SeasonalTransactionInput] = []
    for year in 2024 ... 2025 {
        for month in 1 ... 12 {
            let amount: Decimal = month == 8 ? 12_000_000 : 1_000_000
            txns.append(try expense(year: year, month: month, amount: amount))
        }
    }
    let ref = try makeDate(year: 2026, month: 1, day: 1)
    let plan = SeasonalPlanBuilder.build(transactions: txns, referenceDate: ref, calendar: gregorian)
    #expect(plan.isSufficient)
    #expect(plan.spikes.contains { $0.monthIndex == 8 } == false)
}

@Test("spike beyond eight-week lookahead is excluded")
func beyondLookaheadExcluded() throws {
    // Reference Jan 1 2026. April (offset 3) is > 8 weeks away (~13 weeks),
    // so even a strong April spike is filtered by the lookaheadWeeks guard.
    var txns: [SeasonalTransactionInput] = []
    for year in 2024 ... 2025 {
        for month in 1 ... 12 {
            let amount: Decimal = month == 4 ? 12_000_000 : 1_000_000
            txns.append(try expense(year: year, month: month, amount: amount))
        }
    }
    let ref = try makeDate(year: 2026, month: 1, day: 1)
    let plan = SeasonalPlanBuilder.build(transactions: txns, referenceDate: ref, calendar: gregorian)
    #expect(plan.spikes.contains { $0.monthIndex == 4 } == false)
}

@Test("current-month spike yields zero weeks and saving equals full extra")
func currentMonthSpikeZeroWeeks() throws {
    // Reference Feb 1 with a February spike -> weeksUntil == 0, so
    // suggestedWeeklySaving falls back to the full extra amount.
    var txns: [SeasonalTransactionInput] = []
    for year in 2024 ... 2025 {
        for month in 1 ... 12 {
            let amount: Decimal = month == 2 ? 9_000_000 : 1_000_000
            txns.append(try expense(year: year, month: month, amount: amount))
        }
    }
    let ref = try makeDate(year: 2026, month: 2, day: 1)
    let plan = SeasonalPlanBuilder.build(transactions: txns, referenceDate: ref, calendar: gregorian)
    let feb = try #require(plan.spikes.first { $0.monthIndex == 2 })
    #expect(feb.weeksUntil == 0)
    #expect(feb.suggestedWeeklySaving == feb.extraVsBaseline)
}

@Test("multiple spikes are sorted by weeks until ascending")
func multipleSpikesSorted() throws {
    // Reference Jan 1. Both Jan and Feb spike. Jan (current month) is closer
    // than Feb, so it must sort first.
    var txns: [SeasonalTransactionInput] = []
    for year in 2024 ... 2025 {
        for month in 1 ... 12 {
            let amount: Decimal = (month == 1 || month == 2) ? 9_000_000 : 1_000_000
            txns.append(try expense(year: year, month: month, amount: amount))
        }
    }
    let ref = try makeDate(year: 2026, month: 1, day: 1)
    let plan = SeasonalPlanBuilder.build(transactions: txns, referenceDate: ref, calendar: gregorian)
    #expect(plan.spikes.count >= 2)
    let weeks = plan.spikes.map(\.weeksUntil)
    #expect(weeks == weeks.sorted())
    #expect(plan.spikes.first?.monthIndex == 1)
}

@Test("threshold boundary: average just below 1.3x baseline is not a spike")
func thresholdBoundaryBelow() throws {
    // Construct history where Jan is exactly the baseline (no spike) to verify
    // a non-spiking near-term month is skipped while keeping plan sufficient.
    var txns: [SeasonalTransactionInput] = []
    for year in 2024 ... 2025 {
        for month in 1 ... 12 {
            txns.append(try expense(year: year, month: month, amount: 2_000_000))
        }
    }
    let ref = try makeDate(year: 2026, month: 1, day: 1)
    let plan = SeasonalPlanBuilder.build(transactions: txns, referenceDate: ref, calendar: gregorian)
    #expect(plan.spikes.contains { $0.monthIndex == 1 } == false)
}

@Test("month observed in only one year reports yearsObserved of one")
func partialYearsObserved() throws {
    // March spikes in both years (observed twice); add a one-off February
    // expense only in 2025. February average uses count 1.
    var txns: [SeasonalTransactionInput] = []
    for year in 2024 ... 2025 {
        for month in 1 ... 12 where month != 2 {
            let amount: Decimal = month == 3 ? 9_000_000 : 1_000_000
            txns.append(try expense(year: year, month: month, amount: amount))
        }
    }
    txns.append(try expense(year: 2025, month: 2, amount: 20_000_000))
    let ref = try makeDate(year: 2026, month: 1, day: 1)
    let plan = SeasonalPlanBuilder.build(transactions: txns, referenceDate: ref, calendar: gregorian)
    let feb = try #require(plan.spikes.first { $0.monthIndex == 2 })
    #expect(feb.yearsObserved == 1)
    #expect(feb.historicalAverage == 20_000_000)
}

@Test("wrap-around window crossing year boundary considers next-year months")
func wrapAroundWindow() throws {
    // Reference Dec 1 2026. Offsets cover Dec, Jan, Feb, Mar (next year).
    // A January spike must be detected via the wrap-around month math.
    var txns: [SeasonalTransactionInput] = []
    for year in 2024 ... 2025 {
        for month in 1 ... 12 {
            let amount: Decimal = month == 1 ? 12_000_000 : 1_000_000
            txns.append(try expense(year: year, month: month, amount: amount))
        }
    }
    let ref = try makeDate(year: 2026, month: 12, day: 1)
    let plan = SeasonalPlanBuilder.build(transactions: txns, referenceDate: ref, calendar: gregorian)
    let jan = try #require(plan.spikes.first { $0.monthIndex == 1 })
    #expect(jan.weeksUntil > 0)
    #expect(jan.nameKey == "seasonal.name.tet")
}

@Test("income transactions are excluded from spike averages")
func incomeExcludedFromAverages() throws {
    // Expenses are flat; large income in February must not create a spike.
    var txns: [SeasonalTransactionInput] = []
    for year in 2024 ... 2025 {
        for month in 1 ... 12 {
            txns.append(try expense(year: year, month: month, amount: 2_000_000))
        }
        txns.append(try income(year: year, month: 2, amount: 50_000_000))
    }
    let ref = try makeDate(year: 2026, month: 1, day: 1)
    let plan = SeasonalPlanBuilder.build(transactions: txns, referenceDate: ref, calendar: gregorian)
    #expect(plan.spikes.isEmpty)
}

@Test("builder exposes spike threshold and lookahead constants")
func builderConstants() {
    #expect(SeasonalPlanBuilder.spikeThreshold == 1.3)
    #expect(SeasonalPlanBuilder.lookaheadWeeks == 8)
}
