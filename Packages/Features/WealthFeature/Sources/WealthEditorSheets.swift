import SwiftUI
import ComposableArchitecture
import KasoDesignSystem
import WealthDomain

struct AssetEditorSheet: View {
    @Bindable var store: StoreOf<WealthFeature>

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        text: $store.assetNameText.sending(\.assetNameTextChanged)
                    ) {
                        Text("wealth.asset.name", bundle: .module)
                    }

                    TextField(
                        text: $store.assetValueText.sending(\.assetValueTextChanged)
                    ) {
                        Text("wealth.asset.value", bundle: .module)
                    }

                    Picker(
                        selection: $store.assetType.sending(\.assetTypeChanged)
                    ) {
                        ForEach(AssetType.allCases) { type in
                            Label {
                                Text(LocalizedStringKey(type.nameKey), bundle: .module)
                            } icon: {
                                Image(systemName: type.symbolName)
                            }
                            .tag(type)
                        }
                    } label: {
                        Text("wealth.asset.type", bundle: .module)
                    }

                    TextField(
                        text: $store.assetNoteText.sending(\.assetNoteTextChanged),
                        axis: .vertical
                    ) {
                        Text("wealth.note", bundle: .module)
                    }
                }

                if let errorMessageKey = store.assetEditorErrorMessageKey {
                    WealthEditorErrorLabel(messageKey: errorMessageKey)
                }
            }
            .navigationTitle(Text("wealth.asset.editor.title", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        store.send(.assetEditorDismissed)
                    } label: {
                        Text("wealth.cancel", bundle: .module)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        store.send(.assetSaveButtonTapped)
                    } label: {
                        if store.isAssetSaving {
                            ProgressView()
                        } else {
                            Text("wealth.save", bundle: .module)
                        }
                    }
                    .disabled(store.isAssetSaving)
                }
            }
        }
    }
}

struct LiabilityEditorSheet: View {
    @Bindable var store: StoreOf<WealthFeature>

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        text: $store.liabilityNameText.sending(\.liabilityNameTextChanged)
                    ) {
                        Text("wealth.liability.name", bundle: .module)
                    }

                    TextField(
                        text: $store.liabilityValueText.sending(\.liabilityValueTextChanged)
                    ) {
                        Text("wealth.liability.value", bundle: .module)
                    }

                    Picker(
                        selection: $store.liabilityType.sending(\.liabilityTypeChanged)
                    ) {
                        ForEach(LiabilityType.allCases) { type in
                            Label {
                                Text(LocalizedStringKey(type.nameKey), bundle: .module)
                            } icon: {
                                Image(systemName: type.symbolName)
                            }
                            .tag(type)
                        }
                    } label: {
                        Text("wealth.liability.type", bundle: .module)
                    }

                    TextField(
                        text: $store.liabilityNoteText.sending(\.liabilityNoteTextChanged),
                        axis: .vertical
                    ) {
                        Text("wealth.note", bundle: .module)
                    }
                }

                if let errorMessageKey = store.liabilityEditorErrorMessageKey {
                    WealthEditorErrorLabel(messageKey: errorMessageKey)
                }
            }
            .navigationTitle(Text("wealth.liability.editor.title", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        store.send(.liabilityEditorDismissed)
                    } label: {
                        Text("wealth.cancel", bundle: .module)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        store.send(.liabilitySaveButtonTapped)
                    } label: {
                        if store.isLiabilitySaving {
                            ProgressView()
                        } else {
                            Text("wealth.save", bundle: .module)
                        }
                    }
                    .disabled(store.isLiabilitySaving)
                }
            }
        }
    }
}

private struct WealthEditorErrorLabel: View {
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
