import ComposableArchitecture
import KasoDesignSystem
import RegretScoreDomain
import SwiftUI

struct RegretEditorSheet: View {
    @Bindable var store: StoreOf<RegretScoreFeature>

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        "regret.editor.titlePlaceholder",
                        text: $store.titleText.sending(\.titleChanged)
                    )
                    TextField(
                        "regret.editor.amountPlaceholder",
                        text: $store.amountText.sending(\.amountChanged)
                    )
                    .keyboardType(.decimalPad)
                    TextField(
                        "regret.editor.categoryPlaceholder",
                        text: $store.categoryText.sending(\.categoryChanged)
                    )
                    DatePicker(
                        "regret.editor.purchasedAt",
                        selection: $store.purchasedAt.sending(\.purchasedAtChanged),
                        displayedComponents: [.date]
                    )
                } header: {
                    Text("regret.editor.purchaseHeader", bundle: .module)
                }

                Section {
                    Picker(
                        selection: $store.score.sending(\.scoreChanged)
                    ) {
                        ForEach(RegretScore.allCases, id: \.rawValue) { score in
                            HStack {
                                Image(systemName: score.symbolName)
                                Text(LocalizedStringKey(score.nameKey), bundle: .module)
                            }
                            .tag(score)
                        }
                    } label: {
                        Text("regret.editor.score", bundle: .module)
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("regret.editor.scoreHeader", bundle: .module)
                }

                Section {
                    TextField(
                        "regret.editor.notePlaceholder",
                        text: $store.noteText.sending(\.noteChanged),
                        axis: .vertical
                    )
                    .lineLimit(3, reservesSpace: true)
                } header: {
                    Text("regret.editor.noteHeader", bundle: .module)
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
                        Text("regret.cancel", bundle: .module)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        store.send(.saveButtonTapped)
                    } label: {
                        Text("regret.save", bundle: .module)
                    }
                }
            }
        }
    }

    private var editorTitle: Text {
        store.editingRatingID == nil
            ? Text("regret.editor.titleNew", bundle: .module)
            : Text("regret.editor.titleEdit", bundle: .module)
    }
}
