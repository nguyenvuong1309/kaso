import KasoDesignSystem
import MoodJournalDomain
import SwiftUI

struct MoodJournalInsightCard: View {
    let insight: MoodInsight

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("moodJournal.insight.headline", bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)

            if insight.hasEnoughData, let delta = insight.deltaPercent {
                Text(
                    String(
                        format: NSLocalizedString(
                            "moodJournal.insight.delta",
                            bundle: .module,
                            comment: ""
                        ),
                        deltaText(delta)
                    )
                )
                .font(.kaso.titleMedium)
                .foregroundStyle(delta > 0 ? Color.kaso.warning : Color.kaso.positive)

                Text("moodJournal.insight.description", bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
            } else {
                Text(
                    String(
                        format: NSLocalizedString(
                            "moodJournal.insight.needMore",
                            bundle: .module,
                            comment: ""
                        ),
                        insight.entryCount,
                        MoodInsightCalculator.minimumEntriesForInsight
                    )
                )
                .font(.kaso.body)
                .foregroundStyle(Color.kaso.textSecondary)
            }

            Divider().padding(.vertical, Spacing.xs)

            HStack(spacing: Spacing.md) {
                metric(
                    labelKey: "moodJournal.insight.positiveAverage",
                    value: MoodJournalFormatters.currency(insight.positiveMoodAverage)
                )
                metric(
                    labelKey: "moodJournal.insight.negativeAverage",
                    value: MoodJournalFormatters.currency(insight.negativeMoodAverage)
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func deltaText(_ delta: Double) -> String {
        let magnitude = abs(delta).rounded()
        return "\(Int(magnitude))%"
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

struct MoodJournalBreakdownCard: View {
    let breakdowns: [MoodSpendingBreakdown]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("moodJournal.breakdown.headline", bundle: .module)
                .font(.kaso.titleMedium)

            VStack(spacing: Spacing.sm) {
                ForEach(breakdowns) { breakdown in
                    HStack {
                        Text(breakdown.mood.emoji)
                            .font(.title3)
                        VStack(alignment: .leading) {
                            Text(LocalizedStringKey(breakdown.mood.nameKey), bundle: .module)
                                .font(.kaso.body)
                            Text(
                                String(
                                    format: NSLocalizedString(
                                        "moodJournal.breakdown.entries",
                                        bundle: .module,
                                        comment: ""
                                    ),
                                    breakdown.entryCount
                                )
                            )
                            .font(.kaso.caption)
                            .foregroundStyle(Color.kaso.textSecondary)
                        }
                        Spacer()
                        Text(MoodJournalFormatters.currency(breakdown.averageSpending))
                            .font(.kaso.numericMedium)
                    }
                }
            }
        }
    }
}

struct MoodJournalEntriesCard: View {
    let entries: [MoodEntry]
    let onAdd: () -> Void
    let onEdit: (MoodEntry) -> Void
    let onDelete: (MoodEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("moodJournal.entries.headline", bundle: .module)
                    .font(.kaso.titleMedium)
                Spacer()
                Button {
                    onAdd()
                } label: {
                    Label {
                        Text("moodJournal.entries.add", bundle: .module)
                    } icon: {
                        Image(systemName: "plus.circle")
                    }
                }
                .font(.kaso.caption)
            }

            if entries.isEmpty {
                Text("moodJournal.entries.empty", bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(entries.prefix(12)) { entry in
                        MoodJournalEntryRow(
                            entry: entry,
                            onEdit: { onEdit(entry) },
                            onDelete: { onDelete(entry) }
                        )
                    }
                }
            }
        }
    }
}

private struct MoodJournalEntryRow: View {
    let entry: MoodEntry
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Text(entry.mood.emoji)
                .font(.title2)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(LocalizedStringKey(entry.mood.nameKey), bundle: .module)
                        .font(.kaso.body)
                    Spacer()
                    Text(entry.recordedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                }
                if entry.spendingTotalSnapshot > 0 {
                    Text(MoodJournalFormatters.currency(entry.spendingTotalSnapshot))
                        .font(.kaso.numericMedium)
                }
                if let note = entry.note {
                    Text(note)
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                }
            }
            Spacer()
            Menu {
                Button {
                    onEdit()
                } label: {
                    Label {
                        Text("moodJournal.entries.edit", bundle: .module)
                    } icon: {
                        Image(systemName: "pencil")
                    }
                }
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label {
                        Text("moodJournal.entries.delete", bundle: .module)
                    } icon: {
                        Image(systemName: "trash")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel(Text("moodJournal.entries.menu", bundle: .module))
        }
        .padding(.vertical, Spacing.xs)
    }
}
