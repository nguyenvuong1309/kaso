import Foundation

public struct BudgetFlowNode: Identifiable, Equatable, Sendable {
    public let id: String
    public var labelKey: String
    public var amount: Decimal
    public var ratio: Double
    public var colorName: String
    public var symbolName: String

    public init(
        id: String,
        labelKey: String,
        amount: Decimal,
        ratio: Double,
        colorName: String,
        symbolName: String
    ) {
        self.id = id
        self.labelKey = labelKey
        self.amount = amount
        self.ratio = ratio
        self.colorName = colorName
        self.symbolName = symbolName
    }
}

public struct BudgetFlow: Equatable, Sendable {
    public var total: Decimal
    public var nodes: [BudgetFlowNode]
    public var currencyCode: String

    public init(
        total: Decimal = 0,
        nodes: [BudgetFlowNode] = [],
        currencyCode: String = "VND"
    ) {
        self.total = total
        self.nodes = nodes
        self.currencyCode = currencyCode
    }

    public static let empty = BudgetFlow()

    public var allocatedTotal: Decimal {
        nodes.reduce(Decimal(0)) { $0 + $1.amount }
    }

    public var unallocated: Decimal {
        max(total - allocatedTotal, 0)
    }
}
