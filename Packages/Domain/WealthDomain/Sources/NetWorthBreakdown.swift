import Foundation

public struct NetWorthBreakdownItem: Identifiable, Equatable, Sendable {
    public let id: String
    public var label: String
    public var amount: Decimal
    public var fraction: Double
    public var colorName: String
    public var symbolName: String

    public init(
        id: String,
        label: String,
        amount: Decimal,
        fraction: Double,
        colorName: String,
        symbolName: String
    ) {
        self.id = id
        self.label = label
        self.amount = amount
        self.fraction = fraction
        self.colorName = colorName
        self.symbolName = symbolName
    }
}

public struct NetWorthBreakdown: Equatable, Sendable {
    public var assetItems: [NetWorthBreakdownItem]
    public var liabilityItems: [NetWorthBreakdownItem]

    public init(
        assetItems: [NetWorthBreakdownItem],
        liabilityItems: [NetWorthBreakdownItem]
    ) {
        self.assetItems = assetItems
        self.liabilityItems = liabilityItems
    }

    public static let empty = NetWorthBreakdown(assetItems: [], liabilityItems: [])
}

public enum NetWorthBreakdownBuilder {
    public static func make(
        assets: [Asset],
        liabilities: [Liability]
    ) -> NetWorthBreakdown {
        let assetItems = breakdownItems(
            grouping: assets,
            keyPath: \Asset.type,
            value: { max($0.currentValue, 0) },
            colorName: { $0.colorName },
            symbolName: { $0.symbolName },
            labelKey: { $0.nameKey }
        )

        let liabilityItems = breakdownItems(
            grouping: liabilities,
            keyPath: \Liability.type,
            value: { max($0.principalRemaining, 0) },
            colorName: { $0.colorName },
            symbolName: { $0.symbolName },
            labelKey: { $0.nameKey }
        )

        return NetWorthBreakdown(
            assetItems: assetItems,
            liabilityItems: liabilityItems
        )
    }

    private static func breakdownItems<Item, Key: Hashable>(
        grouping items: [Item],
        keyPath: KeyPath<Item, Key>,
        value: (Item) -> Decimal,
        colorName: (Key) -> String,
        symbolName: (Key) -> String,
        labelKey: (Key) -> String
    ) -> [NetWorthBreakdownItem] {
        let totals = items.reduce(into: [Key: Decimal]()) { partial, item in
            partial[item[keyPath: keyPath], default: 0] += value(item)
        }
        let totalAmount = totals.values.reduce(Decimal(0), +)
        let totalDouble = NSDecimalNumber(decimal: totalAmount).doubleValue

        return totals
            .map { key, amount -> NetWorthBreakdownItem in
                let fraction: Double
                if totalDouble > 0 {
                    fraction = NSDecimalNumber(decimal: amount).doubleValue / totalDouble
                } else {
                    fraction = 0
                }
                return NetWorthBreakdownItem(
                    id: "\(type(of: key)).\(key)",
                    label: labelKey(key),
                    amount: amount,
                    fraction: fraction,
                    colorName: colorName(key),
                    symbolName: symbolName(key)
                )
            }
            .sorted { $0.amount > $1.amount }
    }
}
