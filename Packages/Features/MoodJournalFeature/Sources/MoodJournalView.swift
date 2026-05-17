import ComposableArchitecture
import KasoDesignSystem
import MoodJournalDomain
import SwiftUI

public struct MoodJournalRootView: View {
    private let store: StoreOf<MoodJournalFeature>

    public init(repository: MoodJournalRepository = .empty) {
        store = Store(initialState: MoodJournalFeature.State()) {
            MoodJournalFeature()
        } withDependencies: {
            $0.moodJournalRepository = repository
        }
    }

    public var body: some View {
        MoodJournalView(store: store)
    }
}

public struct MoodJournalView: View {
    @Bindable private var store: StoreOf<MoodJournalFeature>

    public init(store: StoreOf<MoodJournalFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    if store.isLoading {
                        ProgressView().frame(maxWidth: .infinity)
                    }

                    if let messageKey = store.errorMessageKey {
                        MoodJournalErrorLabel(messageKey: messageKey)
                    }

                    KasoCard {
                        MoodJournalInsightCard(insight: store.insight)
                    }

                    if store.insight.breakdowns.isEmpty == false {
                        KasoCard {
                            MoodJournalBreakdownCard(breakdowns: store.insight.breakdowns)
                        }
                    }

                    KasoCard {
                        MoodJournalEntriesCard(
                            entries: Array(store.entries),
                            onAdd: { store.send(.addButtonTapped) },
                            onEdit: { store.send(.editButtonTapped($0)) },
                            onDelete: { store.send(.deleteButtonTapped($0.id)) }
                        )
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.kaso.surfacePrimary)
            .navigationTitle(Text("moodJournal.title", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.send(.addButtonTapped)
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                    .accessibilityLabel(Text("moodJournal.add", bundle: .module))
                }
            }
            .sheet(isPresented: editorPresented) {
                MoodJournalEditorSheet(store: store)
                    .presentationDetents([.medium, .large])
            }
            .task {
                await store.send(.task).finish()
            }
        }
    }

    private var editorPresented: Binding<Bool> {
        Binding(
            get: { store.isEditorPresented },
            set: { presented in
                if presented == false {
                    store.send(.editorDismissed)
                }
            }
        )
    }
}

private struct MoodJournalErrorLabel: View {
    let messageKey: String

    var body: some View {
        Label {
            Text(LocalizedStringKey(messageKey), bundle: .module)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
        }
        .font(.kaso.caption)
        .foregroundStyle(Color.kaso.destructive)
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Color.kaso.destructive.opacity(0.12))
        )
    }
}
