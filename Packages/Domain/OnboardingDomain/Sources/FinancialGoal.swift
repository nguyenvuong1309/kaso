import Foundation

public enum FinancialGoal: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case buildEmergencyFund
    case reduceOverspending
    case saveForPurchase
    case trackCashflow

    public var id: String {
        rawValue
    }

    public var nameKey: String {
        "onboarding.goal.\(rawValue).name"
    }

    public var descriptionKey: String {
        "onboarding.goal.\(rawValue).description"
    }

    public var symbolName: String {
        switch self {
        case .buildEmergencyFund:
            "shield.lefthalf.filled"
        case .reduceOverspending:
            "chart.line.downtrend.xyaxis"
        case .saveForPurchase:
            "sparkles"
        case .trackCashflow:
            "chart.pie"
        }
    }

    public var savingsRatePercent: Decimal {
        switch self {
        case .buildEmergencyFund, .saveForPurchase:
            30
        case .reduceOverspending:
            25
        case .trackCashflow:
            20
        }
    }
}
