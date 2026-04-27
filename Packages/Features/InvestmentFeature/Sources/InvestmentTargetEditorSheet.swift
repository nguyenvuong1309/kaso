import SwiftUI
import ComposableArchitecture
import InvestmentDomain
import KasoDesignSystem

struct InvestmentTargetEditorSheet: View {
    @Bindable var store: StoreOf<InvestmentFeature>

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("investment.target.description", bundle: .module)
                        .font(.kaso.body)
                        .foregroundStyle(Color.kaso.textSecondary)
                }

                Section {
                    ForEach(AssetClass.allCases) { assetClass in
                        TextField(
                            text: targetBinding(for: assetClass)
                        ) {
                            Text(LocalizedStringKey(assetClass.nameKey), bundle: .module)
                        }
                    }
                } header: {
                    Text("investment.target.percentHeader", bundle: .module)
                }

                if let errorMessageKey = store.targetEditorErrorMessageKey {
                    InvestmentEditorErrorLabel(messageKey: errorMessageKey)
                }
            }
            .navigationTitle(Text("investment.target.editor.title", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        store.send(.targetEditorDismissed)
                    } label: {
                        Text("investment.cancel", bundle: .module)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        store.send(.targetSaveButtonTapped)
                    } label: {
                        if store.isTargetSaving {
                            ProgressView()
                        } else {
                            Text("investment.save", bundle: .module)
                        }
                    }
                    .disabled(store.isTargetSaving)
                }
            }
        }
    }

    private func targetBinding(for assetClass: AssetClass) -> Binding<String> {
        Binding(
            get: { store.targetPercentTexts[assetClass] ?? "" },
            set: { text in
                store.send(.targetPercentTextChanged(assetClass, text))
            }
        )
    }
}
