import Foundation
import Testing
@testable import CommunityChallengeDomain

struct CommunityChallengeDomainTests {
    @Test("library exposes at least 5 challenges with unique IDs")
    func libraryHasChallenges() {
        let library = CommunityChallengeLibrary.challenges
        let ids = Set(library.map(\.id))
        #expect(library.count >= 5)
        #expect(ids.count == library.count)
    }

    @Test("progress clamps to [0,1]")
    func progressClamps() {
        let enrollment = CommunityChallengeEnrollment(
            challengeID: "noSpend-week",
            checkedInDays: 14
        )
        #expect(enrollment.progress(durationDays: 7) == 1.0)
        #expect(enrollment.progress(durationDays: 0) == 0)
    }

    @Test("daysRemaining counts down")
    func daysRemainingCountsDown() {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1)) ?? Date()
        let today = calendar.date(from: DateComponents(year: 2026, month: 1, day: 3)) ?? start
        let enrollment = CommunityChallengeEnrollment(
            challengeID: "noSpend-week",
            startedAt: start
        )
        #expect(enrollment.daysRemaining(durationDays: 7, today: today) == 5)
    }
}
