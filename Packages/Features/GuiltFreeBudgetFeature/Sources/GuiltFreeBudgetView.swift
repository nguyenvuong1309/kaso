import ComposableArchitecture
import GuiltFreeBudgetDomain
import KasoDesignSystem
import SwiftUI

public struct GuiltFreeBudgetRootView: View {
    private let store: StoreOf<GuiltFreeBudgetFeature>

    public init(repository: GuiltFreeBudgetRepository = .empty) {
        store = Store(initialState: GuiltFreeBudgetFeature.State()) {
            GuiltFreeBudgetFeature()
        } withDependencies: {
            $0.guiltFreeBudgetRepository = repository
        }
    }

    public var body: some View {
        GuiltFreeBudgetView(store: store)
    }
}

public struct GuiltFreeBudgetView: View {
    @Bindable private var store: StoreOf<GuiltFreeBudgetFeature>

    public init(store: StoreOf<GuiltFreeBudgetFeature>) {
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
                        GuiltFreeErrorLabel(messageKey: messageKey)
                    }

                    KasoCard {
                        GuiltFreeHeadlineCard(
                            budget: store.budget,
                            dailyAllowance: store.dailyAllowance
                        )
                    }

                    KasoCard {
                        GuiltFreeBreakdownCard(budget: store.budget)
                    }

                    KasoCard {
                        GuiltFreeIncomeCard(
                            configuration: store.configuration,
                            onEdit: { store.send(.incomeEditorOpened) }
                        )
                    }

                    KasoCard {
                        GuiltFreeFixedCostsCard(
                            fixedCosts: store.configuration.fixedCosts,
                            onAdd: { store.send(.fixedCostEditorOpenedNew) },
                            onEdit: { store.send(.fixedCostEditorOpenedExisting($0.id)) },
                            onDelete: { store.send(.fixedCostDeleteTapped($0.id)) }
                        )
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.kaso.surfacePrimary)
            .navigationTitle(Text("guiltFree.title", bundle: .module))
            .sheet(isPresented: incomeEditorPresented) {
                GuiltFreeIncomeEditorSheet(store: store)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: fixedCostEditorPresented) {
                GuiltFreeFixedCostEditorSheet(store: store)
                    .presentationDetents([.medium])
            }
            .task {
                await store.send(.task).finish()
            }
        }
    }

    private var incomeEditorPresented: Binding<Bool> {
        Binding(
            get: { store.isIncomeEditorPresented },
            set: { presented in
                if presented == false {
                    store.send(.incomeEditorDismissed)
                }
            }
        )
    }

    private var fixedCostEditorPresented: Binding<Bool> {
        Binding(
            get: { store.isFixedCostEditorPresented },
            set: { presented in
                if presented == false {
                    store.send(.fixedCostEditorDismissed)
                }
            }
        )
    }
}

private struct GuiltFreeErrorLabel: View {
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
