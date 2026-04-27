import SwiftUI
import ComposableArchitecture
import KasoDesignSystem
import PhantomExpenseDomain

struct PhantomExpenseEditorSheet: View {
    @Bindable var store: StoreOf<PhantomExpenseFeature>

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(text: $store.titleText.sending(\.titleTextChanged)) {
                        Text("phantom.titleField", bundle: .module)
                    }

                    TextField(text: $store.amountText.sending(\.amountTextChanged)) {
                        Text("phantom.amountField", bundle: .module)
                    }

                    Picker(selection: $store.category.sending(\.categoryChanged)) {
                        ForEach(PhantomExpenseCategory.allCases) { category in
                            Label {
                                Text(LocalizedStringKey(category.nameKey), bundle: .module)
                            } icon: {
                                Image(systemName: category.symbolName)
                            }
                            .tag(category)
                        }
                    } label: {
                        Text("phantom.categoryField", bundle: .module)
                    }

                    DatePicker(
                        selection: $store.avoidedAt.sending(\.avoidedAtChanged),
                        displayedComponents: .date
                    ) {
                        Text("phantom.dateField", bundle: .module)
                    }

                    TextField(
                        text: $store.noteText.sending(\.noteTextChanged),
                        axis: .vertical
                    ) {
                        Text("phantom.noteField", bundle: .module)
                    }
                }

                if let errorMessageKey = store.editorErrorMessageKey {
                    PhantomExpenseEditorErrorLabel(messageKey: errorMessageKey)
                }
            }
            .navigationTitle(Text("phantom.editor.title", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        store.send(.editorDismissed)
                    } label: {
                        Text("phantom.cancel", bundle: .module)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        store.send(.saveButtonTapped)
                    } label: {
                        if store.isSaving {
                            ProgressView()
                        } else {
                            Text("phantom.save", bundle: .module)
                        }
                    }
                    .disabled(store.isSaving)
                }
            }
        }
    }
}

private struct PhantomExpenseEditorErrorLabel: View {
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
