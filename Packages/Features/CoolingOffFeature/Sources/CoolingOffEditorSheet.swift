import ComposableArchitecture
import CoolingOffDomain
import KasoDesignSystem
import SwiftUI

struct CoolingOffEditorSheet: View {
    @Bindable var store: StoreOf<CoolingOffFeature>

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        "coolingOff.editor.titlePlaceholder",
                        text: $store.titleText.sending(\.titleTextChanged)
                    )
                    TextField(
                        "coolingOff.editor.amountPlaceholder",
                        text: $store.amountText.sending(\.amountTextChanged)
                    )
                    .keyboardType(.decimalPad)
                    Picker(
                        selection: $store.category.sending(\.categoryChanged)
                    ) {
                        ForEach(PurchasePlanCategory.allCases) { category in
                            Text(LocalizedStringKey(category.nameKey), bundle: .module)
                                .tag(category)
                        }
                    } label: {
                        Text("coolingOff.editor.category", bundle: .module)
                    }
                } header: {
                    Text("coolingOff.editor.purchase", bundle: .module)
                }

                Section {
                    Picker(
                        selection: $store.coolingPeriod.sending(\.coolingPeriodChanged)
                    ) {
                        ForEach(CoolingPeriod.allCases) { period in
                            Text(LocalizedStringKey(period.nameKey), bundle: .module)
                                .tag(period)
                        }
                    } label: {
                        Text("coolingOff.editor.period", bundle: .module)
                    }

                    if store.coolingPeriodOverride {
                        Button {
                            store.send(.useSuggestedPeriodTapped)
                        } label: {
                            Label {
                                Text("coolingOff.editor.useSuggested", bundle: .module)
                            } icon: {
                                Image(systemName: "wand.and.stars")
                            }
                        }
                    }
                } header: {
                    Text("coolingOff.editor.periodHeader", bundle: .module)
                } footer: {
                    Text("coolingOff.editor.periodFooter", bundle: .module)
                }

                Section {
                    TextField(
                        "coolingOff.editor.notePlaceholder",
                        text: $store.noteText.sending(\.noteTextChanged),
                        axis: .vertical
                    )
                    .lineLimit(3, reservesSpace: true)
                } header: {
                    Text("coolingOff.editor.note", bundle: .module)
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
                        store.send(.editorDismissed)
                    } label: {
                        Text("coolingOff.cancel", bundle: .module)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        store.send(.saveButtonTapped)
                    } label: {
                        Text("coolingOff.save", bundle: .module)
                    }
                }
            }
        }
    }

    private var editorTitle: Text {
        store.editingPlanID == nil
            ? Text("coolingOff.editor.titleNew", bundle: .module)
            : Text("coolingOff.editor.titleEdit", bundle: .module)
    }
}
