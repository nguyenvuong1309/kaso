import Foundation

public enum BudgetFlowCalculator {
    public static func makeFlow(
        total: Decimal,
        items: [(id: String, labelKey: String, amount: Decimal, colorName: String, symbolName: String)],
        currencyCode: String = "VND"
    ) -> BudgetFlow {
        let sanitizedTotal = max(total, 0)
        let positives = items.filter { $0.amount > 0 }
        let denominator = sanitizedTotal > 0
            ? sanitizedTotal
            : positives.reduce(Decimal(0)) { $0 + $1.amount }

        let nodes: [BudgetFlowNode] = positives
            .sorted { $0.amount > $1.amount }
            .map { item in
                let ratio: Double = {
                    guard denominator > 0 else {
                        return 0
                    }
                    return doubleValue(item.amount) / doubleValue(denominator)
                }()
                return BudgetFlowNode(
                    id: item.id,
                    labelKey: item.labelKey,
                    amount: item.amount,
                    ratio: ratio,
                    colorName: item.colorName,
                    symbolName: item.symbolName
                )
            }

        return BudgetFlow(
            total: max(sanitizedTotal, denominator),
            nodes: nodes,
            currencyCode: currencyCode
        )
    }

    private static func doubleValue(_ decimal: Decimal) -> Double {
        NSDecimalNumber(decimal: decimal).doubleValue
    }
}
