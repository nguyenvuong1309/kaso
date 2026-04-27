import SwiftUI
import ComposableArchitecture
import InvestmentDomain
import KasoDesignSystem

struct InvestmentHoldingEditorSheet: View {
    @Bindable var store: StoreOf<InvestmentFeature>

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(text: $store.symbolText.sending(\.symbolTextChanged)) {
                        Text("investment.holding.symbol", bundle: .module)
                    }

                    TextField(text: $store.nameText.sending(\.nameTextChanged)) {
                        Text("investment.holding.name", bundle: .module)
                    }

                    Picker(selection: $store.assetClass.sending(\.assetClassChanged)) {
                        ForEach(AssetClass.allCases) { assetClass in
                            Label {
                                Text(LocalizedStringKey(assetClass.nameKey), bundle: .module)
                            } icon: {
                                Image(systemName: assetClass.symbolName)
                            }
                            .tag(assetClass)
                        }
                    } label: {
                        Text("investment.holding.assetClass", bundle: .module)
                    }
                }

                Section {
                    TextField(text: $store.quantityText.sending(\.quantityTextChanged)) {
                        Text("investment.holding.quantity", bundle: .module)
                    }

                    TextField(text: $store.costBasisText.sending(\.costBasisTextChanged)) {
                        Text("investment.holding.costBasis", bundle: .module)
                    }

                    TextField(text: $store.currentPriceText.sending(\.currentPriceTextChanged)) {
                        Text("investment.holding.currentPrice", bundle: .module)
                    }

                    DatePicker(
                        selection: $store.purchaseDate.sending(\.purchaseDateChanged),
                        displayedComponents: .date
                    ) {
                        Text("investment.holding.purchaseDate", bundle: .module)
                    }
                } header: {
                    Text("investment.holding.lot", bundle: .module)
                }

                Section {
                    TextField(
                        text: $store.noteText.sending(\.noteTextChanged),
                        axis: .vertical
                    ) {
                        Text("investment.holding.note", bundle: .module)
                    }
                }

                if let errorMessageKey = store.holdingEditorErrorMessageKey {
                    InvestmentEditorErrorLabel(messageKey: errorMessageKey)
                }
            }
            .navigationTitle(Text("investment.holding.editor.title", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        store.send(.holdingEditorDismissed)
                    } label: {
                        Text("investment.cancel", bundle: .module)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        store.send(.holdingSaveButtonTapped)
                    } label: {
                        if store.isHoldingSaving {
                            ProgressView()
                        } else {
                            Text("investment.save", bundle: .module)
                        }
                    }
                    .disabled(store.isHoldingSaving)
                }
            }
        }
    }
}

struct InvestmentEditorErrorLabel: View {
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
    }
}
