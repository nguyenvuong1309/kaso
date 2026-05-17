import Foundation
import Testing
@testable import RegretScoreDomain

@Test("summary computes regret ratio and category breakdown")
func summaryComputesRatio() throws {
    let ratings = [
        rating(category: "fashion", amount: 1_000_000, score: .strongRegret),
        rating(category: "fashion", amount: 500_000, score: .regret),
        rating(category: "fashion", amount: 700_000, score: .noRegret),
        rating(category: "food", amount: 200_000, score: .neutral),
    ]

    let summary = RegretSummaryBuilder.build(ratings: ratings)

    #expect(summary.totalCount == 4)
    #expect(summary.regretCount == 2)
    #expect(abs(summary.regretRatio - 0.5) < 0.001)
    #expect(summary.totalRegretedAmount == 1_500_000)
    let fashion = try #require(summary.categorySummaries.first { $0.category == "fashion" })
    #expect(abs(fashion.regretRatio - (2.0 / 3.0)) < 0.001)
    #expect(fashion.totalRegretedAmount == 1_500_000)
}

@Test("top regreted purchases sorted by score then amount")
func topRegretedSorted() throws {
    let ratings = [
        rating(category: "fashion", amount: 800_000, score: .regret),
        rating(category: "fashion", amount: 1_500_000, score: .strongRegret),
        rating(category: "food", amount: 200_000, score: .strongRegret),
    ]

    let summary = RegretSummaryBuilder.build(ratings: ratings)

    #expect(summary.topRegretedPurchases.first?.amount == 1_500_000)
    #expect(summary.topRegretedPurchases.last?.amount == 800_000)
}

@Test("reminder builder filters by amount and age")
func reminderBuilderFilters() throws {
    let now = Date(timeIntervalSince1970: 30 * 86_400)
    let recentPurchase = RegretReminderInput(
        transactionID: UUID(),
        title: "Phone case",
        category: "electronics",
        amount: 800_000,
        occurredAt: now.addingTimeInterval(-3 * 86_400)
    )
    let oldExpensive = RegretReminderInput(
        transactionID: UUID(),
        title: "Sneakers",
        category: "fashion",
        amount: 2_000_000,
        occurredAt: now.addingTimeInterval(-10 * 86_400)
    )
    let oldCheap = RegretReminderInput(
        transactionID: UUID(),
        title: "Coffee",
        category: "food",
        amount: 80_000,
        occurredAt: now.addingTimeInterval(-10 * 86_400)
    )

    let candidates = RegretReminderBuilder.reminders(
        from: [recentPurchase, oldExpensive, oldCheap],
        ratings: [],
        referenceDate: now
    )

    #expect(candidates.count == 1)
    #expect(candidates.first?.title == "Sneakers")
}

@Test("reminder builder skips already-rated purchases")
func reminderBuilderSkipsRated() throws {
    let now = Date(timeIntervalSince1970: 30 * 86_400)
    let purchaseDate = now.addingTimeInterval(-10 * 86_400)
    let input = RegretReminderInput(
        transactionID: UUID(),
        title: "Sneakers",
        category: "fashion",
        amount: 2_000_000,
        occurredAt: purchaseDate
    )
    let existing = RegretRating(
        purchaseTitle: "Sneakers",
        category: "fashion",
        amount: 2_000_000,
        score: .regret,
        purchasedAt: purchaseDate
    )

    let candidates = RegretReminderBuilder.reminders(
        from: [input],
        ratings: [existing],
        referenceDate: now
    )

    #expect(candidates.isEmpty)
}

private func rating(category: String, amount: Decimal, score: RegretScore) -> RegretRating {
    RegretRating(
        purchaseTitle: "Item",
        category: category,
        amount: amount,
        score: score,
        purchasedAt: Date(timeIntervalSince1970: 0)
    )
}
