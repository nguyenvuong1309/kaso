import Foundation
import Testing
@testable import GoalDomain

@Test("returns zero remaining when current equals target")
func progressRemainingZeroAtTarget() {
    let progress = SavingGoalProgress(currentAmount: 5_000_000, targetAmount: 5_000_000)

    #expect(progress.remainingAmount == 0)
    #expect(progress.isCompleted)
    #expect(progress.fraction == 1)
    #expect(progress.percent == 100)
}

@Test("returns zero remaining when overfunded")
func progressRemainingZeroWhenOverfunded() {
    let progress = SavingGoalProgress(currentAmount: 8_000_000, targetAmount: 5_000_000)

    #expect(progress.remainingAmount == 0)
    #expect(progress.isCompleted)
}

@Test("computes positive remaining amount below target")
func progressRemainingPositive() {
    let progress = SavingGoalProgress(currentAmount: 2_000_000, targetAmount: 5_000_000)

    #expect(progress.remainingAmount == 3_000_000)
    #expect(progress.isCompleted == false)
}

@Test("fraction is zero when target is zero")
func progressFractionZeroTarget() {
    let progress = SavingGoalProgress(currentAmount: 1_000_000, targetAmount: 0)

    #expect(progress.fraction == 0)
    #expect(progress.percent == 0)
    #expect(progress.isCompleted == false)
}

@Test("fraction clamps negative current amount to zero")
func progressFractionClampsNegative() {
    let progress = SavingGoalProgress(currentAmount: -1_000_000, targetAmount: 5_000_000)

    #expect(progress.fraction == 0)
    #expect(progress.percent == 0)
}

@Test("fraction clamps to one when overfunded")
func progressFractionClampsToOne() {
    let progress = SavingGoalProgress(currentAmount: 10_000_000, targetAmount: 5_000_000)

    #expect(progress.fraction == 1)
    #expect(progress.percent == 100)
}

@Test("computes partial fraction and percent")
func progressPartialFraction() {
    let progress = SavingGoalProgress(currentAmount: 3_000_000, targetAmount: 4_000_000)

    #expect(progress.fraction == 0.75)
    #expect(progress.percent == 75)
}

@Test("is not completed when target is zero even with positive current")
func progressNotCompletedWithZeroTarget() {
    let progress = SavingGoalProgress(currentAmount: 1, targetAmount: 0)

    #expect(progress.isCompleted == false)
}

@Test("round-trips progress through Codable")
func progressCodableRoundTrip() throws {
    let progress = SavingGoalProgress(currentAmount: 1_234_567, targetAmount: 9_999_999)
    let data = try JSONEncoder().encode(progress)
    let decoded = try JSONDecoder().decode(SavingGoalProgress.self, from: data)

    #expect(decoded == progress)
}
