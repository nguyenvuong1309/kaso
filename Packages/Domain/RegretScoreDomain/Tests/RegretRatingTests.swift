import Foundation
import Testing
@testable import RegretScoreDomain

@Test("regret score raw values map to the 1...5 scale")
func regretScoreRawValues() {
    #expect(RegretScore.noRegret.rawValue == 1)
    #expect(RegretScore.slight.rawValue == 2)
    #expect(RegretScore.neutral.rawValue == 3)
    #expect(RegretScore.regret.rawValue == 4)
    #expect(RegretScore.strongRegret.rawValue == 5)
}

@Test("regret score exposes all five cases")
func regretScoreAllCases() {
    #expect(RegretScore.allCases.count == 5)
    #expect(RegretScore.allCases == [.noRegret, .slight, .neutral, .regret, .strongRegret])
}

@Test("regret score name key is derived from raw value")
func regretScoreNameKey() {
    #expect(RegretScore.noRegret.nameKey == "regret.score.1")
    #expect(RegretScore.neutral.nameKey == "regret.score.3")
    #expect(RegretScore.strongRegret.nameKey == "regret.score.5")
}

@Test("regret score symbol names cover every case")
func regretScoreSymbolNames() {
    #expect(RegretScore.noRegret.symbolName == "hand.thumbsup.fill")
    #expect(RegretScore.slight.symbolName == "hand.thumbsup")
    #expect(RegretScore.neutral.symbolName == "minus.circle")
    #expect(RegretScore.regret.symbolName == "hand.thumbsdown")
    #expect(RegretScore.strongRegret.symbolName == "hand.thumbsdown.fill")
}

@Test("isRegret is true only for regret and strongRegret")
func regretScoreIsRegret() {
    #expect(RegretScore.noRegret.isRegret == false)
    #expect(RegretScore.slight.isRegret == false)
    #expect(RegretScore.neutral.isRegret == false)
    #expect(RegretScore.regret.isRegret == true)
    #expect(RegretScore.strongRegret.isRegret == true)
}

@Test("regret score codable round-trips for every case")
func regretScoreCodableRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    for score in RegretScore.allCases {
        let data = try encoder.encode(score)
        let decoded = try decoder.decode(RegretScore.self, from: data)
        #expect(decoded == score)
    }
}

@Test("regret rating initializer stores all provided fields")
func regretRatingInitializerStoresFields() throws {
    let calendar = Calendar(identifier: .gregorian)
    let purchasedAt = try makeDate(year: 2026, month: 1, day: 2, calendar: calendar)
    let ratedAt = try makeDate(year: 2026, month: 1, day: 9, calendar: calendar)
    let id = UUID(uuidString: "11111111-1111-1111-1111-111111111111")
    let rating = RegretRating(
        id: try #require(id),
        purchaseTitle: "Sneakers",
        category: "fashion",
        amount: 1_500_000,
        score: .regret,
        note: "Impulse buy",
        purchasedAt: purchasedAt,
        ratedAt: ratedAt
    )

    #expect(rating.id == id)
    #expect(rating.purchaseTitle == "Sneakers")
    #expect(rating.category == "fashion")
    #expect(rating.amount == 1_500_000)
    #expect(rating.score == .regret)
    #expect(rating.note == "Impulse buy")
    #expect(rating.purchasedAt == purchasedAt)
    #expect(rating.ratedAt == ratedAt)
}

@Test("regret rating note defaults to nil")
func regretRatingNoteDefaultsNil() throws {
    let calendar = Calendar(identifier: .gregorian)
    let purchasedAt = try makeDate(year: 2026, month: 3, day: 1, calendar: calendar)
    let rating = RegretRating(
        purchaseTitle: "Coffee",
        category: "food",
        amount: 80_000,
        score: .neutral,
        purchasedAt: purchasedAt
    )

    #expect(rating.note == nil)
}

@Test("regret rating codable round-trips with and without a note")
func regretRatingCodableRoundTrip() throws {
    let calendar = Calendar(identifier: .gregorian)
    let purchasedAt = try makeDate(year: 2026, month: 5, day: 4, calendar: calendar)
    let ratedAt = try makeDate(year: 2026, month: 5, day: 12, calendar: calendar)
    let withNote = RegretRating(
        id: try #require(UUID(uuidString: "22222222-2222-2222-2222-222222222222")),
        purchaseTitle: "Headphones",
        category: "electronics",
        amount: 2_400_000,
        score: .strongRegret,
        note: "Did not need these",
        purchasedAt: purchasedAt,
        ratedAt: ratedAt
    )
    let withoutNote = RegretRating(
        id: try #require(UUID(uuidString: "33333333-3333-3333-3333-333333333333")),
        purchaseTitle: "Book",
        category: "books",
        amount: 150_000,
        score: .noRegret,
        purchasedAt: purchasedAt,
        ratedAt: ratedAt
    )

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    for rating in [withNote, withoutNote] {
        let data = try encoder.encode(rating)
        let decoded = try decoder.decode(RegretRating.self, from: data)
        #expect(decoded == rating)
    }
}

@Test("regret rating equatable distinguishes differing fields")
func regretRatingEquatable() throws {
    let calendar = Calendar(identifier: .gregorian)
    let purchasedAt = try makeDate(year: 2026, month: 2, day: 2, calendar: calendar)
    let ratedAt = try makeDate(year: 2026, month: 2, day: 10, calendar: calendar)
    let id = try #require(UUID(uuidString: "44444444-4444-4444-4444-444444444444"))
    let base = RegretRating(
        id: id,
        purchaseTitle: "Bag",
        category: "fashion",
        amount: 900_000,
        score: .slight,
        purchasedAt: purchasedAt,
        ratedAt: ratedAt
    )
    let same = RegretRating(
        id: id,
        purchaseTitle: "Bag",
        category: "fashion",
        amount: 900_000,
        score: .slight,
        purchasedAt: purchasedAt,
        ratedAt: ratedAt
    )
    let different = RegretRating(
        id: id,
        purchaseTitle: "Bag",
        category: "fashion",
        amount: 900_000,
        score: .regret,
        purchasedAt: purchasedAt,
        ratedAt: ratedAt
    )

    #expect(base == same)
    #expect(base != different)
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
