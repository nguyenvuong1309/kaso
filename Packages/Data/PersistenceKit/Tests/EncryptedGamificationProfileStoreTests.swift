import Foundation
import GamificationDomain
import Testing
@testable import PersistenceKit

@Test("encrypted gamification store round trips profile and rewards")
func encryptedGamificationStoreRoundTripsProfile() async throws {
    let fileURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("kasoenc")
    let keyData = Data(repeating: 7, count: 32)
    let store = EncryptedGamificationProfileStore(
        fileURL: fileURL,
        keyDataProvider: { keyData }
    )
    let profile = GamificationProfile(
        currentStreak: 5,
        longestStreak: 12,
        totalPoints: 420,
        lastActivityDate: Date(timeIntervalSince1970: 1_800_000_000),
        lastEvaluatedDate: Date(timeIntervalSince1970: 1_800_000_000),
        rewardEvents: [
            RewardEvent(
                kind: .streakMilestone3,
                earnedAt: Date(timeIntervalSince1970: 1_800_000_000)
            ),
        ],
        unlockedMilestones: [.streakMilestone3],
        unlockedAchievements: [.firstSteps, .weekWarrior],
        lastNotifiedFinancialLevel: .bronze,
        activeWeeklyChallenge: WeeklyChallenge(
            kind: .dailyStreak,
            weekStart: Date(timeIntervalSince1970: 1_800_000_000),
            currentProgress: 3
        ),
        completedWeeklyChallenges: [
            WeeklyChallenge(
                kind: .categoryVariety,
                weekStart: Date(timeIntervalSince1970: 1_799_395_200),
                currentProgress: 4,
                completedAt: Date(timeIntervalSince1970: 1_799_481_600)
            ),
        ]
    )

    try await store.save(profile)
    let loaded = try await store.load()

    #expect(loaded == profile)
    #expect(try Data(contentsOf: fileURL).isEmpty == false)
}

@Test("decoding profile without achievements field defaults to empty set")
func decodingProfileWithoutAchievementsDefaultsToEmpty() throws {
    let json = """
    {
      "currentStreak": 4,
      "longestStreak": 9,
      "totalPoints": 120,
      "rewardEvents": [],
      "unlockedMilestones": []
    }
    """.data(using: .utf8) ?? Data()

    let decoded = try JSONDecoder().decode(GamificationProfile.self, from: json)

    #expect(decoded.currentStreak == 4)
    #expect(decoded.longestStreak == 9)
    #expect(decoded.totalPoints == 120)
    #expect(decoded.unlockedAchievements.isEmpty)
    #expect(decoded.lastNotifiedFinancialLevel == nil)
    #expect(decoded.activeWeeklyChallenge == nil)
    #expect(decoded.completedWeeklyChallenges.isEmpty)
}

@Test("clear removes the persisted gamification profile")
func clearRemovesPersistedProfile() async throws {
    let fileURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("kasoenc")
    let store = EncryptedGamificationProfileStore(
        fileURL: fileURL,
        keyDataProvider: { Data(repeating: 9, count: 32) }
    )
    try await store.save(GamificationProfile(currentStreak: 1, longestStreak: 1))
    try await store.clear()

    let loaded = try await store.load()
    #expect(loaded == nil)
}
