import SwiftUI
import ComposableArchitecture
import KasoDesignSystem
import PhantomExpenseDomain

public struct PhantomExpenseRootView: View {
    private let store: StoreOf<PhantomExpenseFeature>

    public init(repository: PhantomExpenseRepository = .empty) {
        store = Store(initialState: PhantomExpenseFeature.State()) {
            PhantomExpenseFeature()
        } withDependencies: {
            $0.phantomExpenseRepository = repository
        }
    }

    public var body: some View {
        PhantomExpenseView(store: store)
    }
}

public struct PhantomExpenseView: View {
    @Bindable private var store: StoreOf<PhantomExpenseFeature>

    public init(store: StoreOf<PhantomExpenseFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    if store.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }

                    if let errorMessageKey = store.errorMessageKey {
                        PhantomExpenseErrorLabel(messageKey: errorMessageKey)
                    }

                    KasoCard {
                        PhantomExpenseSummaryCard(summary: store.monthlySummary)
                    }

                    KasoCard {
                        PhantomExpenseCategoryCard(
                            summaries: store.monthlySummary.categorySummaries
                        )
                    }

                    KasoCard {
                        PhantomExpenseListCard(
                            expenses: store.monthlySummary.expenses,
                            onAddTapped: {
                                store.send(.addButtonTapped)
                            },
                            onEditTapped: { expense in
                                store.send(.editButtonTapped(expense))
                            },
                            onDeleteTapped: { expense in
                                store.send(.deleteButtonTapped(expense))
                            }
                        )
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.kaso.surfacePrimary)
            .navigationTitle(Text("phantom.title", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.send(.addButtonTapped)
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                    .accessibilityLabel(Text("phantom.add", bundle: .module))
                }
            }
            .sheet(isPresented: editorPresented) {
                PhantomExpenseEditorSheet(store: store)
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
            set: { isPresented in
                if isPresented == false {
                    store.send(.editorDismissed)
                }
            }
        )
    }
}

private struct PhantomExpenseErrorLabel: View {
    let messageKey: String

    var body: some View {
        Label {
            Text(LocalizedStringKey(messageKey), bundle: .module)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.kaso.destructive)
        }
        .font(.kaso.caption)
        .foregroundStyle(Color.kaso.destructive)
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Color.kaso.destructive.opacity(Layout.alertBackgroundOpacity))
        )
    }
}

private enum Layout {
    static let alertBackgroundOpacity: Double = 0.12
}
