import Foundation

public enum GuiltFreeFixedCostKind: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case housing
    case utilities
    case insurance
    case loanRepayment
    case savings
    case emergencyFund
    case other

    public var id: String {
        rawValue
    }

    public var nameKey: String {
        "guiltFree.fixedCost.kind.\(rawValue)"
    }

    public var symbolName: String {
        switch self {
        case .housing:
            "house.fill"
        case .utilities:
            "bolt.fill"
        case .insurance:
            "cross.case.fill"
        case .loanRepayment:
            "banknote.fill"
        case .savings:
            "leaf.fill"
        case .emergencyFund:
            "shield.lefthalf.filled"
        case .other:
            "ellipsis.circle.fill"
        }
    }
}

public struct GuiltFreeFixedCost: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var amount: Decimal
    public var kind: GuiltFreeFixedCostKind

    public init(
        id: UUID = UUID(),
        name: String,
        amount: Decimal,
        kind: GuiltFreeFixedCostKind = .other
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.kind = kind
    }
}
