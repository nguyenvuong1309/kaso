import Foundation

public enum DebtType: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case mortgage
    case autoLoan
    case personalLoan
    case creditCard
    case studentLoan
    case bnpl
    case other

    public var id: String {
        rawValue
    }

    public var nameKey: String {
        "debt.type.\(rawValue)"
    }

    public var symbolName: String {
        switch self {
        case .mortgage:
            "house.lodge"
        case .autoLoan:
            "car.fill"
        case .personalLoan:
            "person.crop.circle.badge.minus"
        case .creditCard:
            "creditcard"
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
        case .mortgage:
            "brown"
        case .autoLoan:
            "indigo"
        case .personalLoan:
            "orange"
        case .creditCard:
            "red"
        case .studentLoan:
            "purple"
        case .bnpl:
            "pink"
        case .other:
            "gray"
        }
    }
}
