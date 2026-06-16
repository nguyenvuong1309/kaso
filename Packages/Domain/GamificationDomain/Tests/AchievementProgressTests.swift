import Foundation
import Testing
@testable import GamificationDomain

@Test("progress id derives from its kind")
func progressIdMatchesKind() {
    let progress = AchievementProgress(kind: .weekWarrior, currentValue: 3, isUnlocked: false)
    #expect(progress.id == AchievementKind.weekWarrior.id)
}

@Test("progress target value forwards to its kind")
func progressTargetValueForwardsToKind() {
    let progress = AchievementProgress(kind: .centuryClub, currentValue: 10, isUnlocked: false)
    #expect(progress.targetValue == AchievementKind.centuryClub.targetValue)
    #expect(progress.targetValue == 100)
}

@Test("progress clamps negative current values to zero")
func progressClampsNegativeCurrentValue() {
    let progress = AchievementProgress(kind: .weekWarrior, currentValue: -5, isUnlocked: false)
    #expect(progress.currentValue == 0)
    #expect(progress.ratio == 0)
    #expect(progress.displayValue == 0)
}

@Test("progress ratio is the normalized fraction toward the target")
func progressRatioIsFractionOfTarget() {
    let progress = AchievementProgress(kind: .weekWarrior, currentValue: 3, isUnlocked: false)
    #expect(progress.ratio > 0.42)
    #expect(progress.ratio < 0.43)
}

@Test("progress ratio is capped at one when overshooting the target")
func progressRatioCapsAtOne() {
    let progress = AchievementProgress(kind: .weekWarrior, currentValue: 20, isUnlocked: true)
    #expect(progress.ratio == 1)
}

@Test("progress display value never exceeds the target")
func progressDisplayValueCapsAtTarget() {
    let below = AchievementProgress(kind: .centuryClub, currentValue: 40, isUnlocked: false)
    #expect(below.displayValue == 40)

    let above = AchievementProgress(kind: .centuryClub, currentValue: 250, isUnlocked: true)
    #expect(above.displayValue == 100)
}

@Test("progress equates by all stored fields")
func progressEquality() {
    let lhs = AchievementProgress(kind: .firstSteps, currentValue: 1, isUnlocked: true)
    let rhs = AchievementProgress(kind: .firstSteps, currentValue: 1, isUnlocked: true)
    let different = AchievementProgress(kind: .firstSteps, currentValue: 0, isUnlocked: false)
    #expect(lhs == rhs)
    #expect(lhs != different)
}

@Test("achievement evaluation stores progresses and newly unlocked kinds")
func achievementEvaluationStoresFields() {
    let progresses = [
        AchievementProgress(kind: .firstSteps, currentValue: 1, isUnlocked: true),
    ]
    let evaluation = AchievementEvaluation(
        progresses: progresses,
        newlyUnlocked: [.firstSteps]
    )
    #expect(evaluation.progresses == progresses)
    #expect(evaluation.newlyUnlocked == [.firstSteps])
}
