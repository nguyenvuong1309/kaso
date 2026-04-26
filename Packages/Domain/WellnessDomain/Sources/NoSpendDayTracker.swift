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

    public init(
        days: [NoSpendDay],
        currentStreak: Int,
        longestStreak: Int,
        noSpendDaysInMonth: Int
    ) {
        self.days = days
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.noSpendDaysInMonth = noSpendDaysInMonth
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

        return NoSpendSummary(
            days: days,
            currentStreak: currentStreak(in: days),
            longestStreak: longestStreak(in: days),
            noSpendDaysInMonth: noSpendDaysInMonth
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
}
