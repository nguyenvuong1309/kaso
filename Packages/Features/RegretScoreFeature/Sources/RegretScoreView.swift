import ComposableArchitecture
import KasoDesignSystem
import RegretScoreDomain
import SwiftUI

public struct RegretScoreRootView: View {
    private let store: StoreOf<RegretScoreFeature>

    public init(
        repository: RegretRatingRepository = .empty,
        reminderContext: RegretReminderContextClient = .empty
    ) {
        store = Store(initialState: RegretScoreFeature.State()) {
            RegretScoreFeature()
        } withDependencies: {
            $0.regretRatingRepository = repository
            $0.regretReminderContextClient = reminderContext
        }
    }

    public var body: some View {
        RegretScoreView(store: store)
    }
}

public struct RegretScoreView: View {
    @Bindable private var store: StoreOf<RegretScoreFeature>

    public init(store: StoreOf<RegretScoreFeature>) {
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
                        RegretErrorLabel(messageKey: messageKey)
                    }

                    KasoCard {
                        RegretSummaryCard(summary: store.summary)
                    }

                    if store.reminders.isEmpty == false {
                        KasoCard {
                            RegretRemindersCard(
                                reminders: Array(store.reminders),
                                onRate: { store.send(.rateReminderTapped($0)) },
                                onDismiss: { store.send(.dismissReminderTapped($0.id)) }
                            )
                        }
                    }

                    if store.summary.categorySummaries.isEmpty == false {
                        KasoCard {
                            RegretCategoryCard(categories: store.summary.categorySummaries)
                        }
                    }

                    if store.summary.topRegretedPurchases.isEmpty == false {
                        KasoCard {
                            RegretTopCard(top: store.summary.topRegretedPurchases)
                        }
                    }

                    KasoCard {
                        RegretRatingsCard(
                            ratings: Array(store.ratings),
                            onAdd: { store.send(.addButtonTapped) },
                            onEdit: { store.send(.editButtonTapped($0)) },
                            onDelete: { store.send(.deleteButtonTapped($0.id)) }
                        )
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.kaso.surfacePrimary)
            .navigationTitle(Text("regret.title", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.send(.addButtonTapped)
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                    .accessibilityLabel(Text("regret.add", bundle: .module))
                }
            }
            .sheet(isPresented: editorPresented) {
                RegretEditorSheet(store: store)
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

private struct RegretErrorLabel: View {
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
