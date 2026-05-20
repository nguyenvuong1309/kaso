import Foundation

public enum SubscriptionInterval: String, CaseIterable, Codable, Equatable, Sendable {
    case weekly
    case monthly
    case yearly

    public var approximateDays: Int {
        switch self {
        case .weekly: 7
        case .monthly: 30
        case .yearly: 365
        }
    }

    public func monthlyEquivalent(for amount: Decimal) -> Decimal {
        switch self {
        case .weekly:
            amount * Decimal(52) / Decimal(12)
        case .monthly:
            amount
        case .yearly:
            amount / Decimal(12)
        }
    }

    func nextDate(
        after date: Date,
        referenceDate: Date,
        calendar: Calendar
    ) -> Date {
        var nextDate = addingInterval(to: date, calendar: calendar)

        while nextDate <= referenceDate {
            let advancedDate = addingInterval(to: nextDate, calendar: calendar)
            guard advancedDate > nextDate else {
                return nextDate
            }
            nextDate = advancedDate
        }

        return nextDate
    }

    func matchesGap(from startDate: Date, to endDate: Date, calendar: Calendar) -> Bool {
        let dayCount = calendar.dateComponents([.day], from: startDate, to: endDate).day

        guard let dayCount else {
            return false
        }

        switch self {
        case .weekly:
            return (5...9).contains(dayCount)
        case .monthly:
            return (25...35).contains(dayCount)
        case .yearly:
            return (350...380).contains(dayCount)
        }
    }

    private func addingInterval(to date: Date, calendar: Calendar) -> Date {
        let component: Calendar.Component
        let value: Int

        switch self {
        case .weekly:
            component = .weekOfYear
            value = 1
        case .monthly:
            component = .month
            value = 1
        case .yearly:
            component = .year
            value = 1
        }

        return calendar.date(byAdding: component, value: value, to: date) ?? date
    }
}
