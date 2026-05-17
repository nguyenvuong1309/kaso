import ComposableArchitecture
import GuiltFreeBudgetDomain
import KasoDesignSystem
import SwiftUI

struct GuiltFreeIncomeEditorSheet: View {
    @Bindable var store: StoreOf<GuiltFreeBudgetFeature>

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        "guiltFree.income.monthly",
                        text: $store.incomeText.sending(\.incomeTextChanged)
                    )
                    .keyboardType(.decimalPad)
                } header: {
                    Text("guiltFree.income.monthly", bundle: .module)
                } footer: {
                    Text("guiltFree.income.monthly.footer", bundle: .module)
                }

                Section {
                    TextField(
                        "guiltFree.income.savings",
                        text: $store.savingsText.sending(\.savingsTextChanged)
                    )
                    .keyboardType(.decimalPad)
                } header: {
                    Text("guiltFree.income.savings", bundle: .module)
                } footer: {
                    Text("guiltFree.income.savings.footer", bundle: .module)
                }

                Section {
                    TextField(
                        "guiltFree.income.emergency",
                        text: $store.emergencyText.sending(\.emergencyTextChanged)
                    )
                    .keyboardType(.decimalPad)
                } header: {
                    Text("guiltFree.income.emergency", bundle: .module)
                } footer: {
                    Text("guiltFree.income.emergency.footer", bundle: .module)
                }

                if let messageKey = store.editorErrorMessageKey {
                    Section {
                        Text(LocalizedStringKey(messageKey), bundle: .module)
                            .foregroundStyle(Color.kaso.destructive)
                    }
                }
            }
            .navigationTitle(Text("guiltFree.income.editorTitle", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        store.send(.incomeEditorDismissed)
                    } label: {
                        Text("guiltFree.cancel", bundle: .module)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        store.send(.incomeSaveTapped)
                    } label: {
                        Text("guiltFree.save", bundle: .module)
                    }
                }
            }
        }
    }
}

struct GuiltFreeFixedCostEditorSheet: View {
    @Bindable var store: StoreOf<GuiltFreeBudgetFeature>

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        "guiltFree.fixedCosts.namePlaceholder",
                        text: $store.fixedCostNameText.sending(\.fixedCostNameChanged)
                    )
                    TextField(
                        "guiltFree.fixedCosts.amountPlaceholder",
                        text: $store.fixedCostAmountText.sending(\.fixedCostAmountChanged)
                    )
                    .keyboardType(.decimalPad)
                    Picker(
                        selection: $store.fixedCostKind.sending(\.fixedCostKindChanged)
                    ) {
                        ForEach(GuiltFreeFixedCostKind.allCases) { kind in
                            Text(LocalizedStringKey(kind.nameKey), bundle: .module)
                                .tag(kind)
                        }
                    } label: {
                        Text("guiltFree.fixedCosts.kind", bundle: .module)
                    }
                }

                if let messageKey = store.editorErrorMessageKey {
                    Section {
                        Text(LocalizedStringKey(messageKey), bundle: .module)
                            .foregroundStyle(Color.kaso.destructive)
                    }
                }
            }
            .navigationTitle(editorTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        store.send(.fixedCostEditorDismissed)
                    } label: {
                        Text("guiltFree.cancel", bundle: .module)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        store.send(.fixedCostSaveTapped)
                    } label: {
                        Text("guiltFree.save", bundle: .module)
                    }
                }
            }
        }
    }

    private var editorTitle: Text {
        store.editingFixedCostID == nil
            ? Text("guiltFree.fixedCosts.editorTitleNew", bundle: .module)
            : Text("guiltFree.fixedCosts.editorTitleEdit", bundle: .module)
    }
}
