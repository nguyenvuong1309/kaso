import Foundation

public enum CompatibilityDimension: String, CaseIterable, Codable, Equatable, Hashable, Identifiable, Sendable {
    case spendingStyle
    case riskTolerance
    case debtAttitude
    case splittingApproach
    case familySupport
    case futureGoals

    public var id: String {
        rawValue
    }

    public var titleKey: String {
        "compatibility.dimension.\(rawValue)"
    }

    public var symbolName: String {
        switch self {
        case .spendingStyle:
            "cart"
        case .riskTolerance:
            "chart.line.uptrend.xyaxis"
        case .debtAttitude:
            "creditcard"
        case .splittingApproach:
            "person.2"
        case .familySupport:
            "heart"
        case .futureGoals:
            "target"
        }
    }

    public var colorName: String {
        switch self {
        case .spendingStyle:
            "mint"
        case .riskTolerance:
            "orange"
        case .debtAttitude:
            "purple"
        case .splittingApproach:
            "blue"
        case .familySupport:
            "pink"
        case .futureGoals:
            "green"
        }
    }
}
