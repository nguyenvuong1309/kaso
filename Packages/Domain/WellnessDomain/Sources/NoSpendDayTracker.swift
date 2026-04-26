import Foundation
import TransactionDomain

public struct NoSpendDay: Identifiable, Equatable, Sendable {
    public let date: Date
    public let hasExpense: Bool

    public var id: Date {
        date
    }

    public var isNoSpendDay: Bool {
        !hasExpense
    }

    public init(date: Date, hasExpense: Bool) {
        self.date = date
        self.hasExpense = hasExpense
    }
}

public struct NoSpendSummary: Equatable, Sendable {
    public let days: [NoSpendDay]
    public let currentStreak: Int
    public let longestStreak: Int
    public let noSpendDaysInMonth: Int
    public let estimatedSavings: Decimal
    public let achievedMilestone: NoSpendMilestone?
    public let nextMilestone: NoSpendMilestone?

    public init(
        days: [NoSpendDay],
        currentStreak: Int,
        longestStreak: Int,
        noSpendDaysInMonth: Int,
        estimatedSavings: Decimal = 0,
        achievedMilestone: NoSpendMilestone? = nil,
        nextMilestone: NoSpendMilestone? = nil
    ) {
        self.days = days
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.noSpendDaysInMonth = noSpendDaysInMonth
        self.estimatedSavings = estimatedSavings
        self.achievedMilestone = achievedMilestone
        self.nextMilestone = nextMilestone
    }
}

public enum NoSpendMilestone: Int, CaseIterable, Equatable, Identifiable, Sendable {
    case threeDays = 3
    case sevenDays = 7
    case fourteenDays = 14
    case twentyOneDays = 21
    case thirtyDays = 30

    public var id: Int {
        rawValue
    }

    public var dayCount: Int {
        rawValue
    }
}

public enum NoSpendDayTracker {
    public static func monthSummary(
        from transactions: [Transaction],
        containing date: Date,
        calendar: Calendar = .current
    ) -> NoSpendSummary {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else {
            return NoSpendSummary(
                days: [],
                currentStreak: 0,
                longestStreak: 0,
                noSpendDaysInMonth: 0
            )
        }

        return summary(
            from: transactions,
            in: monthInterval,
            asOf: date,
            calendar: calendar
        )
    }

    public static func summary(
        from transactions: [Transaction],
        in interval: DateInterval,
        asOf referenceDate: Date,
        calendar: Calendar = .current
    ) -> NoSpendSummary {
        let days = makeDays(
            from: transactions,
            in: interval,
            asOf: referenceDate,
            calendar: calendar
        )
        let noSpendDaysInMonth = countNoSpendDaysInMonth(
            days,
            containing: referenceDate,
            calendar: calendar
        )
        let currentStreak = currentStreak(in: days)

        return NoSpendSummary(
            days: days,
            currentStreak: currentStreak,
            longestStreak: longestStreak(in: days),
            noSpendDaysInMonth: noSpendDaysInMonth,
            estimatedSavings: estimatedSavings(
                transactions: transactions,
                days: days,
                calendar: calendar
            ),
            achievedMilestone: achievedMilestone(for: currentStreak),
            nextMilestone: nextMilestone(after: currentStreak)
        )
    }
}

private extension NoSpendDayTracker {
    static func makeDays(
        from transactions: [Transaction],
        in interval: DateInterval,
        asOf referenceDate: Date,
        calendar: Calendar
    ) -> [NoSpendDay] {
        guard interval.start < interval.end else {
            return []
        }

        let referenceDayStart = calendar.startOfDay(for: referenceDate)
        let firstDayStart = calendar.startOfDay(for: interval.start)
        guard firstDayStart <= referenceDayStart else {
            return []
        }

        let expenseDays = Set(
            transactions
                .filter { $0.kind == .expense }
                .map { calendar.startOfDay(for: $0.occurredAt) }
        )

        var days: [NoSpendDay] = []
        var dayStart = firstDayStart
        while dayStart < interval.end && dayStart <= referenceDayStart {
            days.append(
                NoSpendDay(
                    date: dayStart,
                    hasExpense: expenseDays.contains(dayStart)
                )
            )

            guard let nextDayStart = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                break
            }
            dayStart = calendar.startOfDay(for: nextDayStart)
        }

        return days
    }

    static func countNoSpendDaysInMonth(
        _ days: [NoSpendDay],
        containing date: Date,
        calendar: Calendar
    ) -> Int {
        days.filter {
            $0.isNoSpendDay
                && calendar.isDate($0.date, equalTo: date, toGranularity: .month)
        }
        .count
    }

    static func currentStreak(in days: [NoSpendDay]) -> Int {
        var streak = 0
        for day in days.reversed() {
            guard day.isNoSpendDay else {
                break
            }
            streak += 1
        }
        return streak
    }

    static func longestStreak(in days: [NoSpendDay]) -> Int {
        var current = 0
        var longest = 0

        for day in days {
            if day.isNoSpendDay {
                current += 1
                longest = max(longest, current)
            } else {
                current = 0
            }
        }

        return longest
    }

    static func estimatedSavings(
        transactions: [Transaction],
        days: [NoSpendDay],
        calendar: Calendar
    ) -> Decimal {
        let noSpendDayCount = days.filter(\.isNoSpendDay).count
        guard noSpendDayCount > 0 else {
            return 0
        }

        let spendingDays = days.filter { $0.isNoSpendDay == false }
        guard spendingDays.isEmpty == false else {
            return 0
        }

        let spendingDayStarts = Set(spendingDays.map(\.date))
        let totalExpenseOnSpendingDays = transactions
            .filter {
                $0.kind == .expense
                    && spendingDayStarts.contains(calendar.startOfDay(for: $0.occurredAt))
            }
            .reduce(Decimal(0)) { $0 + $1.amount }

        guard totalExpenseOnSpendingDays > 0 else {
            return 0
        }

        return totalExpenseOnSpendingDays
            / Decimal(spendingDays.count)
            * Decimal(noSpendDayCount)
    }

    static func achievedMilestone(for currentStreak: Int) -> NoSpendMilestone? {
        NoSpendMilestone.allCases.last { $0.dayCount <= currentStreak }
    }

    static func nextMilestone(after currentStreak: Int) -> NoSpendMilestone? {
        NoSpendMilestone.allCases.first { $0.dayCount > currentStreak }
    }
}
