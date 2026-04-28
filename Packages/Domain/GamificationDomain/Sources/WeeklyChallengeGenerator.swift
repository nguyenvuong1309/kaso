import Foundation

public enum WeeklyChallengeGenerator {
    public static func startOfWeek(
        for date: Date,
        calendar: Calendar = .current
    ) -> Date {
        var workCalendar = calendar
        if workCalendar.firstWeekday != 2 {
            workCalendar.firstWeekday = 2
        }
        let interval = workCalendar.dateInterval(of: .weekOfYear, for: date)
        return interval?.start ?? workCalendar.startOfDay(for: date)
    }

    public static func challenge(
        for weekStart: Date,
        calendar: Calendar = .current
    ) -> WeeklyChallenge {
        let kinds = WeeklyChallengeKind.allCases
        guard !kinds.isEmpty else {
            return WeeklyChallenge(kind: .dailyStreak, weekStart: weekStart)
        }
        let weekOfYear = calendar.component(.weekOfYear, from: weekStart)
        let yearForWeek = calendar.component(.yearForWeekOfYear, from: weekStart)
        let bucket = abs((yearForWeek * 53) + weekOfYear)
        let kind = kinds[bucket % kinds.count]
        return WeeklyChallenge(kind: kind, weekStart: weekStart)
    }
}
