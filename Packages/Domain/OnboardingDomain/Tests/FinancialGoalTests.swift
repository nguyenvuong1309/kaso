import Foundation
import Testing
import TransactionDomain
@testable import OnboardingDomain

@Test("exposes all four financial goals via CaseIterable")
func financialGoalAllCases() {
    #expect(
        FinancialGoal.allCases == [
            .buildEmergencyFund,
            .reduceOverspending,
            .saveForPurchase,
            .trackCashflow,
        ]
    )
}

@Test("id mirrors the raw value")
func financialGoalIdMatchesRawValue() {
    for goal in FinancialGoal.allCases {
        #expect(goal.id == goal.rawValue)
    }
}

@Test("name and description localization keys follow the namespace convention")
func financialGoalLocalizationKeys() {
    #expect(FinancialGoal.buildEmergencyFund.nameKey == "onboarding.goal.buildEmergencyFund.name")
    #expect(
        FinancialGoal.buildEmergencyFund.descriptionKey
            == "onboarding.goal.buildEmergencyFund.description"
    )
    #expect(FinancialGoal.reduceOverspending.nameKey == "onboarding.goal.reduceOverspending.name")
    #expect(
        FinancialGoal.reduceOverspending.descriptionKey
            == "onboarding.goal.reduceOverspending.description"
    )
    #expect(FinancialGoal.saveForPurchase.nameKey == "onboarding.goal.saveForPurchase.name")
    #expect(
        FinancialGoal.saveForPurchase.descriptionKey
            == "onboarding.goal.saveForPurchase.description"
    )
    #expect(FinancialGoal.trackCashflow.nameKey == "onboarding.goal.trackCashflow.name")
    #expect(
        FinancialGoal.trackCashflow.descriptionKey
            == "onboarding.goal.trackCashflow.description"
    )
}

@Test("maps each goal to its SF Symbol")
func financialGoalSymbolNames() {
    #expect(FinancialGoal.buildEmergencyFund.symbolName == "shield.lefthalf.filled")
    #expect(FinancialGoal.reduceOverspending.symbolName == "chart.line.downtrend.xyaxis")
    #expect(FinancialGoal.saveForPurchase.symbolName == "sparkles")
    #expect(FinancialGoal.trackCashflow.symbolName == "chart.pie")
}

@Test("savings rate percent differs per goal")
func financialGoalSavingsRatePercent() {
    #expect(FinancialGoal.buildEmergencyFund.savingsRatePercent == Decimal(30))
    #expect(FinancialGoal.saveForPurchase.savingsRatePercent == Decimal(30))
    #expect(FinancialGoal.reduceOverspending.savingsRatePercent == Decimal(25))
    #expect(FinancialGoal.trackCashflow.savingsRatePercent == Decimal(20))
}

@Test("round-trips through Codable preserving the raw value")
func financialGoalCodableRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    for goal in FinancialGoal.allCases {
        let data = try encoder.encode(goal)
        let decoded = try decoder.decode(FinancialGoal.self, from: data)
        #expect(decoded == goal)
    }
}

@Test("decodes from its raw string representation")
func financialGoalDecodesFromRawString() throws {
    let data = Data("\"saveForPurchase\"".utf8)
    let decoded = try JSONDecoder().decode(FinancialGoal.self, from: data)
    #expect(decoded == .saveForPurchase)
}
