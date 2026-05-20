import KasoDesignSystem
import MoneyTherapistDomain
import SwiftUI

struct MoneyTherapistHeaderCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("moneyTherapist.header.title", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)
            Text("moneyTherapist.header.subtitle", bundle: .module)
                .font(.kaso.body)
                .foregroundStyle(Color.kaso.textSecondary)
            Text("moneyTherapist.header.privacy", bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.positive)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MoneyTherapistTopicsCard: View {
    let onSelect: (TherapistTopic) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.sm),
        GridItem(.flexible(), spacing: Spacing.sm),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("moneyTherapist.topics.title", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            LazyVGrid(columns: columns, spacing: Spacing.sm) {
                ForEach(TherapistTopic.allCases) { topic in
                    Button {
                        onSelect(topic)
                    } label: {
                        MoneyTherapistTopicTile(topic: topic)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MoneyTherapistTopicTile: View {
    let topic: TherapistTopic

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Image(systemName: topic.iconSystemName)
                .foregroundStyle(Color.kaso.accent)
                .font(.title3)
            Text(LocalizedStringKey(topic.titleKey), bundle: .module)
                .font(.kaso.body.weight(.semibold))
                .foregroundStyle(Color.kaso.textPrimary)
            Text(LocalizedStringKey(topic.subtitleKey), bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
                .lineLimit(2)
        }
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Color.kaso.accent.opacity(0.08))
        )
    }
}

struct MoneyTherapistHistoryCard: View {
    let reflections: [TherapistReflection]
    let onDelete: (TherapistReflection) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("moneyTherapist.history.title", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            ForEach(reflections) { reflection in
                MoneyTherapistHistoryRow(
                    reflection: reflection,
                    onDelete: { onDelete(reflection) }
                )
                if reflection.id != reflections.last?.id {
                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MoneyTherapistHistoryRow: View {
    let reflection: TherapistReflection
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: reflection.topic.iconSystemName)
                .foregroundStyle(Color.kaso.accent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(reflection.topic.titleKey), bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textPrimary)
                if let note = reflection.note, note.isEmpty == false {
                    Text(note)
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                        .lineLimit(3)
                }
                Text(reflection.recordedAt, format: .dateTime.day().month().year())
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
    }
}

struct MoneyTherapistReflectionSheet: View {
    let prompt: TherapistPrompt
    @Binding var noteText: String
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text(LocalizedStringKey(prompt.openingMessageKey), bundle: .module)
                        .font(.kaso.body)
                        .foregroundStyle(Color.kaso.textPrimary)

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("moneyTherapist.sheet.questions", bundle: .module)
                            .font(.kaso.body.weight(.semibold))
                        ForEach(prompt.reflectionQuestionKeys, id: \.self) { key in
                            HStack(alignment: .top, spacing: Spacing.xs) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundStyle(Color.kaso.accent)
                                    .padding(.top, 6)
                                Text(LocalizedStringKey(key), bundle: .module)
                                    .font(.kaso.body)
                                    .foregroundStyle(Color.kaso.textPrimary)
                            }
                        }
                    }
                    .padding(Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                            .fill(Color.kaso.accent.opacity(0.08))
                    )

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("moneyTherapist.sheet.note", bundle: .module)
                            .font(.kaso.body.weight(.semibold))
                        TextField(
                            "moneyTherapist.sheet.notePlaceholder",
                            text: $noteText,
                            axis: .vertical
                        )
                        .lineLimit(3 ... 6)
                        .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("moneyTherapist.sheet.actions", bundle: .module)
                            .font(.kaso.body.weight(.semibold))
                        ForEach(prompt.suggestedActionKeys, id: \.self) { key in
                            HStack(alignment: .top, spacing: Spacing.xs) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(Color.kaso.positive)
                                Text(LocalizedStringKey(key), bundle: .module)
                                    .font(.kaso.body)
                            }
                        }
                    }

                    Text(LocalizedStringKey(prompt.closingMessageKey), bundle: .module)
                        .font(.kaso.body)
                        .foregroundStyle(Color.kaso.textSecondary)
                        .padding(.top, Spacing.sm)
                }
                .padding(Spacing.md)
            }
            .background(Color.kaso.surfacePrimary)
            .navigationTitle(Text(LocalizedStringKey(prompt.topic.titleKey), bundle: .module))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(
                        action: onCancel,
                        label: { Text("moneyTherapist.sheet.cancel", bundle: .module) }
                    )
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(
                        action: onSave,
                        label: { Text("moneyTherapist.sheet.save", bundle: .module) }
                    )
                }
            }
        }
    }
}
