import Foundation
import TransactionDomain

public enum FinancialAssistantEngine {
    public static func answer(
        question: String,
        transactions: [Transaction],
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> FinancialAssistantAnswer {
        let normalizedQuestion = normalize(question)
        let intent = classify(normalizedQuestion)
        let context = FinancialAssistantContext(
            transactions: transactions,
            referenceDate: referenceDate,
            calendar: calendar
        )

        switch intent {
        case .monthStatus:
            return monthStatusAnswer(context: context, intent: .monthStatus)
        case .affordability:
            return affordabilityAnswer(
                requestedAmount: parseAmount(from: normalizedQuestion),
                context: context
            )
        case .savingsCut:
            return savingsCutAnswer(
                targetAmount: parseAmount(from: normalizedQuestion),
                context: context
            )
        case .topCategory:
            return topCategoryAnswer(context: context)
        case .unknown:
            return unknownAnswer(context: context)
        }
    }

    private static func classify(_ question: String) -> FinancialAssistantIntent {
        if containsAny(question, keywords: ["du tien", "co du", "afford", "di du lich"]) {
            return .affordability
        }

        if containsAny(question, keywords: ["cat", "giam", "tiet kiem", "bot"]) {
            return .savingsCut
        }

        if containsAny(question, keywords: ["chi nhieu", "nhieu nhat", "top", "danh muc"]) {
            return .topCategory
        }

        if containsAny(question, keywords: ["thang nay", "con bao nhieu", "so du", "cuoi thang"]) {
            return .monthStatus
        }

        return .unknown
    }

    private static func monthStatusAnswer(
        context: FinancialAssistantContext,
        intent: FinancialAssistantIntent
    ) -> FinancialAssistantAnswer {
        let forecast = MonthlyBalanceForecaster.forecast(
            transactions: context.transactions,
            referenceDate: context.referenceDate,
            calendar: context.calendar
        )
        let summary = context.currentMonthSummary
        let facts = [
            FinancialAssistantFact(kind: .income, amount: summary.income),
            FinancialAssistantFact(kind: .expense, amount: summary.expense),
            FinancialAssistantFact(kind: .balance, amount: summary.balance),
            FinancialAssistantFact(kind: .projectedBalance, amount: forecast.projectedBalance),
        ]

        return FinancialAssistantAnswer(
            intent: intent,
            risk: risk(projectedBalance: forecast.projectedBalance, balance: summary.balance),
            confidence: intent == .unknown ? 0.3 : 0.9,
            facts: facts
        )
    }

    private static func affordabilityAnswer(
        requestedAmount: Decimal?,
        context: FinancialAssistantContext
    ) -> FinancialAssistantAnswer {
        let forecast = MonthlyBalanceForecaster.forecast(
            transactions: context.transactions,
            referenceDate: context.referenceDate,
            calendar: context.calendar
        )
        let summary = context.currentMonthSummary
        var facts = [
            FinancialAssistantFact(kind: .balance, amount: summary.balance),
            FinancialAssistantFact(kind: .projectedBalance, amount: forecast.projectedBalance),
        ]

        guard let requestedAmount else {
            return FinancialAssistantAnswer(
                intent: .affordability,
                risk: .neutral,
                confidence: 0.65,
                facts: facts,
                requestedAmount: nil
            )
        }

        facts.append(
            FinancialAssistantFact(kind: .requestedAmount, amount: requestedAmount)
        )
        let answerRisk: FinancialAssistantRisk
        if forecast.projectedBalance >= requestedAmount {
            answerRisk = .positive
        } else if summary.balance >= requestedAmount {
            answerRisk = .warning
        } else {
            answerRisk = .critical
        }

        return FinancialAssistantAnswer(
            intent: .affordability,
            risk: answerRisk,
            confidence: 0.85,
            facts: facts,
            requestedAmount: requestedAmount
        )
    }

    private static func savingsCutAnswer(
        targetAmount: Decimal?,
        context: FinancialAssistantContext
    ) -> FinancialAssistantAnswer {
        let suggestions = SpendingReductionSuggestionEngine.suggestions(
            transactions: context.transactions,
            referenceDate: context.referenceDate,
            calendar: context.calendar
        )
        let topSuggestion = suggestions.first
        let fallbackSaving = context.topCategory.map {
            roundedToThousands($0.amount * fallbackSavingRatio)
        } ?? 0
        let suggestedSaving = topSuggestion?.suggestedMonthlySaving ?? fallbackSaving
        let recommendedCategory = topSuggestion?.category ?? context.topCategory?.category
        var facts: [FinancialAssistantFact] = [
            FinancialAssistantFact(kind: .suggestedSaving, amount: suggestedSaving),
        ]

        if let targetAmount {
            facts.append(
                FinancialAssistantFact(kind: .requestedAmount, amount: targetAmount)
            )
        }

        if let topCategory = context.topCategory {
            facts.append(
                FinancialAssistantFact(
                    kind: .topCategoryExpense,
                    amount: topCategory.amount,
                    category: topCategory.category
                )
            )
        }

        return FinancialAssistantAnswer(
            intent: .savingsCut,
            risk: savingsRisk(targetAmount: targetAmount, suggestedSaving: suggestedSaving),
            confidence: topSuggestion == nil ? 0.65 : 0.9,
            facts: facts,
            requestedAmount: targetAmount,
            recommendedCategory: recommendedCategory
        )
    }

    private static func topCategoryAnswer(context: FinancialAssistantContext) -> FinancialAssistantAnswer {
        guard let topCategory = context.topCategory else {
            return FinancialAssistantAnswer(
                intent: .topCategory,
                risk: .neutral,
                confidence: 0.75,
                facts: [
                    FinancialAssistantFact(kind: .expense, amount: context.currentMonthSummary.expense),
                ]
            )
        }

        return FinancialAssistantAnswer(
            intent: .topCategory,
            risk: .neutral,
            confidence: 0.9,
            facts: [
                FinancialAssistantFact(
                    kind: .topCategoryExpense,
                    amount: topCategory.amount,
                    category: topCategory.category
                ),
                FinancialAssistantFact(kind: .expense, amount: context.currentMonthSummary.expense),
            ],
            recommendedCategory: topCategory.category
        )
    }

    private static func unknownAnswer(context: FinancialAssistantContext) -> FinancialAssistantAnswer {
        monthStatusAnswer(context: context, intent: .unknown)
    }

    private static func risk(
        projectedBalance: Decimal,
        balance: Decimal
    ) -> FinancialAssistantRisk {
        if projectedBalance < 0 {
            return .critical
        }

        if projectedBalance < balance * warningBalanceRatio {
            return .warning
        }

        return .positive
    }

    private static func savingsRisk(
        targetAmount: Decimal?,
        suggestedSaving: Decimal
    ) -> FinancialAssistantRisk {
        guard suggestedSaving > 0 else {
            return .neutral
        }

        guard let targetAmount else {
            return .positive
        }

        return suggestedSaving >= targetAmount ? .positive : .warning
    }

    private static func parseAmount(from question: String) -> Decimal? {
        let tokens = question
            .replacingOccurrences(of: "?", with: " ")
            .replacingOccurrences(of: ",", with: " ")
            .replacingOccurrences(of: "₫", with: " ")
            .split(separator: " ")
            .map(String.init)

        for tokenIndex in tokens.indices {
            let token = tokens[tokenIndex]
            let nextToken = tokens.index(after: tokenIndex) < tokens.endIndex
                ? tokens[tokens.index(after: tokenIndex)]
                : nil
            if let amount = amount(from: token, nextToken: nextToken) {
                return amount
            }
        }

        return nil
    }

    private static func amount(
        from token: String,
        nextToken: String?
    ) -> Decimal? {
        let rawNumber = token.filter {
            $0.isNumber || $0 == "." || $0 == ","
        }
        guard rawNumber.isEmpty == false else {
            return nil
        }

        var normalizedNumber = rawNumber.replacingOccurrences(of: ",", with: ".")
        let decimalSeparatorCount = normalizedNumber.filter { $0 == "." }.count
        if decimalSeparatorCount > 1 {
            normalizedNumber = normalizedNumber.replacingOccurrences(of: ".", with: "")
        }

        guard let numericValue = Double(normalizedNumber) else {
            return nil
        }

        let hasMillionUnit = token.contains("trieu") || nextToken == "trieu"
        let hasThousandUnit = token.contains("nghin") || token.contains("k") || nextToken == "nghin"
        let multiplier: Double
        if hasMillionUnit {
            multiplier = 1_000_000
        } else if hasThousandUnit {
            multiplier = 1_000
        } else if numericValue >= 10_000 {
            multiplier = 1
        } else {
            return nil
        }

        return Decimal(Int((numericValue * multiplier).rounded()))
    }

    private static func normalize(_ value: String) -> String {
        value
            .replacingOccurrences(of: "đ", with: "d")
            .replacingOccurrences(of: "Đ", with: "D")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi_VN"))
            .lowercased()
    }

    private static func containsAny(
        _ value: String,
        keywords: [String]
    ) -> Bool {
        keywords.contains { value.contains($0) }
    }

    private static func roundedToThousands(_ amount: Decimal) -> Decimal {
        let roundedValue = (NSDecimalNumber(decimal: amount).doubleValue / 1_000).rounded() * 1_000
        return Decimal(Int(roundedValue))
    }

    private static let fallbackSavingRatio = Decimal(10) / Decimal(100)
    private static let warningBalanceRatio = Decimal(20) / Decimal(100)
}

private struct FinancialAssistantContext {
    let transactions: [Transaction]
    let referenceDate: Date
    let calendar: Calendar

    var currentMonthSummary: MonthlyTransactionSummary {
        transactions.monthlySummary(containing: referenceDate, calendar: calendar)
    }

    var topCategory: CategorySpendingTotal? {
        categoryTotals().sorted {
            if $0.amount == $1.amount {
                return $0.category.id < $1.category.id
            }

            return $0.amount > $1.amount
        }
        .first
    }

    private func categoryTotals() -> [CategorySpendingTotal] {
        let totals = currentMonthExpenses.reduce(into: [TransactionCategory: Decimal]()) { result, transaction in
            result[transaction.category, default: 0] += transaction.amount
        }

        return totals.map {
            CategorySpendingTotal(category: $0.key, amount: $0.value)
        }
    }

    private var currentMonthExpenses: [Transaction] {
        transactions.filter {
            $0.kind == .expense
                && $0.amount > 0
                && $0.occurredAt <= referenceDate
                && calendar.isDate($0.occurredAt, equalTo: referenceDate, toGranularity: .month)
        }
    }
}

private struct CategorySpendingTotal: Equatable, Sendable {
    var category: TransactionCategory
    var amount: Decimal
}
