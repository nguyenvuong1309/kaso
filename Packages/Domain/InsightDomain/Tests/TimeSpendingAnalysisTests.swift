import Foundation
import Testing
@testable import InsightDomain

@Test("configuration uses documented default values")
func configurationDefaults() {
    let configuration = TimeSpendingAnalysisConfiguration()
    #expect(configuration.lookbackMonthCount == 3)
    #expect(configuration.minimumTransactionCount == 5)
    #expect(configuration.topWeekdayCount == 2)
    #expect(configuration.topHourCount == 1)
    #expect(configuration.eveningStartHour == 20)
    #expect(configuration.eveningShareThreshold == (Decimal(string: "0.3") ?? 0.3))
    #expect(configuration.minimumEveningAmount == 100_000)
}

@Test("analysis isEmpty is true only when all patterns are absent")
func analysisIsEmpty() {
    let empty = TimeSpendingAnalysis(
        totalExpense: 0,
        transactionCount: 0,
        peakWeekdays: [],
        peakHours: [],
        eveningSpike: nil
    )
    #expect(empty.isEmpty)

    let withWeekday = TimeSpendingAnalysis(
        totalExpense: 100,
        transactionCount: 1,
        peakWeekdays: [WeekdaySpendingPattern(weekday: 6, amount: 100, transactionCount: 1, shareOfTotal: 1)],
        peakHours: [],
        eveningSpike: nil
    )
    #expect(withWeekday.isEmpty == false)

    let withEvening = TimeSpendingAnalysis(
        totalExpense: 100,
        transactionCount: 1,
        peakWeekdays: [],
        peakHours: [],
        eveningSpike: EveningSpendingPattern(startHour: 20, amount: 100, transactionCount: 1, shareOfTotal: 1)
    )
    #expect(withEvening.isEmpty == false)
}

@Test("pattern identifiers encode their dimension value")
func patternIdentifiers() {
    let weekday = WeekdaySpendingPattern(weekday: 6, amount: 1, transactionCount: 1, shareOfTotal: 0)
    let hour = HourlySpendingPattern(hour: 21, amount: 1, transactionCount: 1, shareOfTotal: 0)
    let evening = EveningSpendingPattern(startHour: 20, amount: 1, transactionCount: 1, shareOfTotal: 0)
    #expect(weekday.id == "weekday-6")
    #expect(hour.id == "hour-21")
    #expect(evening.id == "evening-20")
}

@Test("patterns expose stored fields")
func patternsStoreFields() {
    let weekday = WeekdaySpendingPattern(
        weekday: 2,
        amount: 500_000,
        transactionCount: 3,
        shareOfTotal: Decimal(string: "0.5") ?? 0
    )
    #expect(weekday.weekday == 2)
    #expect(weekday.amount == 500_000)
    #expect(weekday.transactionCount == 3)
    #expect(weekday.shareOfTotal == (Decimal(string: "0.5") ?? 0))
}
