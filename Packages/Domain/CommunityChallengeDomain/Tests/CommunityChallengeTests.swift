import Foundation
import Testing
@testable import CommunityChallengeDomain

struct CommunityChallengeTests {
    // MARK: - Helpers

    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        calendar: Calendar = Calendar(identifier: .gregorian)
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

    private let fixedID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")

    // MARK: - Category

    @Test("category exposes all five cases via CaseIterable")
    func categoryAllCases() {
        let all = CommunityChallengeCategory.allCases
        #expect(all.count == 5)
        #expect(all.contains(.noSpend))
        #expect(all.contains(.mindfulEating))
        #expect(all.contains(.subscriptionCleanup))
        #expect(all.contains(.gratitude))
        #expect(all.contains(.savingsBoost))
    }

    @Test("category labelKey is namespaced by raw value")
    func categoryLabelKey() {
        #expect(CommunityChallengeCategory.noSpend.labelKey == "communityChallenge.category.noSpend")
        #expect(CommunityChallengeCategory.mindfulEating.labelKey == "communityChallenge.category.mindfulEating")
        #expect(
            CommunityChallengeCategory.subscriptionCleanup.labelKey
                == "communityChallenge.category.subscriptionCleanup"
        )
        #expect(CommunityChallengeCategory.gratitude.labelKey == "communityChallenge.category.gratitude")
        #expect(CommunityChallengeCategory.savingsBoost.labelKey == "communityChallenge.category.savingsBoost")
    }

    @Test("category iconSystemName maps each case to its SF Symbol")
    func categoryIconSystemName() {
        #expect(CommunityChallengeCategory.noSpend.iconSystemName == "calendar.badge.minus")
        #expect(CommunityChallengeCategory.mindfulEating.iconSystemName == "fork.knife")
        #expect(CommunityChallengeCategory.subscriptionCleanup.iconSystemName == "scissors")
        #expect(CommunityChallengeCategory.gratitude.iconSystemName == "heart")
        #expect(CommunityChallengeCategory.savingsBoost.iconSystemName == "leaf.arrow.circlepath")
    }

    @Test("category raw values round-trip from string")
    func categoryRawValueRoundTrip() {
        for category in CommunityChallengeCategory.allCases {
            #expect(CommunityChallengeCategory(rawValue: category.rawValue) == category)
        }
        #expect(CommunityChallengeCategory(rawValue: "unknown") == nil)
    }

    // MARK: - Difficulty

    @Test("difficulty labelKey is namespaced by raw value")
    func difficultyLabelKey() {
        #expect(CommunityChallengeDifficulty.easy.labelKey == "communityChallenge.difficulty.easy")
        #expect(CommunityChallengeDifficulty.medium.labelKey == "communityChallenge.difficulty.medium")
        #expect(CommunityChallengeDifficulty.hard.labelKey == "communityChallenge.difficulty.hard")
    }

    @Test("difficulty raw values round-trip from string")
    func difficultyRawValueRoundTrip() {
        #expect(CommunityChallengeDifficulty(rawValue: "easy") == .easy)
        #expect(CommunityChallengeDifficulty(rawValue: "medium") == .medium)
        #expect(CommunityChallengeDifficulty(rawValue: "hard") == .hard)
        #expect(CommunityChallengeDifficulty(rawValue: "extreme") == nil)
    }

    // MARK: - CommunityChallenge value type

    @Test("challenge initializer stores every field")
    func challengeInit() {
        let challenge = CommunityChallenge(
            id: "demo",
            titleKey: "t",
            descriptionKey: "d",
            goalKey: "g",
            durationDays: 10,
            category: .gratitude,
            difficulty: .medium
        )
        #expect(challenge.id == "demo")
        #expect(challenge.titleKey == "t")
        #expect(challenge.descriptionKey == "d")
        #expect(challenge.goalKey == "g")
        #expect(challenge.durationDays == 10)
        #expect(challenge.category == .gratitude)
        #expect(challenge.difficulty == .medium)
    }

    @Test("challenge equality is value-based")
    func challengeEquality() {
        let a = CommunityChallenge(
            id: "x",
            titleKey: "t",
            descriptionKey: "d",
            goalKey: "g",
            durationDays: 5,
            category: .noSpend,
            difficulty: .easy
        )
        let b = CommunityChallenge(
            id: "x",
            titleKey: "t",
            descriptionKey: "d",
            goalKey: "g",
            durationDays: 5,
            category: .noSpend,
            difficulty: .easy
        )
        let different = CommunityChallenge(
            id: "y",
            titleKey: "t",
            descriptionKey: "d",
            goalKey: "g",
            durationDays: 5,
            category: .noSpend,
            difficulty: .easy
        )
        #expect(a == b)
        #expect(a != different)
    }

    // MARK: - Enrollment defaults & init

    @Test("enrollment default values are zeroed and not completed")
    func enrollmentDefaults() throws {
        let id = try #require(fixedID)
        let start = try makeDate(year: 2026, month: 1, day: 1)
        let enrollment = CommunityChallengeEnrollment(
            id: id,
            challengeID: "noSpend-week",
            startedAt: start
        )
        #expect(enrollment.id == id)
        #expect(enrollment.challengeID == "noSpend-week")
        #expect(enrollment.startedAt == start)
        #expect(enrollment.checkedInDays == 0)
        #expect(enrollment.isCompleted == false)
    }

    @Test("enrollment is mutable for checkedInDays and isCompleted")
    func enrollmentMutation() throws {
        let id = try #require(fixedID)
        let start = try makeDate(year: 2026, month: 1, day: 1)
        var enrollment = CommunityChallengeEnrollment(
            id: id,
            challengeID: "coffee-skip",
            startedAt: start
        )
        enrollment.checkedInDays = 3
        enrollment.isCompleted = true
        #expect(enrollment.checkedInDays == 3)
        #expect(enrollment.isCompleted)
    }

    // MARK: - progress(durationDays:)

    @Test("progress is fractional for partial completion")
    func progressPartial() throws {
        let id = try #require(fixedID)
        let start = try makeDate(year: 2026, month: 1, day: 1)
        let enrollment = CommunityChallengeEnrollment(
            id: id,
            challengeID: "noSpend-week",
            startedAt: start,
            checkedInDays: 3
        )
        #expect(enrollment.progress(durationDays: 6) == 0.5)
    }

    @Test("progress is zero with no check-ins")
    func progressZeroCheckIns() throws {
        let id = try #require(fixedID)
        let start = try makeDate(year: 2026, month: 1, day: 1)
        let enrollment = CommunityChallengeEnrollment(
            id: id,
            challengeID: "noSpend-week",
            startedAt: start,
            checkedInDays: 0
        )
        #expect(enrollment.progress(durationDays: 7) == 0.0)
    }

    @Test("progress reaches exactly 1.0 when check-ins equal duration")
    func progressExactlyComplete() throws {
        let id = try #require(fixedID)
        let start = try makeDate(year: 2026, month: 1, day: 1)
        let enrollment = CommunityChallengeEnrollment(
            id: id,
            challengeID: "noSpend-week",
            startedAt: start,
            checkedInDays: 7
        )
        #expect(enrollment.progress(durationDays: 7) == 1.0)
    }

    @Test("progress clamps at 1.0 when over-completed")
    func progressClampsOver() throws {
        let id = try #require(fixedID)
        let start = try makeDate(year: 2026, month: 1, day: 1)
        let enrollment = CommunityChallengeEnrollment(
            id: id,
            challengeID: "noSpend-week",
            startedAt: start,
            checkedInDays: 100
        )
        #expect(enrollment.progress(durationDays: 7) == 1.0)
    }

    @Test("progress returns 0 for negative duration")
    func progressNegativeDuration() throws {
        let id = try #require(fixedID)
        let start = try makeDate(year: 2026, month: 1, day: 1)
        let enrollment = CommunityChallengeEnrollment(
            id: id,
            challengeID: "noSpend-week",
            startedAt: start,
            checkedInDays: 5
        )
        #expect(enrollment.progress(durationDays: -3) == 0)
    }

    // MARK: - daysRemaining(durationDays:today:)

    @Test("daysRemaining equals full duration on the start day")
    func daysRemainingOnStartDay() throws {
        let calendar = Calendar(identifier: .gregorian)
        let id = try #require(fixedID)
        let start = try makeDate(year: 2026, month: 3, day: 10, calendar: calendar)
        let enrollment = CommunityChallengeEnrollment(
            id: id,
            challengeID: "coffee-skip",
            startedAt: start
        )
        #expect(enrollment.daysRemaining(durationDays: 14, today: start) == 14)
    }

    @Test("daysRemaining floors at zero after the duration elapses")
    func daysRemainingFloorsAtZero() throws {
        let calendar = Calendar(identifier: .gregorian)
        let id = try #require(fixedID)
        let start = try makeDate(year: 2026, month: 3, day: 1, calendar: calendar)
        let today = try makeDate(year: 2026, month: 3, day: 20, calendar: calendar)
        let enrollment = CommunityChallengeEnrollment(
            id: id,
            challengeID: "subscription-audit",
            startedAt: start
        )
        #expect(enrollment.daysRemaining(durationDays: 7, today: today) == 0)
    }

    @Test("daysRemaining handles a today earlier than start as full duration")
    func daysRemainingTodayBeforeStart() throws {
        let calendar = Calendar(identifier: .gregorian)
        let id = try #require(fixedID)
        let start = try makeDate(year: 2026, month: 3, day: 10, calendar: calendar)
        let today = try makeDate(year: 2026, month: 3, day: 5, calendar: calendar)
        let enrollment = CommunityChallengeEnrollment(
            id: id,
            challengeID: "coffee-skip",
            startedAt: start
        )
        // elapsed is negative, so durationDays - elapsed exceeds duration.
        #expect(enrollment.daysRemaining(durationDays: 14, today: today) == 19)
    }

    @Test("daysRemaining hits exactly zero on the final day")
    func daysRemainingExactlyZero() throws {
        let calendar = Calendar(identifier: .gregorian)
        let id = try #require(fixedID)
        let start = try makeDate(year: 2026, month: 3, day: 1, calendar: calendar)
        let today = try makeDate(year: 2026, month: 3, day: 8, calendar: calendar)
        let enrollment = CommunityChallengeEnrollment(
            id: id,
            challengeID: "subscription-audit",
            startedAt: start
        )
        #expect(enrollment.daysRemaining(durationDays: 7, today: today) == 0)
    }

    // MARK: - Enrollment equality

    @Test("enrollment equality is value-based across all fields")
    func enrollmentEquality() throws {
        let id = try #require(fixedID)
        let start = try makeDate(year: 2026, month: 1, day: 1)
        let a = CommunityChallengeEnrollment(
            id: id,
            challengeID: "noSpend-week",
            startedAt: start,
            checkedInDays: 2,
            isCompleted: false
        )
        let b = CommunityChallengeEnrollment(
            id: id,
            challengeID: "noSpend-week",
            startedAt: start,
            checkedInDays: 2,
            isCompleted: false
        )
        let different = CommunityChallengeEnrollment(
            id: id,
            challengeID: "noSpend-week",
            startedAt: start,
            checkedInDays: 3,
            isCompleted: false
        )
        #expect(a == b)
        #expect(a != different)
    }
}
