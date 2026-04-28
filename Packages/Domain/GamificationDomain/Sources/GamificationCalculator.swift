import BudgetDomain
import Foundation
import TransactionDomain

public struct GamificationEvaluation: Equatable, Sendable {
    public let profile: GamificationProfile
    public let newEvents: [RewardEvent]
    public let achievedMilestone: RewardEventKind?
    public let achievementProgresses: [AchievementProgress]
    public let newlyUnlockedAchievements: [AchievementKind]
    public let financialLevelProgress: FinancialLevelProgress
    public let newlyAchievedFinancialLevel: FinancialLevel?
    public let newlyCompletedWeeklyChallenge: WeeklyChallenge?

    public init(
        profile: GamificationProfile,
        newEvents: [RewardEvent],
        achievedMilestone: RewardEventKind?,
        achievementProgresses: [AchievementProgress] = [],
        newlyUnlockedAchievements: [AchievementKind] = [],
        financialLevelProgress: FinancialLevelProgress = FinancialLevelProgress(totalPoints: 0),
        newlyAchievedFinancialLevel: FinancialLevel? = nil,
        newlyCompletedWeeklyChallenge: WeeklyChallenge? = nil
    ) {
        self.profile = profile
        self.newEvents = newEvents
        self.achievedMilestone = achievedMilestone
        self.achievementProgresses = achievementProgresses
        self.newlyUnlockedAchievements = newlyUnlockedAchievements
        self.financialLevelProgress = financialLevelProgress
        self.newlyAchievedFinancialLevel = newlyAchievedFinancialLevel
        self.newlyCompletedWeeklyChallenge = newlyCompletedWeeklyChallenge
    }
}

public enum GamificationCalculator {
    private static let recentEventsLimit = 30

    public static func evaluate(
        profile: GamificationProfile,
        transactions: [Transaction],
        budgets: [Budget],
        referenceDate: Date,
        calendar: Calendar = .current
    ) -> GamificationEvaluation {
        let referenceDay = calendar.startOfDay(for: referenceDate)
        let lastActivityDay = profile.lastActivityDate.map { calendar.startOfDay(for: $0) }
        let lastEvaluatedDay = profile.lastEvaluatedDate.map { calendar.startOfDay(for: $0) }
        let alreadyEvaluatedToday = lastEvaluatedDay.map {
            calendar.isDate($0, inSameDayAs: referenceDay)
        } ?? false

        var updated = profile
        var newEvents: [RewardEvent] = []

        let hasEntryToday = transactions.contains { transaction in
            calendar.isDate(transaction.occurredAt, inSameDayAs: referenceDay)
        }
        let alreadyCountedToday = lastActivityDay.map {
            calendar.isDate($0, inSameDayAs: referenceDay)
        } ?? false

        updated.currentStreak = nextStreak(
            currentStreak: profile.currentStreak,
            lastActivityDay: lastActivityDay,
            referenceDay: referenceDay,
            hasEntryToday: hasEntryToday,
            calendar: calendar
        )

        if hasEntryToday && !alreadyCountedToday {
            updated.lastActivityDate = referenceDay
            newEvents.append(RewardEvent(kind: .dailyEntry, earnedAt: referenceDate))
        }

        updated.longestStreak = max(updated.longestStreak, updated.currentStreak)

        let achievedMilestone = milestoneIfAchieved(profile: updated)
        if let milestone = achievedMilestone {
            updated.unlockedMilestones.insert(milestone)
            newEvents.append(RewardEvent(kind: milestone, earnedAt: referenceDate))
        }

        if !alreadyEvaluatedToday {
            if isNoSpendDay(
                transactions: transactions,
                day: referenceDay,
                calendar: calendar
            ) && hasEntryToday {
                newEvents.append(
                    RewardEvent(kind: .noSpendDay, earnedAt: referenceDate)
                )
            }

            if budgetsRespected(budgets) && hasEntryToday {
                newEvents.append(
                    RewardEvent(kind: .budgetRespected, earnedAt: referenceDate)
                )
            }
        }

        let earnedPoints = newEvents.reduce(0) { $0 + $1.points }
        updated.totalPoints += earnedPoints

        if hasEntryToday {
            updated.lastEvaluatedDate = referenceDay
        }

        updated.rewardEvents = mergedEvents(
            existing: profile.rewardEvents,
            additions: newEvents
        )

        let weeklyOutcome = evaluateWeeklyChallenge(
            profile: updated,
            transactions: transactions,
            referenceDate: referenceDate,
            calendar: calendar
        )
        updated.activeWeeklyChallenge = weeklyOutcome.activeChallenge
        updated.completedWeeklyChallenges = weeklyOutcome.completedChallenges
        if let challengeReward = weeklyOutcome.rewardEvent {
            newEvents.append(challengeReward)
            updated.totalPoints += challengeReward.points
            updated.rewardEvents = mergedEvents(
                existing: updated.rewardEvents,
                additions: [challengeReward]
            )
        }

        let achievementEvaluation = AchievementCalculator.evaluate(
            profile: updated,
            transactions: transactions,
            referenceDate: referenceDate,
            calendar: calendar
        )
        for kind in achievementEvaluation.newlyUnlocked {
            updated.unlockedAchievements.insert(kind)
        }

        let financialProgress = FinancialLevelProgress(totalPoints: updated.totalPoints)
        let newFinancialLevel = newlyAchievedFinancialLevel(
            previousNotified: profile.lastNotifiedFinancialLevel,
            currentLevel: financialProgress.level
        )
        updated.lastNotifiedFinancialLevel = financialProgress.level

        return GamificationEvaluation(
            profile: updated,
            newEvents: newEvents,
            achievedMilestone: achievedMilestone,
            achievementProgresses: achievementEvaluation.progresses,
            newlyUnlockedAchievements: achievementEvaluation.newlyUnlocked,
            financialLevelProgress: financialProgress,
            newlyAchievedFinancialLevel: newFinancialLevel,
            newlyCompletedWeeklyChallenge: weeklyOutcome.newlyCompletedChallenge
        )
    }
}

