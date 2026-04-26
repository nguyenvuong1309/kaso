import Foundation

public enum AssetType: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case cash
    case bankSavings
    case termDeposit
    case investment
    case realEstate
    case vehicle
    case other

    public var id: String {
        rawValue
    }

    public var nameKey: String {
        "wealth.asset.type.\(rawValue)"
    }

    public var symbolName: String {
        switch self {
        case .cash:
            "banknote"
        case .bankSavings:
            "building.columns"
        case .termDeposit:
            "lock.shield"
        case .investment:
            "chart.line.uptrend.xyaxis"
        case .realEstate:
            "house"
        case .vehicle:
            "car"
        case .other:
            "shippingbox"
        }
    }

    public var colorName: String {
        switch self {
        case .cash:
            "green"
        case .bankSavings:
            "blue"
        case .termDeposit:
            "indigo"
        case .investment:
            "purple"
        case .realEstate:
            "brown"
        case .vehicle:
            "orange"
        case .other:
            "gray"
        }
    }
}
