import Foundation
import Testing
@testable import MoodJournalDomain

@Test("empty entries return empty insight")
func emptyEntriesReturnEmptyInsight() {
    #expect(MoodInsightCalculator.insight(from: []) == .empty)
}

@Test("breakdown groups entries by mood and averages spending")
func breakdownAveragesByMood() throws {
    let entries = [
        MoodEntry(mood: .stressed, spendingTotalSnapshot: 500_000),
        MoodEntry(mood: .stressed, spendingTotalSnapshot: 700_000),
        MoodEntry(mood: .good, spendingTotalSnapshot: 200_000),
    ]

    let insight = MoodInsightCalculator.insight(from: entries)
    let stressed = try #require(insight.breakdowns.first { $0.mood == .stressed })
    let good = try #require(insight.breakdowns.first { $0.mood == .good })

    #expect(stressed.entryCount == 2)
    #expect(stressed.averageSpending == 600_000)
    #expect(good.averageSpending == 200_000)
    #expect(insight.overallAverageSpending == (500_000 + 700_000 + 200_000) / Decimal(3))
}

@Test("delta percent compares negative vs positive moods")
func deltaPercentComparesMoods() throws {
    let entries = [
        MoodEntry(mood: .stressed, spendingTotalSnapshot: 600_000),
        MoodEntry(mood: .anxious, spendingTotalSnapshot: 600_000),
        MoodEntry(mood: .good, spendingTotalSnapshot: 200_000),
        MoodEntry(mood: .great, spendingTotalSnapshot: 400_000),
    ]

    let insight = MoodInsightCalculator.insight(from: entries)

    #expect(insight.negativeMoodAverage == 600_000)
    #expect(insight.positiveMoodAverage == 300_000)
    let delta = try #require(insight.deltaPercent)
    #expect(abs(delta - 100.0) < 0.001)
}

@Test("delta percent is nil when one side has no entries")
func deltaNilWhenOneSideEmpty() {
    let entries = [
        MoodEntry(mood: .stressed, spendingTotalSnapshot: 100_000),
    ]
    let insight = MoodInsightCalculator.insight(from: entries)
    #expect(insight.deltaPercent == nil)
}

@Test("hasEnoughData true when 6 or more entries")
func hasEnoughDataAtSix() {
    let few = (0 ..< 5).map { _ in MoodEntry(mood: .good, spendingTotalSnapshot: 100_000) }
    let enough = (0 ..< 6).map { _ in MoodEntry(mood: .good, spendingTotalSnapshot: 100_000) }

    #expect(MoodInsightCalculator.insight(from: few).hasEnoughData == false)
    #expect(MoodInsightCalculator.insight(from: enough).hasEnoughData == true)
}
