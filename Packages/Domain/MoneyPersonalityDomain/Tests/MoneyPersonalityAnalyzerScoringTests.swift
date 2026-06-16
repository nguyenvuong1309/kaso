import Foundation
import Testing
@testable import MoneyPersonalityDomain

struct MoneyPersonalityAnalyzerScoringTests {
    @Test("classifies planner for low-burst, moderate-diversity, saving spender")
    func classifiesPlanner() throws {
        let calendar = Calendar(identifier: .gregorian)
        let weekday = try makeDate(year: 2026, month: 6, day: 15, calendar: calendar) // Monday
        var transactions: [PersonalityTransactionInput] = []
        for _ in 0 ..< 24 {
            transactions.append(input(50_000, "transport", weekday, calendar))
        }
        for _ in 0 ..< 6 {
            transactions.append(input(50_000, "utilities", weekday, calendar))
        }

        let profile = MoneyPersonalityAnalyzer.analyze(
            transactions: transactions,
            budgetUtilizationRatio: 0.5,
            savingsRate: 0.25
        )
        #expect(profile.isSufficient)
        #expect(profile.type == .planner)
    }

    @Test("classifies impulsive for large weekend bursts and overspending")
    func classifiesImpulsive() throws {
        let calendar = Calendar(identifier: .gregorian)
        let weekday = try makeDate(year: 2026, month: 6, day: 15, calendar: calendar) // Monday
        let weekend = try makeDate(year: 2026, month: 6, day: 20, calendar: calendar) // Saturday
        var transactions: [PersonalityTransactionInput] = []
        for _ in 0 ..< 25 {
            transactions.append(input(50_000, "shopping", weekday, calendar))
        }
        for _ in 0 ..< 5 {
            transactions.append(input(1_000_000, "shopping", weekend, calendar))
        }

        let profile = MoneyPersonalityAnalyzer.analyze(
            transactions: transactions,
            budgetUtilizationRatio: 1.4,
            savingsRate: 0.0
        )
        #expect(profile.isSufficient)
        #expect(profile.type == .impulsive)
    }

    @Test("classifies minimalist for high savings, single category and low frequency")
    func classifiesMinimalist() throws {
        let calendar = Calendar(identifier: .gregorian)
        let weekday = try makeDate(year: 2026, month: 6, day: 15, calendar: calendar) // Monday
        let transactions = (0 ..< 30).map { _ in
            input(50_000, "transport", weekday, calendar)
        }

        let profile = MoneyPersonalityAnalyzer.analyze(
            transactions: transactions,
            budgetUtilizationRatio: 0.5,
            savingsRate: 0.5
        )
        #expect(profile.isSufficient)
        #expect(profile.type == .minimalist)
    }

    @Test("exactly the minimum transaction count is sufficient")
    func minimumBoundarySufficient() throws {
        let calendar = Calendar(identifier: .gregorian)
        let weekday = try makeDate(year: 2026, month: 6, day: 15, calendar: calendar)
        let transactions = (0 ..< MoneyPersonalityAnalyzer.minimumTransactionCount).map { _ in
            input(50_000, "food", weekday, calendar)
        }
        let profile = MoneyPersonalityAnalyzer.analyze(transactions: transactions)
        #expect(profile.isSufficient)
        #expect(profile.analyzedTransactionCount == MoneyPersonalityAnalyzer.minimumTransactionCount)
    }

    @Test("one below the minimum returns the insufficient placeholder")
    func belowMinimumInsufficient() throws {
        let calendar = Calendar(identifier: .gregorian)
        let weekday = try makeDate(year: 2026, month: 6, day: 15, calendar: calendar)
        let transactions = (0 ..< MoneyPersonalityAnalyzer.minimumTransactionCount - 1).map { _ in
            input(50_000, "food", weekday, calendar)
        }
        let profile = MoneyPersonalityAnalyzer.analyze(transactions: transactions)
        #expect(profile == MoneyPersonalityProfile.insufficientPlaceholder)
    }

    @Test("empty transactions return the insufficient placeholder")
    func emptyTransactions() {
        let profile = MoneyPersonalityAnalyzer.analyze(transactions: [])
        #expect(profile.isSufficient == false)
        #expect(profile == MoneyPersonalityProfile.insufficientPlaceholder)
    }

    @Test("only income transactions yield zero expense and insufficient placeholder")
    func onlyIncomeIsInsufficient() throws {
        let calendar = Calendar(identifier: .gregorian)
        let weekday = try makeDate(year: 2026, month: 6, day: 15, calendar: calendar)
        let transactions = (0 ..< 40).map { _ in
            PersonalityTransactionInput(
                amount: 1_000_000,
                categoryID: "salary",
                isExpense: false,
                occurredAt: weekday,
                calendar: calendar
            )
        }
        let profile = MoneyPersonalityAnalyzer.analyze(transactions: transactions)
        #expect(profile == MoneyPersonalityProfile.insufficientPlaceholder)
    }

