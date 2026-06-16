import Foundation
import Testing
@testable import MoodJournalDomain

@Test("MoodSpendingBreakdown initializer stores all values and id is the mood")
func breakdownInitAndID() {
    let breakdown = MoodSpendingBreakdown(
        mood: .stressed,
        entryCount: 3,
        averageSpending: 250_000,
        totalSpending: 750_000
    )

    #expect(breakdown.mood == .stressed)
    #expect(breakdown.entryCount == 3)
    #expect(breakdown.averageSpending == Decimal(250_000))
    #expect(breakdown.totalSpending == Decimal(750_000))
    #expect(breakdown.id == Mood.stressed)
}

@Test("MoodSpendingBreakdown equatable distinguishes differing fields")
func breakdownEquatable() {
    let base = MoodSpendingBreakdown(mood: .good, entryCount: 2, averageSpending: 100_000, totalSpending: 200_000)
    let same = MoodSpendingBreakdown(mood: .good, entryCount: 2, averageSpending: 100_000, totalSpending: 200_000)
    let differentCount = MoodSpendingBreakdown(mood: .good, entryCount: 3, averageSpending: 100_000, totalSpending: 200_000)
    let differentMood = MoodSpendingBreakdown(mood: .sad, entryCount: 2, averageSpending: 100_000, totalSpending: 200_000)

    #expect(base == same)
    #expect(base != differentCount)
    #expect(base != differentMood)
}

@Test("MoodInsight initializer stores all provided values")
func insightInitStoresValues() {
    let breakdown = MoodSpendingBreakdown(mood: .anxious, entryCount: 1, averageSpending: 50_000, totalSpending: 50_000)
    let insight = MoodInsight(
        breakdowns: [breakdown],
        overallAverageSpending: 50_000,
        negativeMoodAverage: 50_000,
        positiveMoodAverage: 10_000,
        deltaPercent: 400.0,
        entryCount: 7,
        hasEnoughData: true
    )

    #expect(insight.breakdowns == [breakdown])
    #expect(insight.overallAverageSpending == Decimal(50_000))
    #expect(insight.negativeMoodAverage == Decimal(50_000))
    #expect(insight.positiveMoodAverage == Decimal(10_000))
    #expect(insight.deltaPercent == 400.0)
    #expect(insight.entryCount == 7)
    #expect(insight.hasEnoughData == true)
}

@Test("MoodInsight.empty has zeroed fields and nil delta")
func insightEmptyDefaults() {
    let empty = MoodInsight.empty
    #expect(empty.breakdowns.isEmpty)
    #expect(empty.overallAverageSpending == Decimal(0))
    #expect(empty.negativeMoodAverage == Decimal(0))
    #expect(empty.positiveMoodAverage == Decimal(0))
    #expect(empty.deltaPercent == nil)
    #expect(empty.entryCount == 0)
    #expect(empty.hasEnoughData == false)
}

@Test("MoodInsight equatable distinguishes differing fields")
func insightEquatable() {
    let a = MoodInsight.empty
    var b = MoodInsight.empty
    b.entryCount = 1
    #expect(a == MoodInsight.empty)
    #expect(a != b)
}
