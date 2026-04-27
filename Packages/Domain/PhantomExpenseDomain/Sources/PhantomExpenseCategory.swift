import Foundation

public enum PhantomExpenseCategory: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case cart
    case trip
    case subscription
    case shopping
    case foodDrink
    case entertainment
    case other

    public var id: String {
        rawValue
    }

    public var nameKey: String {
        "phantom.category.\(rawValue)"
    }

    public var symbolName: String {
        switch self {
        case .cart:
            "cart.badge.minus"
        case .trip:
            "airplane.departure"
        case .subscription:
            "repeat.circle"
        case .shopping:
            "bag"
        case .foodDrink:
            "cup.and.saucer"
        case .entertainment:
            "gamecontroller"
        case .other:
            "sparkles"
        }
    }

    public var colorName: String {
        switch self {
        case .cart:
            "blue"
        case .trip:
            "mint"
        case .subscription:
            "purple"
        case .shopping:
            "pink"
        case .foodDrink:
            "orange"
        case .entertainment:
            "indigo"
        case .other:
            "green"
        }
    }
}
