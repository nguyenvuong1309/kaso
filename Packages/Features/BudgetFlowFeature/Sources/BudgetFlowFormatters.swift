import BudgetFlowDomain
import Foundation

enum BudgetFlowFormatters {
    static func amount(_ value: Decimal, currencyCode: String) -> String {
        value.formatted(.currency(code: currencyCode).precision(.fractionLength(0 ... 2)))
    }

    static func percent(_ ratio: Double) -> String {
        ratio.formatted(.percent.precision(.fractionLength(0 ... 1)))
    }

    static func nodeValue(
        _ node: BudgetFlowNode,
        mode: BudgetFlowDisplayMode,
        currencyCode: String
    ) -> String {
        switch mode {
        case .amount:
            amount(node.amount, currencyCode: currencyCode)
        case .percent:
            percent(node.ratio)
        }
    }
}
