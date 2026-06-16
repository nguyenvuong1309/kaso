import Foundation
import Testing

/// Deterministic gregorian calendar pinned to UTC for date construction.
func makeCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
}

/// Builds a fixed `Date` from components. Never uses `Date()` so tests stay deterministic.
func makeDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 0,
    minute: Int = 0,
    calendar: Calendar = makeCalendar()
) throws -> Date {
    try #require(
        DateComponents(
            calendar: calendar,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        ).date
    )
}

/// Exact `Decimal` comparison helper to avoid scale/format mismatches.
func decimalsEqual(_ lhs: Decimal, _ rhs: Decimal) -> Bool {
    NSDecimalNumber(decimal: lhs).compare(NSDecimalNumber(decimal: rhs)) == .orderedSame
}
