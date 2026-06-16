import Foundation
import Testing
@testable import RegretScoreDomain

@Test("summary build returns empty for no ratings")
func summaryBuildEmpty() {
    let summary = RegretSummaryBuilder.build(ratings: [])
    #expect(summary == .empty)
    #expect(summary.totalCount == 0)
    #expect(summary.regretCount == 0)
    #expect(summary.regretRatio == 0)
    #expect(summary.totalRegretedAmount == 0)
    #expect(summary.categorySummaries.isEmpty)
    #expect(summary.topRegretedPurchases.isEmpty)
}

@Test("summary empty constant exposes zeroed fields")
func summaryEmptyConstant() {
    let empty = RegretSummary.empty
    #expect(empty.ratings.isEmpty)
    #expect(empty.totalCount == 0)
    #expect(empty.regretCount == 0)
    #expect(empty.regretRatio == 0)
    #expect(empty.totalRegretedAmount == 0)
    #expect(empty.categorySummaries.isEmpty)
    #expect(empty.topRegretedPurchases.isEmpty)
}

@Test("summary with no regrets reports a zero ratio")
func summaryNoRegrets() throws {
    let calendar = Calendar(identifier: .gregorian)
    let ratings = [
        rating(category: "food", amount: 100_000, score: .noRegret, calendar: calendar),
        rating(category: "food", amount: 200_000, score: .slight, calendar: calendar),
        rating(category: "food", amount: 50_000, score: .neutral, calendar: calendar),
    ]

    let summary = RegretSummaryBuilder.build(ratings: ratings)

    #expect(summary.totalCount == 3)
    #expect(summary.regretCount == 0)
    #expect(summary.regretRatio == 0)
    #expect(summary.totalRegretedAmount == 0)
    #expect(summary.topRegretedPurchases.isEmpty)
    let food = try #require(summary.categorySummaries.first)
    #expect(food.category == "food")
    #expect(food.ratingCount == 3)
    #expect(food.regretRatio == 0)
    #expect(food.totalRegretedAmount == 0)
}

@Test("summary with all regrets reports a ratio of one")
func summaryAllRegrets() {
    let calendar = Calendar(identifier: .gregorian)
    let ratings = [
        rating(category: "fashion", amount: 600_000, score: .regret, calendar: calendar),
        rating(category: "fashion", amount: 900_000, score: .strongRegret, calendar: calendar),
    ]

    let summary = RegretSummaryBuilder.build(ratings: ratings)

    #expect(summary.regretCount == 2)
    #expect(abs(summary.regretRatio - 1.0) < 0.0001)
    #expect(summary.totalRegretedAmount == 1_500_000)
}

@Test("summary sorts category summaries by descending regret ratio")
func summarySortsCategoriesByRatio() throws {
    let calendar = Calendar(identifier: .gregorian)
    let ratings = [
        // fashion: 1/2 regret ratio
        rating(category: "fashion", amount: 100_000, score: .regret, calendar: calendar),
        rating(category: "fashion", amount: 100_000, score: .noRegret, calendar: calendar),
        // electronics: 1/1 regret ratio
        rating(category: "electronics", amount: 500_000, score: .strongRegret, calendar: calendar),
        // food: 0/1 regret ratio
        rating(category: "food", amount: 30_000, score: .neutral, calendar: calendar),
    ]

    let summary = RegretSummaryBuilder.build(ratings: ratings)

    #expect(summary.categorySummaries.count == 3)
    #expect(summary.categorySummaries.first?.category == "electronics")
    #expect(summary.categorySummaries.last?.category == "food")
}

@Test("summary top purchases sort by score then amount and cap at five")
func summaryTopPurchasesCappedAndSorted() {
    let calendar = Calendar(identifier: .gregorian)
    let ratings = [
        rating(category: "a", amount: 100_000, score: .regret, calendar: calendar),
        rating(category: "b", amount: 200_000, score: .regret, calendar: calendar),
        rating(category: "c", amount: 300_000, score: .strongRegret, calendar: calendar),
        rating(category: "d", amount: 400_000, score: .strongRegret, calendar: calendar),
        rating(category: "e", amount: 500_000, score: .regret, calendar: calendar),
        rating(category: "f", amount: 600_000, score: .regret, calendar: calendar),
    ]

    let summary = RegretSummaryBuilder.build(ratings: ratings)

    #expect(summary.topRegretedPurchases.count == 5)
    // strongRegret first, sorted by amount within score.
    #expect(summary.topRegretedPurchases[0].amount == 400_000)
    #expect(summary.topRegretedPurchases[0].score == .strongRegret)
    #expect(summary.topRegretedPurchases[1].amount == 300_000)
    #expect(summary.topRegretedPurchases[1].score == .strongRegret)
    // then regret cases by amount descending.
    #expect(summary.topRegretedPurchases[2].amount == 600_000)
    #expect(summary.topRegretedPurchases[4].amount == 200_000)
}

@Test("summary orders ratings by most recently rated first")
func summaryOrdersRatingsByRatedAt() throws {
    let calendar = Calendar(identifier: .gregorian)
    let purchasedAt = try makeDate(year: 2026, month: 1, day: 1, calendar: calendar)
    let older = RegretRating(
        purchaseTitle: "Older",
        category: "food",
        amount: 100_000,
        score: .neutral,
        purchasedAt: purchasedAt,
        ratedAt: try makeDate(year: 2026, month: 1, day: 5, calendar: calendar)
    )
    let newer = RegretRating(
        purchaseTitle: "Newer",
        category: "food",
        amount: 200_000,
        score: .neutral,
        purchasedAt: purchasedAt,
        ratedAt: try makeDate(year: 2026, month: 1, day: 20, calendar: calendar)
    )

    let summary = RegretSummaryBuilder.build(ratings: [older, newer])

    #expect(summary.ratings.first?.purchaseTitle == "Newer")
    #expect(summary.ratings.last?.purchaseTitle == "Older")
}

@Test("category summary id mirrors the category")
func categorySummaryId() {
    let summary = RegretCategorySummary(
        category: "fashion",
        ratingCount: 3,
        regretRatio: 0.5,
        totalRegretedAmount: 1_000_000
    )
    #expect(summary.id == "fashion")
}

@Test("category summary is equatable")
func categorySummaryEquatable() {
    let a = RegretCategorySummary(category: "food", ratingCount: 1, regretRatio: 0.5, totalRegretedAmount: 100)
    let b = RegretCategorySummary(category: "food", ratingCount: 1, regretRatio: 0.5, totalRegretedAmount: 100)
    let c = RegretCategorySummary(category: "food", ratingCount: 2, regretRatio: 0.5, totalRegretedAmount: 100)
    #expect(a == b)
    #expect(a != c)
}

@Test("summary is equatable through its initializer")
func summaryEquatable() {
    let calendar = Calendar(identifier: .gregorian)
    let ratings = [rating(category: "food", amount: 10, score: .regret, calendar: calendar)]
    let first = RegretSummaryBuilder.build(ratings: ratings)
    let second = RegretSummaryBuilder.build(ratings: ratings)
    #expect(first == second)
    #expect(first != .empty)
}

private func rating(
    category: String,
    amount: Decimal,
    score: RegretScore,
    calendar: Calendar
) -> RegretRating {
    RegretRating(
        purchaseTitle: "Item",
        category: category,
        amount: amount,
        score: score,
        purchasedAt: Date(timeIntervalSince1970: 0)
    )
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
