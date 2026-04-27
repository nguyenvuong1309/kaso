import Foundation

public struct YearMonth: Codable, Comparable, Equatable, Hashable, Identifiable, Sendable {
    public let year: Int
    public let month: Int

    public var id: String {
        "\(year)-\(String(format: "%02d", month))"
    }

    public init(year: Int, month: Int) {
        self.year = year
        self.month = min(max(month, 1), 12)
    }

    public init(date: Date, calendar: Calendar = .current) {
        let components = calendar.dateComponents([.year, .month], from: date)
        year = components.year ?? 1970
        month = components.month ?? 1
    }

    public func date(calendar: Calendar = .current) -> Date? {
        DateComponents(calendar: calendar, year: year, month: month, day: 1).date
    }

    public static func < (lhs: YearMonth, rhs: YearMonth) -> Bool {
        if lhs.year == rhs.year {
            return lhs.month < rhs.month
        } else {
            return lhs.year < rhs.year
        }
    }
}
