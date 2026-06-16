import Foundation
import Testing
@testable import GamificationDomain

@Test("reward event kind id equals its raw value")
func rewardEventKindIdMatchesRawValue() {
    for kind in RewardEventKind.allCases {
        #expect(kind.id == kind.rawValue)
    }
}

@Test("reward event kind exposes the expected point values")
func rewardEventKindPointValues() {
    #expect(RewardEventKind.dailyEntry.points == 10)
    #expect(RewardEventKind.streakMilestone3.points == 30)
    #expect(RewardEventKind.streakMilestone7.points == 80)
    #expect(RewardEventKind.streakMilestone30.points == 300)
    #expect(RewardEventKind.streakMilestone100.points == 1_000)
    #expect(RewardEventKind.noSpendDay.points == 20)
    #expect(RewardEventKind.budgetRespected.points == 50)
    #expect(RewardEventKind.weeklyChallengeCompleted.points == 150)
}

@Test("reward event kind exposes namespaced distinct localization keys")
func rewardEventKindLocalizationKeys() {
    #expect(RewardEventKind.dailyEntry.titleKey == "gamification.reward.dailyEntry.title")
    #expect(
        RewardEventKind.noSpendDay.descriptionKey == "gamification.reward.noSpendDay.description"
    )
    let titleKeys = RewardEventKind.allCases.map(\.titleKey)
    #expect(Set(titleKeys).count == titleKeys.count)
}

@Test("reward event defaults its points to the kind value")
func rewardEventDefaultsPointsToKind() throws {
    let calendar = Calendar(identifier: .gregorian)
    let earnedAt = try makeDate(year: 2026, month: 4, day: 5, calendar: calendar)
    let event = RewardEvent(kind: .budgetRespected, earnedAt: earnedAt)
    #expect(event.points == RewardEventKind.budgetRespected.points)
    #expect(event.kind == .budgetRespected)
    #expect(event.earnedAt == earnedAt)
}

@Test("reward event accepts an explicit points override")
func rewardEventAcceptsPointsOverride() throws {
    let calendar = Calendar(identifier: .gregorian)
    let earnedAt = try makeDate(year: 2026, month: 4, day: 5, calendar: calendar)
    let event = RewardEvent(kind: .weeklyChallengeCompleted, earnedAt: earnedAt, points: 200)
    #expect(event.points == 200)
}

@Test("reward event preserves the supplied identifier")
func rewardEventPreservesIdentifier() throws {
    let calendar = Calendar(identifier: .gregorian)
    let earnedAt = try makeDate(year: 2026, month: 4, day: 5, calendar: calendar)
    let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")
    let resolvedId = try #require(id)
    let event = RewardEvent(id: resolvedId, kind: .dailyEntry, earnedAt: earnedAt)
    #expect(event.id == resolvedId)
}

@Test("reward event codable round-trips through json")
func rewardEventCodableRoundTrip() throws {
    let calendar = Calendar(identifier: .gregorian)
    let earnedAt = try makeDate(year: 2026, month: 4, day: 5, calendar: calendar)
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000002"))
    let event = RewardEvent(id: id, kind: .noSpendDay, earnedAt: earnedAt, points: 99)

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    let data = try encoder.encode(event)
    let decoded = try decoder.decode(RewardEvent.self, from: data)
    #expect(decoded == event)
}

@Test("reward event kind codable round-trips through raw value")
func rewardEventKindCodableRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    for kind in RewardEventKind.allCases {
        let data = try encoder.encode(kind)
        let decoded = try decoder.decode(RewardEventKind.self, from: data)
        #expect(decoded == kind)
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
