import Foundation

public enum CoolingPeriod: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case oneDay
    case threeDays
    case oneWeek
    case twoWeeks

    public var id: String {
        rawValue
    }

    public var nameKey: String {
        "coolingOff.period.\(rawValue)"
    }

    public var seconds: TimeInterval {
        switch self {
        case .oneDay:
            86_400
        case .threeDays:
            3 * 86_400
        case .oneWeek:
            7 * 86_400
        case .twoWeeks:
            14 * 86_400
        }
    }
}
