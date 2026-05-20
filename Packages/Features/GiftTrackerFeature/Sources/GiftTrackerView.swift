import ComposableArchitecture
import GiftTrackerDomain
import KasoDesignSystem
import SwiftUI

public struct GiftTrackerView: View {
    @Bindable var store: StoreOf<GiftTrackerFeature>

    public init(store: StoreOf<GiftTrackerFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            Group {
                if store.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if store.records.isEmpty {
                    emptyState
                } else {
                    content
                }
            }
            .navigationTitle(Text("gift.title", bundle: .module))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.send(.addButtonTapped)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { store.isEditorPresented },
            set: { if !$0 { store.send(.editorDismissed) } }
        )) {
            GiftEditorSheet(store: store)
        }
        .task { await store.send(.task).finish() }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                GiftYearlySummaryCard(summary: store.yearlySummary)
                    .padding(.horizontal, Spacing.md)

                if store.selectedPersonName != nil {
                    personDetailSection
                } else {
                    personListSection
                }
            }
            .padding(.vertical, Spacing.md)
        }
    }

    private var personListSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("gift.section.people", bundle: .module)
                .font(Font.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
                .padding(.horizontal, Spacing.md)

            ForEach(store.personSummaries) { summary in
                Button {
                    store.send(.personSelected(summary.personName))
                } label: {
                    GiftPersonSummaryRow(summary: summary)
                        .padding(.horizontal, Spacing.md)
                }
                .tint(.primary)

                Divider()
                    .padding(.leading, Spacing.md)
            }
        }
    }

    private var personDetailSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Button {
                    store.send(.personDeselected)
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "chevron.left")
                            .font(.kaso.caption)
                        Text("gift.back", bundle: .module)
                    }
                    .foregroundStyle(Color.kaso.accent)
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.md)

            if let name = store.selectedPersonName {
                Text(name)
                    .font(Font.kaso.titleMedium)
                    .foregroundStyle(Color.kaso.textPrimary)
                    .padding(.horizontal, Spacing.md)
            }

            ForEach(store.filteredPersonRecords) { record in
                GiftRecordRow(record: record)
                    .padding(.horizontal, Spacing.md)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            store.send(.deleteButtonTapped(record.id))
                        } label: {
                            Image(systemName: "trash")
                        }

                        Button {
                            store.send(.editButtonTapped(record))
                        } label: {
                            Image(systemName: "pencil")
                        }
                        .tint(.blue)
                    }

                Divider()
                    .padding(.leading, Spacing.md)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "envelope.open.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color.kaso.textSecondary.opacity(0.6))

            Text("gift.empty.title", bundle: .module)
                .font(Font.kaso.body)
                .foregroundStyle(Color.kaso.textPrimary)

            Text("gift.empty.subtitle", bundle: .module)
                .font(Font.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)

            Button {
                store.send(.addButtonTapped)
            } label: {
                Text("gift.add.button", bundle: .module)
                    .font(Font.kaso.body)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.kaso.accent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct GiftYearlySummaryCard: View {
    let summary: GiftYearlySummary

    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Text("gift.summary.year \(summary.year)", bundle: .module)
                    .font(Font.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
                Spacer()
                Text("\(summary.recordCount) giao dịch")
                    .font(Font.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary.opacity(0.6))
            }

            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("gift.summary.given", bundle: .module)
                        .font(Font.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                    Text(summary.totalGiven, format: .currency(code: "VND"))
                        .font(Font.kaso.titleMedium)
                        .foregroundStyle(Color.kaso.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("gift.summary.received", bundle: .module)
                        .font(Font.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                    Text(summary.totalReceived, format: .currency(code: "VND"))
                        .font(Font.kaso.titleMedium)
                        .foregroundStyle(Color.kaso.positive)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.kaso.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }
}

private struct GiftPersonSummaryRow: View {
    let summary: GiftPersonSummary

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(Color.kaso.surfaceSecondary)
                .frame(width: 44, height: 44)
                .overlay {
                    Text(summary.personName.prefix(1).uppercased())
                        .font(Font.kaso.titleMedium)
                        .foregroundStyle(Color.kaso.textSecondary)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(summary.personName)
                    .font(Font.kaso.body)
                    .foregroundStyle(Color.kaso.textPrimary)

                HStack(spacing: Spacing.xs) {
                    Image(systemName: summary.lastEventKind.symbolName)
                        .font(.kaso.caption)
                    Text(summary.lastEventDate, style: .relative)
                        .font(Font.kaso.caption)
                }
                .foregroundStyle(Color.kaso.textSecondary.opacity(0.6))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(summary.totalGiven, format: .currency(code: "VND"))
                    .font(Font.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)

                Image(systemName: "chevron.right")
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary.opacity(0.6))
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}

private struct GiftRecordRow: View {
    let record: GiftRecord

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: record.eventKind.symbolName)
                .font(Font.kaso.body)
                .foregroundStyle(Color.kaso.textSecondary)
                .frame(width: 36, height: 36)
                .background(Color.kaso.surfaceSecondary)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(record.eventKind.nameKey), bundle: .module)
                    .font(Font.kaso.body)
                    .foregroundStyle(Color.kaso.textPrimary)

                if let note = record.note, note.isEmpty == false {
                    Text(note)
                        .font(Font.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                        .lineLimit(1)
                }

                Text(record.eventDate, style: .date)
                    .font(Font.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary.opacity(0.6))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(record.amount, format: .currency(code: "VND"))
                    .font(Font.kaso.body)
                    .foregroundStyle(
                        record.direction == .received
                            ? Color.kaso.positive
                            : Color.kaso.textPrimary
                    )

                Text(LocalizedStringKey(record.direction.nameKey), bundle: .module)
                    .font(Font.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary.opacity(0.6))
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}
