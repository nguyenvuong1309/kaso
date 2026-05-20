import Foundation
import Testing
@testable import MoneyPersonalityDomain

struct MoneyPersonalityAnalyzerTests {
    @Test("returns insufficient when transaction count is below threshold")
    func insufficientData() {
        let transactions = (0 ..< 10).map { _ in
            PersonalityTransactionInput(
                amount: 50_000,
                categoryID: "food",
                isExpense: true,
                occurredAt: Date()
            )
        }

        let profile = MoneyPersonalityAnalyzer.analyze(transactions: transactions)
        #expect(profile.isSufficient == false)
    }

    @Test("classifies foodie when food share is dominant")
    func classifiesFoodie() {
        let transactions = (0 ..< 50).map { i in
            PersonalityTransactionInput(
                amount: 50_000,
                categoryID: i % 5 == 0 ? "transport" : "food",
                isExpense: true,
                occurredAt: Date()
            )
        }

        let profile = MoneyPersonalityAnalyzer.analyze(
            transactions: transactions,
            budgetUtilizationRatio: 0.8,
            savingsRate: 0.1
        )

        #expect(profile.isSufficient)
        #expect(profile.type == .foodie)
    }

    @Test("classifies experience seeker when entertainment + travel dominate")
    func classifiesExperienceSeeker() {
        let transactions = (0 ..< 50).map { i in
            PersonalityTransactionInput(
                amount: 200_000,
                categoryID: i % 3 == 0 ? "entertainment" : (i % 3 == 1 ? "travel" : "food"),
                isExpense: true,
                occurredAt: Date()
            )
        }

        let profile = MoneyPersonalityAnalyzer.analyze(
            transactions: transactions,
            budgetUtilizationRatio: 0.7,
            savingsRate: 0.05
        )

        #expect(profile.isSufficient)
        #expect(profile.type == .experienceSeeker)
    }

    @Test("traits array contains 6 entries when sufficient")
    func traitsCount() {
        let transactions = (0 ..< 50).map { _ in
            PersonalityTransactionInput(
                amount: 50_000,
                categoryID: "food",
                isExpense: true,
                occurredAt: Date()
            )
        }

        let profile = MoneyPersonalityAnalyzer.analyze(transactions: transactions)
        #expect(profile.traits.count == 6)
    }

    @Test("all type scores are between 0 and 1")
    func scoresAreNormalized() {
        let transactions = (0 ..< 60).map { i in
            PersonalityTransactionInput(
                amount: Decimal(100_000 + (i % 5) * 50_000),
                categoryID: ["food", "shopping", "entertainment", "transport"][i % 4],
                isExpense: true,
                occurredAt: Date()
            )
        }

        let profile = MoneyPersonalityAnalyzer.analyze(
            transactions: transactions,
            budgetUtilizationRatio: 0.9,
            savingsRate: 0.1
        )

        for (_, score) in profile.typeScores {
            #expect(score >= 0)
            #expect(score <= 1)
        }
    }
}
