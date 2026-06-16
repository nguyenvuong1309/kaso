import Foundation
import Testing
import TransactionDomain
@testable import InsightDomain

@Test("intent exposes localization keys per raw value")
func intentExposesLocalizationKeys() {
    #expect(FinancialAssistantIntent.monthStatus.titleKey == "assistant.intent.monthStatus.title")
    #expect(FinancialAssistantIntent.monthStatus.summaryKey == "assistant.answer.monthStatus.summary")
    #expect(FinancialAssistantIntent.affordability.titleKey == "assistant.intent.affordability.title")
    #expect(FinancialAssistantIntent.unknown.summaryKey == "assistant.answer.unknown.summary")
}

@Test("risk and fact-kind expose localization keys")
func riskAndFactKindKeys() {
    #expect(FinancialAssistantRisk.critical.titleKey == "assistant.risk.critical")
    #expect(FinancialAssistantRisk.positive.titleKey == "assistant.risk.positive")
    #expect(FinancialAssistantFactKind.projectedBalance.titleKey == "assistant.fact.projectedBalance")
    #expect(FinancialAssistantFactKind.suggestedSaving.titleKey == "assistant.fact.suggestedSaving")
}

@Test("fact identifier omits category when none is supplied")
func factIdentifierWithoutCategory() {
    let fact = FinancialAssistantFact(kind: .balance, amount: 1_000_000)
    #expect(fact.id == "balance")
    #expect(fact.category == nil)
}

@Test("fact identifier combines kind and category id")
func factIdentifierWithCategory() {
    let fact = FinancialAssistantFact(kind: .topCategoryExpense, amount: 500_000, category: .food)
    #expect(fact.id == "topCategoryExpense-food")
    #expect(fact.category == .food)
}

@Test("answer amount lookup returns the first matching fact and nil otherwise")
func answerAmountLookup() {
    let answer = FinancialAssistantAnswer(
        intent: .monthStatus,
        risk: .positive,
        confidence: 0.9,
        facts: [
            FinancialAssistantFact(kind: .income, amount: 10_000_000),
            FinancialAssistantFact(kind: .expense, amount: 4_000_000),
            FinancialAssistantFact(kind: .balance, amount: 6_000_000),
        ]
    )
    #expect(answer.amount(for: .income) == 10_000_000)
    #expect(answer.amount(for: .balance) == 6_000_000)
    #expect(answer.amount(for: .projectedBalance) == nil)
}

@Test("answer keeps optional defaults when not specified")
func answerOptionalDefaults() {
    let answer = FinancialAssistantAnswer(
        intent: .topCategory,
        risk: .neutral,
        confidence: 0.75,
        facts: []
    )
    #expect(answer.requestedAmount == nil)
    #expect(answer.recommendedCategory == nil)
}
