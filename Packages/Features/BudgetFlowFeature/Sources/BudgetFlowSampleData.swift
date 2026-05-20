import BudgetFlowDomain
import Foundation

public enum BudgetFlowSampleData {
    public static let householdMonth: BudgetFlow = BudgetFlowCalculator.makeFlow(
        total: 4_000,
        items: [
            (id: "housing", labelKey: "budgetFlow.category.housing", amount: 1_110, colorName: "mint", symbolName: "house.fill"),
            (id: "savings", labelKey: "budgetFlow.category.savings", amount: 1_100, colorName: "orange", symbolName: "leaf.fill"),
            (id: "transport", labelKey: "budgetFlow.category.transport", amount: 475, colorName: "blue", symbolName: "bus.fill"),
            (id: "personalCare", labelKey: "budgetFlow.category.personalCare", amount: 250, colorName: "pink", symbolName: "heart.fill"),
            (id: "food", labelKey: "budgetFlow.category.food", amount: 127, colorName: "purple", symbolName: "fork.knife"),
            (id: "lifestyle", labelKey: "budgetFlow.category.lifestyle", amount: 12.5, colorName: "indigo", symbolName: "sparkles"),
        ],
        currencyCode: "EUR"
    )
}