    @Test("zero amount expenses produce zero total and insufficient placeholder")
    func zeroAmountExpenses() throws {
        let calendar = Calendar(identifier: .gregorian)
        let weekday = try makeDate(year: 2026, month: 6, day: 15, calendar: calendar)
        let transactions = (0 ..< 40).map { _ in
            input(0, "food", weekday, calendar)
        }
        let profile = MoneyPersonalityAnalyzer.analyze(transactions: transactions)
        #expect(profile == MoneyPersonalityProfile.insufficientPlaceholder)
    }

    @Test("analyzedAt is propagated to the profile")
    func analyzedAtPropagated() throws {
        let calendar = Calendar(identifier: .gregorian)
        let weekday = try makeDate(year: 2026, month: 6, day: 15, calendar: calendar)
        let analyzedAt = try makeDate(year: 2026, month: 7, day: 1, calendar: calendar)
        let transactions = (0 ..< 40).map { _ in
            input(50_000, "food", weekday, calendar)
        }
        let profile = MoneyPersonalityAnalyzer.analyze(transactions: transactions, analyzedAt: analyzedAt)
        #expect(profile.analyzedAt == analyzedAt)
    }

    @Test("confidence equals the chosen type's score for an analyzed profile")
    func confidenceMatchesTopScore() throws {
        let calendar = Calendar(identifier: .gregorian)
        let weekday = try makeDate(year: 2026, month: 6, day: 15, calendar: calendar)
        let transactions = (0 ..< 40).map { _ in
            input(50_000, "transport", weekday, calendar)
        }
        let profile = MoneyPersonalityAnalyzer.analyze(
            transactions: transactions,
            budgetUtilizationRatio: 0.5,
            savingsRate: 0.5
        )
        let topScore = profile.typeScores[profile.type]
        #expect(profile.confidence == topScore)
    }

    @Test("trait values mirror the corresponding type scores")
    func traitsMirrorScores() throws {
        let calendar = Calendar(identifier: .gregorian)
        let weekday = try makeDate(year: 2026, month: 6, day: 15, calendar: calendar)
        let transactions = (0 ..< 40).map { i in
            input(50_000, ["food", "shopping", "entertainment", "transport"][i % 4], weekday, calendar)
        }
        let profile = MoneyPersonalityAnalyzer.analyze(
            transactions: transactions,
            budgetUtilizationRatio: 0.8,
            savingsRate: 0.1
        )
        let planning = try #require(profile.traits.first { $0.id == "planning" })
        let impulse = try #require(profile.traits.first { $0.id == "impulse" })
        let food = try #require(profile.traits.first { $0.id == "food" })
        #expect(planning.value == profile.typeScores[.planner])
        #expect(impulse.value == profile.typeScores[.impulsive])
        #expect(food.value == profile.typeScores[.foodie])

        let traitIDs = Set(profile.traits.map(\.id))
        #expect(traitIDs == ["planning", "impulse", "frugality", "food", "experiences", "diversity"])
    }

    @Test("every type score remains within 0 and 1 under extreme inputs")
    func scoresClampedUnderExtremeInputs() throws {
        let calendar = Calendar(identifier: .gregorian)
        let weekend = try makeDate(year: 2026, month: 6, day: 20, calendar: calendar)
        let transactions = (0 ..< 40).map { i in
            input(Decimal(i == 0 ? 100_000_000 : 1_000), "shopping", weekend, calendar)
        }
        let profile = MoneyPersonalityAnalyzer.analyze(
            transactions: transactions,
            budgetUtilizationRatio: 5.0,
            savingsRate: 2.0
        )
        for score in profile.typeScores.values {
            #expect(score >= 0)
            #expect(score <= 1)
        }
    }
}

private func input(
    _ amount: Decimal,
    _ categoryID: String,
    _ occurredAt: Date,
    _ calendar: Calendar
) -> PersonalityTransactionInput {
    PersonalityTransactionInput(
        amount: amount,
        categoryID: categoryID,
        isExpense: true,
        occurredAt: occurredAt,
        calendar: calendar
    )
}

private func makeDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 12,
    calendar: Calendar
) throws -> Date {
    try #require(
        DateComponents(
            calendar: calendar,
            year: year,
            month: month,
            day: day,
            hour: hour
        ).date
    )
}
