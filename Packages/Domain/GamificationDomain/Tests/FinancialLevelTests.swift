import Foundation
import Testing
import TransactionDomain
@testable import GamificationDomain

@Test("financial level resolves from total points")
func financialLevelResolvesFromPoints() {
    #expect(FinancialLevel.level(for: 0) == .sprout)
    #expect(FinancialLevel.level(for: 199) == .sprout)
    #expect(FinancialLevel.level(for: 200) == .bronze)
    #expect(FinancialLevel.level(for: 799) == .bronze)
    #expect(FinancialLevel.level(for: 800) == .silver)
    #expect(FinancialLevel.level(for: 2_000) == .gold)
    #expect(FinancialLevel.level(for: 5_000) == .platinum)
    #expect(FinancialLevel.level(for: 10_000) == .diamond)
    #expect(FinancialLevel.level(for: 25_000) == .legend)
    #expect(FinancialLevel.level(for: 100_000) == .legend)
}

@Test("financial level chains nextLevel and stops at legend")
func financialLevelChainsNextLevel() {
    #expect(FinancialLevel.sprout.nextLevel == .bronze)
    #expect(FinancialLevel.bronze.nextLevel == .silver)
    #expect(FinancialLevel.silver.nextLevel == .gold)
    #expect(FinancialLevel.gold.nextLevel == .platinum)
    #expect(FinancialLevel.platinum.nextLevel == .diamond)
    #expect(FinancialLevel.diamond.nextLevel == .legend)
    #expect(FinancialLevel.legend.nextLevel == nil)
}

@Test("comparable orders levels by minimumPoints")
func financialLevelComparable() {
    #expect(FinancialLevel.bronze < FinancialLevel.silver)
    #expect(FinancialLevel.legend > FinancialLevel.gold)
    let sorted = [FinancialLevel.diamond, .sprout, .gold, .legend].sorted()
    #expect(sorted == [.sprout, .gold, .diamond, .legend])
}

@Test("financial level progress reports remaining points to next tier")
func financialLevelProgressReportsRemainingPoints() {
    let progress = FinancialLevelProgress(totalPoints: 350)
    #expect(progress.level == .bronze)
    #expect(progress.nextLevel == .silver)
    #expect(progress.pointsInCurrentLevel == 150)
    #expect(progress.pointsNeededForNext == 450)
    #expect(progress.ratio > 0.24)
    #expect(progress.ratio < 0.26)
    #expect(progress.isMaxLevel == false)
}

@Test("financial level progress at max level reports ratio of one")
func financialLevelProgressAtMaxLevel() {
    let progress = FinancialLevelProgress(totalPoints: 50_000)
    #expect(progress.level == .legend)
    #expect(progress.ratio == 1)
    #expect(progress.pointsNeededForNext == nil)
    #expect(progress.isMaxLevel)
}

@Test("financial level progress clamps negative totals to sprout")
func financialLevelProgressClampsNegativeTotals() {
    let progress = FinancialLevelProgress(totalPoints: -100)
    #expect(progress.level == .sprout)
    #expect(progress.totalPoints == 0)
    #expect(progress.ratio == 0)
}

@Test("calculator does not celebrate level for first-time users")
func calculatorDoesNotCelebrateLevelForFirstTimeUsers() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try makeDate(year: 2026, month: 4, day: 5, calendar: calendar)
    let transactions = [
        Transaction(amount: 50_000, kind: .expense, category: .food, occurredAt: referenceDate),
    ]

    let evaluation = GamificationCalculator.evaluate(
        profile: GamificationProfile(),
        transactions: transactions,
        budgets: [],
        referenceDate: referenceDate,
        calendar: calendar
    )

    #expect(evaluation.newlyAchievedFinancialLevel == nil)
    #expect(evaluation.profile.lastNotifiedFinancialLevel == .sprout)
}

@Test("calculator celebrates level upgrade when crossing threshold")
func calculatorCelebratesLevelUpgrade() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try makeDate(year: 2026, month: 4, day: 5, calendar: calendar)
    let profile = GamificationProfile(
        currentStreak: 1,
        longestStreak: 1,
        totalPoints: 195,
        lastActivityDate: referenceDate.addingTimeInterval(-3_600 * 24),
        lastEvaluatedDate: referenceDate.addingTimeInterval(-3_600 * 24),
        lastNotifiedFinancialLevel: .sprout
    )
    let transactions = [
        Transaction(amount: 50_000, kind: .expense, category: .food, occurredAt: referenceDate),
    ]

    let evaluation = GamificationCalculator.evaluate(
        profile: profile,
        transactions: transactions,
        budgets: [],
        referenceDate: referenceDate,
        calendar: calendar
    )

    #expect(evaluation.profile.totalPoints >= FinancialLevel.bronze.minimumPoints)
    #expect(evaluation.newlyAchievedFinancialLevel == .bronze)
    #expect(evaluation.profile.lastNotifiedFinancialLevel == .bronze)
    #expect(evaluation.financialLevelProgress.level == .bronze)
}

@Test("calculator does not celebrate when level unchanged on re-eval")
func calculatorDoesNotCelebrateWhenLevelUnchanged() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try makeDate(year: 2026, month: 4, day: 5, calendar: calendar)
    let profile = GamificationProfile(
        currentStreak: 1,
        longestStreak: 1,
        totalPoints: 300,
        lastNotifiedFinancialLevel: .bronze
    )

    let evaluation = GamificationCalculator.evaluate(
        profile: profile,
        transactions: [],
        budgets: [],
        referenceDate: referenceDate,
        calendar: calendar
    )

    #expect(evaluation.newlyAchievedFinancialLevel == nil)
    #expect(evaluation.profile.lastNotifiedFinancialLevel == .bronze)
}

@Test("calculator surfaces financial level progress alongside achievements")
func calculatorSurfacesFinancialLevelProgress() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try makeDate(year: 2026, month: 4, day: 5, calendar: calendar)
    let evaluation = GamificationCalculator.evaluate(
        profile: GamificationProfile(totalPoints: 600),
        transactions: [],
        budgets: [],
        referenceDate: referenceDate,
        calendar: calendar
    )

    #expect(evaluation.financialLevelProgress.level == .bronze)
    #expect(evaluation.financialLevelProgress.totalPoints == 600)
    #expect(evaluation.financialLevelProgress.pointsNeededForNext == 200)
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
