import Foundation

public enum AssetClass: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case stock
    case etf
    case bond
    case mutualFund
    case crypto
    case gold
    case cashEquivalent
    case other

    public var id: String {
        rawValue
    }

    public var nameKey: String {
        "investment.assetClass.\(rawValue)"
    }

    public var symbolName: String {
        switch self {
        case .stock:
            "chart.line.uptrend.xyaxis"
        case .etf:
            "chart.bar"
        case .bond:
            "doc.text"
        case .mutualFund:
            "rectangle.stack"
        case .crypto:
            "bitcoinsign.circle"
        case .gold:
            "circle.hexagongrid"
        case .cashEquivalent:
            "banknote"
        case .other:
            "questionmark.circle"
        }
    }

    public var colorName: String {
        switch self {
        case .stock:
            "blue"
        case .etf:
            "indigo"
        case .bond:
            "purple"
        case .mutualFund:
            "mint"
        case .crypto:
            "orange"
        case .gold:
            "brown"
        case .cashEquivalent:
            "green"
        case .other:
            "gray"
        }
    }
}
