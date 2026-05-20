import ComposableArchitecture
import GiftTrackerDomain
import KasoDesignSystem
import SwiftUI

struct GiftEditorSheet: View {
    @Bindable var store: StoreOf<GiftTrackerFeature>

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        text: Binding(
                            get: { store.draftPersonName },
                            set: { store.send(.personNameChanged($0)) }
                        ),
                        prompt: Text("gift.editor.personName.placeholder", bundle: .module)
                    ) {
                        Text("gift.editor.personName", bundle: .module)
                    }
                    .autocorrectionDisabled()

                    Picker(selection: Binding(
                        get: { store.draftEventKind },
                        set: { store.send(.eventKindChanged($0)) }
                    )) {
                        ForEach(GiftEventKind.allCases) { kind in
                            Label {
                                Text(LocalizedStringKey(kind.nameKey), bundle: .module)
                            } icon: {
                                Image(systemName: kind.symbolName)
                            }
                            .tag(kind)
                        }
                    } label: {
                        Text("gift.editor.eventKind", bundle: .module)
                    }

                    Picker(selection: Binding(
                        get: { store.draftDirection },
                        set: { store.send(.directionChanged($0)) }
                    )) {
                        ForEach(GiftDirection.allCases, id: \.rawValue) { direction in
                            Text(LocalizedStringKey(direction.nameKey), bundle: .module)
                                .tag(direction)
                        }
                    } label: {
                        Text("gift.editor.direction", bundle: .module)
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    TextField(
                        text: Binding(
                            get: { store.draftAmountText },
                            set: { store.send(.amountTextChanged($0)) }
                        ),
                        prompt: Text("gift.editor.amount.placeholder", bundle: .module)
                    ) {
                        Text("gift.editor.amount", bundle: .module)
                    }
                    .keyboardType(.numberPad)

                    DatePicker(
                        selection: Binding(
                            get: { store.draftEventDate },
                            set: { store.send(.eventDateChanged($0)) }
                        ),
                        displayedComponents: .date
                    ) {
                        Text("gift.editor.date", bundle: .module)
                    }
                }

                Section {
                    TextField(
                        text: Binding(
                            get: { store.draftNote },
                            set: { store.send(.noteChanged($0)) }
                        ),
                        prompt: Text("gift.editor.note.placeholder", bundle: .module),
                        axis: .vertical
                    ) {
                        Text("gift.editor.note", bundle: .module)
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
                store.editingRecord == nil
                    ? Text("gift.editor.title.add", bundle: .module)
                    : Text("gift.editor.title.edit", bundle: .module)
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
