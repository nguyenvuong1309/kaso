import Foundation
import Testing
@testable import MoodJournalDomain

@Test("minimum entries threshold constant is six")
func minimumEntriesConstant() {
    #expect(MoodInsightCalculator.minimumEntriesForInsight == 6)
}

@Test("breakdowns are sorted by descending average spending")
func breakdownsSortedDescending() throws {
    let entries = [
        MoodEntry(mood: .good, spendingTotalSnapshot: 100_000),
        MoodEntry(mood: .stressed, spendingTotalSnapshot: 900_000),
        MoodEntry(mood: .neutral, spendingTotalSnapshot: 400_000),
    ]

    let insight = MoodInsightCalculator.insight(from: entries)
    let averages = insight.breakdowns.map(\.averageSpending)

    #expect(insight.breakdowns.count == 3)
    #expect(averages == [Decimal(900_000), Decimal(400_000), Decimal(100_000)])
    let first = try #require(insight.breakdowns.first)
    #expect(first.mood == .stressed)
}

@Test("breakdown totals and per-mood entry counts accumulate correctly")
func breakdownTotalsAccumulate() throws {
    let entries = [
        MoodEntry(mood: .anxious, spendingTotalSnapshot: 100_000),
        MoodEntry(mood: .anxious, spendingTotalSnapshot: 200_000),
        MoodEntry(mood: .anxious, spendingTotalSnapshot: 300_000),
    ]

    let insight = MoodInsightCalculator.insight(from: entries)
    let anxious = try #require(insight.breakdowns.first { $0.mood == .anxious })

    #expect(anxious.entryCount == 3)
    #expect(anxious.totalSpending == Decimal(600_000))
    #expect(anxious.averageSpending == Decimal(200_000))
}

@Test("single entry produces one breakdown and matching overall average")
func singleEntryInsight() throws {
    let entries = [MoodEntry(mood: .neutral, spendingTotalSnapshot: 333_000)]
    let insight = MoodInsightCalculator.insight(from: entries)

    #expect(insight.entryCount == 1)
    #expect(insight.breakdowns.count == 1)
    #expect(insight.overallAverageSpending == Decimal(333_000))
}

@Test("only neutral moods yield zero positive and negative averages and nil delta")
func neutralOnlyAverages() {
    let entries = [
        MoodEntry(mood: .neutral, spendingTotalSnapshot: 100_000),
        MoodEntry(mood: .neutral, spendingTotalSnapshot: 300_000),
    ]
    let insight = MoodInsightCalculator.insight(from: entries)

    #expect(insight.negativeMoodAverage == Decimal(0))
    #expect(insight.positiveMoodAverage == Decimal(0))
    #expect(insight.deltaPercent == nil)
    #expect(insight.overallAverageSpending == Decimal(200_000))
}

@Test("delta is nil when only negative moods are present")
func deltaNilWhenOnlyNegative() {
    let entries = [
        MoodEntry(mood: .stressed, spendingTotalSnapshot: 100_000),
        MoodEntry(mood: .sad, spendingTotalSnapshot: 200_000),
    ]
    let insight = MoodInsightCalculator.insight(from: entries)

    #expect(insight.negativeMoodAverage == Decimal(150_000))
    #expect(insight.positiveMoodAverage == Decimal(0))
    #expect(insight.deltaPercent == nil)
}

@Test("delta is nil when only positive moods are present")
func deltaNilWhenOnlyPositive() {
    let entries = [
        MoodEntry(mood: .great, spendingTotalSnapshot: 100_000),
        MoodEntry(mood: .good, spendingTotalSnapshot: 200_000),
    ]
    let insight = MoodInsightCalculator.insight(from: entries)

    #expect(insight.positiveMoodAverage == Decimal(150_000))
    #expect(insight.negativeMoodAverage == Decimal(0))
    #expect(insight.deltaPercent == nil)
}

@Test("negative delta when negative moods spend less than positive moods")
func negativeDeltaWhenNegativeSpendsLess() throws {
    let entries = [
        MoodEntry(mood: .stressed, spendingTotalSnapshot: 100_000),
        MoodEntry(mood: .good, spendingTotalSnapshot: 200_000),
    ]
    let insight = MoodInsightCalculator.insight(from: entries)
    let delta = try #require(insight.deltaPercent)

    #expect(abs(delta - (-50.0)) < 0.001)
}

@Test("neutral entries are excluded from positive and negative averages")
func neutralExcludedFromAverages() {
    let entries = [
        MoodEntry(mood: .neutral, spendingTotalSnapshot: 1_000_000),
        MoodEntry(mood: .great, spendingTotalSnapshot: 200_000),
        MoodEntry(mood: .stressed, spendingTotalSnapshot: 400_000),
    ]
    let insight = MoodInsightCalculator.insight(from: entries)

    #expect(insight.positiveMoodAverage == Decimal(200_000))
    #expect(insight.negativeMoodAverage == Decimal(400_000))
}

@Test("entries with zero spending produce zero averages without dividing by zero")
func zeroSpendingEntries() {
    let entries = [
        MoodEntry(mood: .good, spendingTotalSnapshot: 0),
        MoodEntry(mood: .sad, spendingTotalSnapshot: 0),
    ]
    let insight = MoodInsightCalculator.insight(from: entries)

    #expect(insight.overallAverageSpending == Decimal(0))
    #expect(insight.positiveMoodAverage == Decimal(0))
    #expect(insight.negativeMoodAverage == Decimal(0))
    // positiveAverage is 0, so delta guard returns nil even though both sides exist.
    #expect(insight.deltaPercent == nil)
}
