import ComposableArchitecture
import KasoDesignSystem
import MoodJournalDomain
import SwiftUI

struct MoodJournalEditorSheet: View {
    @Bindable var store: StoreOf<MoodJournalFeature>

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(
                        selection: $store.selectedMood.sending(\.moodChanged)
                    ) {
                        ForEach(Mood.allCases) { mood in
                            HStack {
                                Text(mood.emoji)
                                Text(LocalizedStringKey(mood.nameKey), bundle: .module)
                            }
                            .tag(mood)
                        }
                    } label: {
                        Text("moodJournal.editor.mood", bundle: .module)
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("moodJournal.editor.moodHeader", bundle: .module)
                }

                Section {
                    TextField(
                        "moodJournal.editor.spendingPlaceholder",
                        text: $store.spendingTotalText.sending(\.spendingTotalChanged)
                    )
                    .keyboardType(.decimalPad)
                } header: {
                    Text("moodJournal.editor.spendingHeader", bundle: .module)
                } footer: {
                    Text("moodJournal.editor.spendingFooter", bundle: .module)
                }

                Section {
                    TextField(
                        "moodJournal.editor.notePlaceholder",
                        text: $store.noteText.sending(\.noteChanged),
                        axis: .vertical
                    )
                    .lineLimit(3, reservesSpace: true)
                } header: {
                    Text("moodJournal.editor.noteHeader", bundle: .module)
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
                        Text("moodJournal.cancel", bundle: .module)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        store.send(.saveButtonTapped)
                    } label: {
                        Text("moodJournal.save", bundle: .module)
                    }
                }
            }
        }
    }

    private var editorTitle: Text {
        store.editingEntryID == nil
            ? Text("moodJournal.editor.titleNew", bundle: .module)
            : Text("moodJournal.editor.titleEdit", bundle: .module)
    }
}
