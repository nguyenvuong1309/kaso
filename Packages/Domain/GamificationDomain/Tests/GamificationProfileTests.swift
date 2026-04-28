import Foundation
import Testing
@testable import GamificationDomain

@Test("profile reports level from current streak")
func profileLevelMatchesCurrentStreak() {
    let profile = GamificationProfile(currentStreak: 8)
    #expect(profile.level == .disciplined)
    #expect(profile.nextLevel == .master)
    #expect(profile.daysToNextLevel == 22)
}

@Test("progress to next level is normalized between 0 and 1")
func progressIsNormalized() {
    let halfWay = GamificationProfile(currentStreak: 18)
    let progress = halfWay.progressToNextLevel
    #expect(progress > 0.45)
    #expect(progress < 0.55)

    let topLevel = GamificationProfile(currentStreak: 250)
    #expect(topLevel.progressToNextLevel == 1)
    #expect(topLevel.nextLevel == nil)
    #expect(topLevel.daysToNextLevel == nil)
}

@Test("progress collapses to one when next threshold equals current threshold")
func progressDefaultsToOneWhenStreakAtMax() {
    let profile = GamificationProfile(currentStreak: 100)
    #expect(profile.level == .legendary)
    #expect(profile.progressToNextLevel == 1)
}
