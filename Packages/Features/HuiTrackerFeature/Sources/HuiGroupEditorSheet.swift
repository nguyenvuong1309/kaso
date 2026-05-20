import ComposableArchitecture
import HuiTrackerDomain
import KasoDesignSystem
import SwiftUI

struct HuiGroupEditorSheet: View {
    @Bindable var store: StoreOf<HuiTrackerFeature>

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        text: Binding(
                            get: { store.draftName },
                            set: { store.send(.nameChanged($0)) }
                        ),
                        prompt: Text("hui.editor.name.placeholder", bundle: .module)
                    ) {
                        Text("hui.editor.name", bundle: .module)
                    }
                    .autocorrectionDisabled()

                    TextField(
                        text: Binding(
                            get: { store.draftOrganizerName },
                            set: { store.send(.organizerNameChanged($0)) }
                        ),
                        prompt: Text("hui.editor.organizer.placeholder", bundle: .module)
                    ) {
                        Text("hui.editor.organizer", bundle: .module)
                    }
                    .autocorrectionDisabled()
                }

                Section {
                    TextField(
                        text: Binding(
                            get: { store.draftContributionText },
                            set: { store.send(.contributionTextChanged($0)) }
                        ),
                        prompt: Text("hui.editor.contribution.placeholder", bundle: .module)
                    ) {
                        Text("hui.editor.contribution", bundle: .module)
                    }
                    .keyboardType(.numberPad)

                    TextField(
                        text: Binding(
                            get: { store.draftMemberCountText },
                            set: { store.send(.memberCountTextChanged($0)) }
                        ),
                        prompt: Text("hui.editor.memberCount.placeholder", bundle: .module)
                    ) {
                        Text("hui.editor.memberCount", bundle: .module)
                    }
                    .keyboardType(.numberPad)

                    Picker(selection: Binding(
                        get: { store.draftPeriodKind },
                        set: { store.send(.periodKindChanged($0)) }
                    )) {
                        ForEach(HuiPeriodKind.allCases) { kind in
                            Text(LocalizedStringKey(kind.nameKey), bundle: .module)
                                .tag(kind)
                        }
                    } label: {
                        Text("hui.editor.period", bundle: .module)
                    }

                    DatePicker(
                        selection: Binding(
                            get: { store.draftStartDate },
                            set: { store.send(.startDateChanged($0)) }
                        ),
                        displayedComponents: .date
                    ) {
                        Text("hui.editor.startDate", bundle: .module)
                    }
                }

                Section {
                    TextField(
                        text: Binding(
                            get: { store.draftNote },
                            set: { store.send(.noteChanged($0)) }
                        ),
                        prompt: Text("hui.editor.note.placeholder", bundle: .module),
                        axis: .vertical
                    ) {
                        Text("hui.editor.note", bundle: .module)
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
                store.editingGroup == nil
                    ? Text("hui.editor.title.add", bundle: .module)
                    : Text("hui.editor.title.edit", bundle: .module)
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
