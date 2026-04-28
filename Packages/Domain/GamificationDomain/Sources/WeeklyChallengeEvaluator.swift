import Foundation
import TransactionDomain

public enum WeeklyChallengeEvaluator {
    public static func evaluate(
        challenge: WeeklyChallenge,
        transactions: [Transaction],
        rewardEvents: [RewardEvent],
        referenceDate: Date,
        calendar: Calendar = .current
    ) -> WeeklyChallenge {
        let weekStart = challenge.weekStart
        let weekEnd = challenge.weekEnd(calendar: calendar)
        let weekTransactions = transactions.filter { transaction in
            transaction.occurredAt >= weekStart && transaction.occurredAt < weekEnd
        }
        let weekRewardEvents = rewardEvents.filter { event in
            event.earnedAt >= weekStart && event.earnedAt < weekEnd
        }

        var updated = challenge
        updated.currentProgress = computeProgress(
            kind: challenge.kind,
            weekTransactions: weekTransactions,
            weekRewardEvents: weekRewardEvents,
            calendar: calendar
        )
        if updated.completedAt == nil && updated.currentProgress >= updated.target {
            updated.completedAt = referenceDate
        }
        return updated
    }
}

private extension WeeklyChallengeEvaluator {
    static func computeProgress(
        kind: WeeklyChallengeKind,
        weekTransactions: [Transaction],
        weekRewardEvents: [RewardEvent],
        calendar: Calendar
    ) -> Int {
        switch kind {
        case .dailyStreak:
            countDistinctDays(transactions: weekTransactions, calendar: calendar)
        case .noSpendDays:
            countDistinctDays(
                events: weekRewardEvents.filter { $0.kind == .noSpendDay },
                calendar: calendar
            )
        case .budgetKeeper:
            countDistinctDays(
                events: weekRewardEvents.filter { $0.kind == .budgetRespected },
                calendar: calendar
            )
        case .categoryVariety:
            Set(weekTransactions.map(\.category.id)).count
        case .incomeLogger:
            weekTransactions.contains { $0.kind == .income } ? 1 : 0
        }
    }

    static func countDistinctDays(
        transactions: [Transaction],
        calendar: Calendar
    ) -> Int {
        Set(transactions.map { calendar.startOfDay(for: $0.occurredAt) }).count
    }

    static func countDistinctDays(
        events: [RewardEvent],
        calendar: Calendar
    ) -> Int {
        Set(events.map { calendar.startOfDay(for: $0.earnedAt) }).count
    }
}
