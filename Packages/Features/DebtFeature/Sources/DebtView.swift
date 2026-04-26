import SwiftUI
import ComposableArchitecture
import DebtDomain
import KasoDesignSystem

public struct DebtRootView: View {
    private let store: StoreOf<DebtFeature>

    public init(
        debtRepository: DebtRepository = .empty,
        liabilitySyncClient: DebtLiabilitySyncClient = .empty
    ) {
        store = Store(initialState: DebtFeature.State()) {
            DebtFeature()
        } withDependencies: {
            $0.debtRepository = debtRepository
            $0.debtLiabilitySyncClient = liabilitySyncClient
        }
    }

    public var body: some View {
        DebtView(store: store)
    }
}

public struct DebtView: View {
    @Bindable private var store: StoreOf<DebtFeature>

    public init(store: StoreOf<DebtFeature>) {
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
                        DebtErrorLabel(messageKey: errorMessageKey)
                    }

                    KasoCard {
                        DebtSummaryCard(summary: store.summary)
                    }

                    KasoCard {
                        SelectedDebtCard(
                            debts: Array(store.debts),
                            selectedDebtID: store.selectedDebtID,
                            schedule: store.selectedSchedule,
                            referenceDate: store.referenceDate,
                            onDebtSelected: { id in
                                store.send(.debtSelected(id))
                            }
                        )
                    }

                    KasoCard {
                        ExtraPaymentCard(store: store)
                    }

                    KasoCard {
                        DebtListSection(
                            debts: Array(store.debts),
                            referenceDate: store.referenceDate,
                            onAddTapped: {
                                store.send(.debtAddButtonTapped)
                            },
                            onEditTapped: { debt in
                                store.send(.debtEditButtonTapped(debt))
                            },
                            onDeleteTapped: { debt in
                                store.send(.debtDeleteButtonTapped(debt))
                            }
                        )
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.kaso.surfacePrimary)
            .navigationTitle(Text("debt.title", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.send(.debtAddButtonTapped)
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                    .accessibilityLabel(Text("debt.add", bundle: .module))
                }
            }
            .sheet(isPresented: debtEditorPresented) {
                DebtEditorSheet(store: store)
                    .presentationDetents([.large])
            }
            .task {
                await store.send(.task).finish()
            }
        }
    }

    private var debtEditorPresented: Binding<Bool> {
        Binding(
            get: { store.isDebtEditorPresented },
            set: { isPresented in
                if isPresented == false {
                    store.send(.debtEditorDismissed)
                }
            }
        )
    }
}

struct DebtErrorLabel: View {
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
