import SwiftUI
import InsightDomain
import KasoDesignSystem
import TransactionDomain

struct FinancialAssistantAnswerCard: View {
    let answer: FinancialAssistantAnswer

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                Image(systemName: answer.risk.symbolName)
                    .foregroundStyle(answer.risk.tintColor)
                    .font(.kaso.titleMedium)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(LocalizedStringKey(answer.intent.titleKey), bundle: .module)
                        .font(.kaso.titleMedium)
                        .foregroundStyle(Color.kaso.textPrimary)

                    Text(LocalizedStringKey(answer.intent.summaryKey), bundle: .module)
                        .font(.kaso.body)
                        .foregroundStyle(Color.kaso.textSecondary)
                }

                Spacer()

                Text(LocalizedStringKey(answer.risk.titleKey), bundle: .module)
                    .font(.kaso.caption)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(answer.risk.tintColor.opacity(0.14), in: Capsule())
                    .foregroundStyle(answer.risk.tintColor)
            }

            VStack(spacing: Spacing.sm) {
                ForEach(answer.facts) { fact in
                    FinancialAssistantFactRow(fact: fact)
                }
            }

            if let category = answer.recommendedCategory {
                FinancialAssistantCategoryHint(category: category)
            }

            Label {
                Text("assistant.privacy.onDevice", bundle: .module)
            } icon: {
                Image(systemName: "lock.shield")
            }
            .font(.kaso.caption)
            .foregroundStyle(Color.kaso.textSecondary)
        }
    }
}

private struct FinancialAssistantFactRow: View {
    let fact: FinancialAssistantFact

    var body: some View {
        HStack(spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(LocalizedStringKey(fact.kind.titleKey), bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)

                if let category = fact.category {
                    Label {
                        Text(LocalizedStringKey(category.nameKey), bundle: .module)
                    } icon: {
                        Image(systemName: category.symbolName)
                    }
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
                }
            }

            Spacer()

            Text(fact.amount.formatted(.currency(code: "VND")))
                .font(.kaso.numericMedium)
                .foregroundStyle(fact.kind.amountColor)
        }
        .padding(Spacing.sm)
        .background(
            Color.kaso.surfacePrimary,
            in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
        )
    }
}

private struct FinancialAssistantCategoryHint: View {
    let category: TransactionCategory

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: category.symbolName)
                .foregroundStyle(Color.kaso.category(named: category.colorName))

            Text("assistant.recommendation.category", bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)

            Text(LocalizedStringKey(category.nameKey), bundle: .module)
                .font(.kaso.body)
                .foregroundStyle(Color.kaso.textPrimary)
        }
        .padding(Spacing.sm)
        .background(
            Color.kaso.accent.opacity(0.10),
            in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
        )
    }
}

extension FinancialAssistantRisk {
    var tintColor: Color {
        switch self {
        case .positive:
            Color.kaso.positive
        case .neutral:
            Color.kaso.accent
        case .warning:
            Color.kaso.warning
        case .critical:
            Color.kaso.destructive
        }
    }

    var symbolName: String {
        switch self {
        case .positive:
            "checkmark.seal"
        case .neutral:
            "sparkles"
        case .warning:
            "exclamationmark.triangle"
        case .critical:
            "xmark.octagon"
        }
    }
}

private extension FinancialAssistantFactKind {
    var amountColor: Color {
        switch self {
        case .income, .balance, .projectedBalance, .suggestedSaving:
            Color.kaso.positive
        case .expense, .requestedAmount, .topCategoryExpense:
            Color.kaso.textPrimary
        }
    }
}
