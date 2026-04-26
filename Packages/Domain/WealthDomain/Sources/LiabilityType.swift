import Foundation

public enum LiabilityType: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case creditCard
    case personalLoan
    case mortgage
    case autoLoan
    case studentLoan
    case bnpl
    case other

    public var id: String {
        rawValue
    }

    public var nameKey: String {
        "wealth.liability.type.\(rawValue)"
    }

    public var symbolName: String {
        switch self {
        case .creditCard:
            "creditcard"
        case .personalLoan:
            "person.crop.circle.badge.minus"
        case .mortgage:
            "house.lodge"
        case .autoLoan:
            "car.fill"
        case .studentLoan:
            "graduationcap"
        case .bnpl:
            "cart.badge.minus"
        case .other:
            "doc.text"
        }
    }

    public var colorName: String {
        switch self {
        case .creditCard:
            "red"
        case .personalLoan:
            "orange"
        case .mortgage:
            "brown"
        case .autoLoan:
            "indigo"
        case .studentLoan:
            "purple"
        case .bnpl:
            "pink"
        case .other:
            "gray"
        }
    }
}
