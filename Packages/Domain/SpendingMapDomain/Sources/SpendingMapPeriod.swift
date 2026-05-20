import Foundation

public enum SpendingMapPeriod: String, CaseIterable, Equatable, Codable, Sendable, Identifiable {
    case last30Days
    case last90Days
    case allTime

    public var id: String { rawValue }

    public var titleKey: String {
        switch self {
        case .last30Days: "spendingMap.period.last30Days"
        case .last90Days: "spendingMap.period.last90Days"
        case .allTime: "spendingMap.period.allTime"
        }
    }

    public func startDate(referenceDate: Date, calendar: Calendar) -> Date? {
        switch self {
        case .last30Days:
            calendar.date(byAdding: .day, value: -30, to: referenceDate)
        case .last90Days:
            calendar.date(byAdding: .day, value: -90, to: referenceDate)
        case .allTime:
            nil
        }
    }
}
