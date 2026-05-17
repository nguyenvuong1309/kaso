import KasoDesignSystem
import RegretScoreDomain
import SwiftUI

struct RegretSummaryCard: View {
    let summary: RegretSummary

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("regret.summary.headline", bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)

            Text(RegretFormatters.currency(summary.totalRegretedAmount))
                .font(.kaso.titleLarge)
                .foregroundStyle(summary.regretCount > 0 ? Color.kaso.destructive : Color.kaso.textSecondary)

            HStack(spacing: Spacing.md) {
                metric(
                    labelKey: "regret.summary.ratings",
                    value: String(summary.totalCount)
                )
                metric(
                    labelKey: "regret.summary.regretCount",
                    value: String(summary.regretCount)
                )
                metric(
                    labelKey: "regret.summary.regretRatio",
                    value: String(format: "%.0f%%", summary.regretRatio * 100)
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func metric(labelKey: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(LocalizedStringKey(labelKey), bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
            Text(value)
                .font(.kaso.numericMedium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RegretRemindersCard: View {
    let reminders: [RegretReminderCandidate]
    let onRate: (RegretReminderCandidate) -> Void
    let onDismiss: (RegretReminderCandidate) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("regret.reminders.headline", bundle: .module)
                .font(.kaso.titleMedium)
            Text("regret.reminders.description", bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)

            VStack(spacing: Spacing.sm) {
                ForEach(reminders) { candidate in
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(Color.kaso.warning)
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(candidate.title)
                                .font(.kaso.body)
                            Text(RegretFormatters.currency(candidate.amount))
                                .font(.kaso.numericMedium)
                            Text(candidate.occurredAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.kaso.caption)
                                .foregroundStyle(Color.kaso.textSecondary)
                        }
                        Spacer()
                        VStack(spacing: Spacing.xs) {
                            Button {
                                onRate(candidate)
                            } label: {
                                Text("regret.reminders.rate", bundle: .module)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            Button(role: .cancel) {
                                onDismiss(candidate)
                            } label: {
                                Text("regret.reminders.dismiss", bundle: .module)
                            }
                            .buttonStyle(.borderless)
                            .controlSize(.small)
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                }
            }
        }
    }
}

struct RegretCategoryCard: View {
    let categories: [RegretCategorySummary]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("regret.category.headline", bundle: .module)
                .font(.kaso.titleMedium)

            VStack(spacing: Spacing.sm) {
                ForEach(categories) { summary in
                    HStack {
                        Text(summary.category.capitalized)
                            .font(.kaso.body)
                        Spacer()
                        Text(String(format: "%.0f%%", summary.regretRatio * 100))
                            .font(.kaso.numericMedium)
                            .foregroundStyle(summary.regretRatio > 0.5 ? Color.kaso.destructive : Color.kaso.textPrimary)
                    }
                }
            }
        }
    }
}

struct RegretTopCard: View {
    let top: [RegretRating]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("regret.top.headline", bundle: .module)
                .font(.kaso.titleMedium)

            VStack(spacing: Spacing.sm) {
                ForEach(top) { rating in
                    HStack {
                        Image(systemName: rating.score.symbolName)
                            .foregroundStyle(Color.kaso.destructive)
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(rating.purchaseTitle)
                                .font(.kaso.body)
                            Text(rating.category.capitalized)
                                .font(.kaso.caption)
                                .foregroundStyle(Color.kaso.textSecondary)
                        }
                        Spacer()
                        Text(RegretFormatters.currency(rating.amount))
                            .font(.kaso.numericMedium)
                    }
                }
            }
        }
    }
}

struct RegretRatingsCard: View {
    let ratings: [RegretRating]
    let onAdd: () -> Void
    let onEdit: (RegretRating) -> Void
    let onDelete: (RegretRating) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("regret.ratings.headline", bundle: .module)
                    .font(.kaso.titleMedium)
                Spacer()
                Button {
                    onAdd()
                } label: {
                    Label {
                        Text("regret.ratings.add", bundle: .module)
                    } icon: {
                        Image(systemName: "plus.circle")
                    }
                }
                .font(.kaso.caption)
            }

            if ratings.isEmpty {
                Text("regret.ratings.empty", bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(ratings.prefix(12)) { rating in
                        RegretRatingRow(
                            rating: rating,
                            onEdit: { onEdit(rating) },
                            onDelete: { onDelete(rating) }
                        )
                    }
                }
            }
        }
    }
}

private struct RegretRatingRow: View {
    let rating: RegretRating
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: rating.score.symbolName)
                .foregroundStyle(rating.score.isRegret ? Color.kaso.destructive : Color.kaso.positive)
                .imageScale(.large)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(rating.purchaseTitle)
                    .font(.kaso.body)
                Text(rating.category.capitalized)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
                if let note = rating.note {
                    Text(note)
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: Spacing.xs) {
                Text(RegretFormatters.currency(rating.amount))
                    .font(.kaso.numericMedium)
                Text(LocalizedStringKey(rating.score.nameKey), bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
            }
            Menu {
                Button {
                    onEdit()
                } label: {
                    Label {
                        Text("regret.ratings.edit", bundle: .module)
                    } icon: {
                        Image(systemName: "pencil")
                    }
                }
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label {
                        Text("regret.ratings.delete", bundle: .module)
                    } icon: {
                        Image(systemName: "trash")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel(Text("regret.ratings.menu", bundle: .module))
        }
        .padding(.vertical, Spacing.xs)
    }
}
