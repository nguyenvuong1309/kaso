import Foundation
import TransactionDomain

public struct AchievementEvaluation: Equatable, Sendable {
    public let progresses: [AchievementProgress]
    public let newlyUnlocked: [AchievementKind]

    public init(
        progresses: [AchievementProgress],
        newlyUnlocked: [AchievementKind]
    ) {
        self.progresses = progresses
        self.newlyUnlocked = newlyUnlocked
    }
}

public enum AchievementCalculator {
    private static let noSpendLookbackDays = 30
    private static let categoryLookbackDays = 90
    private static let earlyBirdHourEnd = 7
    private static let nightOwlHourStart = 22

    public static func evaluate(
        profile: GamificationProfile,
        transactions: [Transaction],
        referenceDate: Date,
        calendar: Calendar = .current
    ) -> AchievementEvaluation {
        let progresses = AchievementKind.allCases.map { kind in
            progress(
                for: kind,
                profile: profile,
                transactions: transactions,
                referenceDate: referenceDate,
                calendar: calendar
            )
        }

        let newlyUnlocked = progresses
            .filter { progress in
                !profile.unlockedAchievements.contains(progress.kind)
                    && progress.currentValue >= progress.targetValue
            }
            .map(\.kind)

        return AchievementEvaluation(
            progresses: progresses,
            newlyUnlocked: newlyUnlocked
        )
    }
}

private extension AchievementCalculator {
    static func progress(
        for kind: AchievementKind,
        profile: GamificationProfile,
        transactions: [Transaction],
        referenceDate: Date,
        calendar: Calendar
    ) -> AchievementProgress {
        let raw = rawValue(
            for: kind,
            profile: profile,
            transactions: transactions,
            referenceDate: referenceDate,
            calendar: calendar
        )
        let alreadyUnlocked = profile.unlockedAchievements.contains(kind)
        let isUnlocked = alreadyUnlocked || raw >= kind.targetValue
        return AchievementProgress(
            kind: kind,
            currentValue: raw,
            isUnlocked: isUnlocked
        )
    }

    static func rawValue(
        for kind: AchievementKind,
        profile: GamificationProfile,
        transactions: [Transaction],
        referenceDate: Date,
        calendar: Calendar
    ) -> Int {
        switch kind {
        case .firstSteps:
            min(transactions.count, kind.targetValue)
        case .weekWarrior, .monthlyMaster, .centuryClub:
            max(profile.currentStreak, profile.longestStreak)
        case .noSpendNovice, .noSpendChampion:
            countNoSpendDays(
                transactions: transactions,
                referenceDate: referenceDate,
                calendar: calendar
            )
        case .budgetGuardian:
            budgetRespectedCount(profile: profile)
        case .categoryCollector:
            countDistinctCategories(
                transactions: transactions,
                referenceDate: referenceDate,
                calendar: calendar
            )
        case .dualLogger:
            hasIncomeAndExpenseSameDay(
                transactions: transactions,
                calendar: calendar
            ) ? 1 : 0
        case .earlyBird:
            hasTransactionInHourRange(
                upTo: earlyBirdHourEnd,
                transactions: transactions,
                calendar: calendar
            ) ? 1 : 0
        case .nightOwl:
            hasTransactionInHourRange(
                from: nightOwlHourStart,
                transactions: transactions,
                calendar: calendar
            ) ? 1 : 0
        case .rewardCollector, .eliteCollector:
            profile.totalPoints
        }
    }

    static func countNoSpendDays(
        transactions: [Transaction],
        referenceDate: Date,
        calendar: Calendar
    ) -> Int {
        let referenceDay = calendar.startOfDay(for: referenceDate)
        var count = 0
        for offset in 0..<noSpendLookbackDays {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: referenceDay) else {
                continue
            }
            let dayTransactions = transactions.filter {
                calendar.isDate($0.occurredAt, inSameDayAs: day)
            }
            guard !dayTransactions.isEmpty else {
                continue
            }
            let hasExpense = dayTransactions.contains { $0.kind == .expense }
            if !hasExpense {
                count += 1
            }
        }
        return count
    }

    static func budgetRespectedCount(profile: GamificationProfile) -> Int {
        profile.rewardEvents.filter { $0.kind == .budgetRespected }.count
    }

    static func countDistinctCategories(
        transactions: [Transaction],
        referenceDate: Date,
        calendar: Calendar
    ) -> Int {
        let cutoff = calendar.date(
            byAdding: .day,
            value: -categoryLookbackDays,
            to: referenceDate
        ) ?? referenceDate
        let recent = transactions.filter { $0.occurredAt >= cutoff }
        return Set(recent.map(\.category.id)).count
    }

    static func hasIncomeAndExpenseSameDay(
        transactions: [Transaction],
        calendar: Calendar
    ) -> Bool {
        let grouped = Dictionary(grouping: transactions) {
            calendar.startOfDay(for: $0.occurredAt)
        }
        return grouped.values.contains { dayTransactions in
            let kinds = Set(dayTransactions.map(\.kind))
            return kinds.contains(.income) && kinds.contains(.expense)
        }
    }

    static func hasTransactionInHourRange(
        upTo endHourExclusive: Int,
        transactions: [Transaction],
        calendar: Calendar
    ) -> Bool {
        transactions.contains { transaction in
            let hour = calendar.component(.hour, from: transaction.occurredAt)
            return hour < endHourExclusive
        }
    }

    static func hasTransactionInHourRange(
        from startHourInclusive: Int,
        transactions: [Transaction],
        calendar: Calendar
    ) -> Bool {
        transactions.contains { transaction in
            let hour = calendar.component(.hour, from: transaction.occurredAt)
            return hour >= startHourInclusive
        }
    }
}