private extension GamificationCalculator {
    static func nextStreak(
        currentStreak: Int,
        lastActivityDay: Date?,
        referenceDay: Date,
        hasEntryToday: Bool,
        calendar: Calendar
    ) -> Int {
        guard let lastActivityDay else {
            return hasEntryToday ? 1 : 0
        }

        let components = calendar.dateComponents(
            [.day],
            from: lastActivityDay,
            to: referenceDay
        )
        let dayDelta = components.day ?? 0

        switch (dayDelta, hasEntryToday) {
        case (0, _):
            return currentStreak
        case (1, true):
            return currentStreak + 1
        case (1, false):
            return currentStreak
        case (_, true) where dayDelta > 1:
            return 1
        default:
            return 0
        }
    }

    static func milestoneIfAchieved(profile: GamificationProfile) -> RewardEventKind? {
        let candidates: [(streak: Int, kind: RewardEventKind)] = [
            (3, .streakMilestone3),
            (7, .streakMilestone7),
            (30, .streakMilestone30),
            (100, .streakMilestone100),
        ]

        return candidates
            .filter { profile.currentStreak >= $0.streak }
            .last { !profile.unlockedMilestones.contains($0.kind) }
            .map(\.kind)
    }

    static func isNoSpendDay(
        transactions: [Transaction],
        day: Date,
        calendar: Calendar
    ) -> Bool {
        let hasExpense = transactions.contains { transaction in
            transaction.kind == .expense
                && calendar.isDate(transaction.occurredAt, inSameDayAs: day)
        }
        return !hasExpense
    }

    static func budgetsRespected(_ budgets: [Budget]) -> Bool {
        guard !budgets.isEmpty else {
            return false
        }
        return budgets.allSatisfy { $0.status != .exceeded }
    }

    static func newlyAchievedFinancialLevel(
        previousNotified: FinancialLevel?,
        currentLevel: FinancialLevel
    ) -> FinancialLevel? {
        guard let previousNotified else {
            return nil
        }
        return currentLevel > previousNotified ? currentLevel : nil
    }

    static func mergedEvents(
        existing: [RewardEvent],
        additions: [RewardEvent]
    ) -> [RewardEvent] {
        guard !additions.isEmpty else {
            return existing
        }
        var combined = existing + additions
        combined.sort { $0.earnedAt > $1.earnedAt }
        if combined.count > recentEventsLimit {
            combined = Array(combined.prefix(recentEventsLimit))
        }
        return combined
    }

    struct WeeklyChallengeOutcome: Sendable {
        let activeChallenge: WeeklyChallenge?
        let completedChallenges: [WeeklyChallenge]
        let rewardEvent: RewardEvent?
        let newlyCompletedChallenge: WeeklyChallenge?
    }

    static func evaluateWeeklyChallenge(
        profile: GamificationProfile,
        transactions: [Transaction],
        referenceDate: Date,
        calendar: Calendar
    ) -> WeeklyChallengeOutcome {
        let currentWeekStart = WeeklyChallengeGenerator.startOfWeek(
            for: referenceDate,
            calendar: calendar
        )

        var activeChallenge = profile.activeWeeklyChallenge
        var completedChallenges = profile.completedWeeklyChallenges
        var rewardEvent: RewardEvent?
        var newlyCompleted: WeeklyChallenge?

        if var existing = activeChallenge {
            let wasCompleted = existing.isCompleted
            existing = WeeklyChallengeEvaluator.evaluate(
                challenge: existing,
                transactions: transactions,
                rewardEvents: profile.rewardEvents,
                referenceDate: referenceDate,
                calendar: calendar
            )
            if !wasCompleted, existing.isCompleted {
                rewardEvent = RewardEvent(
                    kind: .weeklyChallengeCompleted,
                    earnedAt: referenceDate,
                    points: existing.kind.rewardPoints
                )
                newlyCompleted = existing
            }
            activeChallenge = existing
        }

        if let existing = activeChallenge,
           !calendar.isDate(existing.weekStart, inSameDayAs: currentWeekStart) {
            completedChallenges.insert(existing, at: 0)
            if completedChallenges.count > GamificationProfile.weeklyChallengeHistoryLimit {
                completedChallenges = Array(
                    completedChallenges.prefix(GamificationProfile.weeklyChallengeHistoryLimit)
                )
            }
            activeChallenge = nil
        }

        if activeChallenge == nil {
            let newChallenge = WeeklyChallengeGenerator.challenge(
                for: currentWeekStart,
                calendar: calendar
            )
            let evaluated = WeeklyChallengeEvaluator.evaluate(
                challenge: newChallenge,
                transactions: transactions,
                rewardEvents: profile.rewardEvents,
                referenceDate: referenceDate,
                calendar: calendar
            )
            activeChallenge = evaluated
        }

        return WeeklyChallengeOutcome(
            activeChallenge: activeChallenge,
            completedChallenges: completedChallenges,
            rewardEvent: rewardEvent,
            newlyCompletedChallenge: newlyCompleted
        )
    }
}
