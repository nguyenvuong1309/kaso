import BNPLDomain
import ComposableArchitecture
import KasoDesignSystem
import SwiftUI

struct BNPLEditorSheet: View {
    @Bindable var store: StoreOf<BNPLFeature>

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        text: Binding(
                            get: { store.draftPurchaseName },
                            set: { store.send(.purchaseNameChanged($0)) }
                        ),
                        prompt: Text("bnpl.editor.purchaseName.placeholder", bundle: .module)
                    ) {
                        Text("bnpl.editor.purchaseName", bundle: .module)
                    }

                    Picker(selection: Binding(
                        get: { store.draftProvider },
                        set: { store.send(.providerChanged($0)) }
                    )) {
                        ForEach(BNPLProvider.allCases) { provider in
                            Label {
                                Text(provider.displayName)
                            } icon: {
                                Image(systemName: provider.symbolName)
                            }
                            .tag(provider)
                        }
                    } label: {
                        Text("bnpl.editor.provider", bundle: .module)
                    }
                }

                Section {
                    TextField(
                        text: Binding(
                            get: { store.draftTotalAmountText },
                            set: { store.send(.totalAmountTextChanged($0)) }
                        ),
                        prompt: Text("bnpl.editor.amount.placeholder", bundle: .module)
                    ) {
                        Text("bnpl.editor.amount", bundle: .module)
                    }
                    .keyboardType(.numberPad)

                    Stepper(
                        value: Binding(
                            get: { store.draftInstallmentCount },
                            set: { store.send(.installmentCountChanged($0)) }
                        ),
                        in: 1 ... 36
                    ) {
                        HStack {
                            Text("bnpl.editor.installmentCount", bundle: .module)
                            Spacer()
                            Text("\(store.draftInstallmentCount)")
                                .foregroundStyle(Color.kaso.textSecondary)
                        }
                    }

                    DatePicker(
                        selection: Binding(
                            get: { store.draftPurchaseDate },
                            set: { store.send(.purchaseDateChanged($0)) }
                        ),
                        displayedComponents: .date
                    ) {
                        Text("bnpl.editor.purchaseDate", bundle: .module)
                    }
                }

                Section {
                    TextField(
                        text: Binding(
                            get: { store.draftNote },
                            set: { store.send(.noteChanged($0)) }
                        ),
                        prompt: Text("bnpl.editor.note.placeholder", bundle: .module),
                        axis: .vertical
                    ) {
                        Text("bnpl.editor.note", bundle: .module)
                    }
                    .lineLimit(3)
                }

                if let errorKey = store.editorErrorMessageKey {
                    Section {
                        Text(LocalizedStringKey(errorKey), bundle: .module)
                            .foregroundStyle(Color.kaso.destructive)
                            .font(Font.kaso.caption)
                    }
                }
            }
            .navigationTitle(
                store.editingObligation == nil
                    ? Text("bnpl.editor.title.add", bundle: .module)
                    : Text("bnpl.editor.title.edit", bundle: .module)
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        store.send(.editorDismissed)
                    } label: {
                        Text("common.cancel", bundle: .module)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        store.send(.saveButtonTapped)
                    } label: {
                        Text("common.save", bundle: .module)
                    }
                }
            }
        }
    }
}
