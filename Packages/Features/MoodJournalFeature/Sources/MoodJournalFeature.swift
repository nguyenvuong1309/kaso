import ComposableArchitecture
import Foundation
import MoodJournalDomain

@Reducer
public struct MoodJournalFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var entries: IdentifiedArrayOf<MoodEntry>
        public var isLoading: Bool
        public var isEditorPresented: Bool
        public var editingEntryID: UUID?
        public var selectedMood: Mood
        public var spendingTotalText: String
        public var noteText: String
        public var errorMessageKey: String?
        public var editorErrorMessageKey: String?

        public init(
            entries: IdentifiedArrayOf<MoodEntry> = [],
            isLoading: Bool = false,
            isEditorPresented: Bool = false,
            editingEntryID: UUID? = nil,
            selectedMood: Mood = .neutral,
            spendingTotalText: String = "",
            noteText: String = "",
            errorMessageKey: String? = nil,
            editorErrorMessageKey: String? = nil
        ) {
            self.entries = entries
            self.isLoading = isLoading
            self.isEditorPresented = isEditorPresented
            self.editingEntryID = editingEntryID
            self.selectedMood = selectedMood
            self.spendingTotalText = spendingTotalText
            self.noteText = noteText
            self.errorMessageKey = errorMessageKey
            self.editorErrorMessageKey = editorErrorMessageKey
        }

        public var insight: MoodInsight {
            MoodInsightCalculator.insight(from: Array(entries))
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case entriesLoaded([MoodEntry])
        case loadFailed(String)
        case addButtonTapped
        case editButtonTapped(MoodEntry)
        case editorDismissed
        case moodChanged(Mood)
        case spendingTotalChanged(String)
        case noteChanged(String)
        case saveButtonTapped
        case entrySaved(MoodEntry)
        case saveFailed(String)
        case deleteButtonTapped(UUID)
        case entryDeleted(UUID)
        case deleteFailed(String)
    }

    @Dependency(\.moodJournalRepository) private var repository
    @Dependency(\.date) private var date
    @Dependency(\.uuid) private var uuid

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                state.errorMessageKey = nil
                return .run { send in
                    do {
                        let entries = try await repository.fetchAll()
                        await send(.entriesLoaded(entries))
                    } catch {
                        await send(.loadFailed("moodJournal.error.loadFailed"))
                    }
                }

            case let .entriesLoaded(entries):
                state.isLoading = false
                state.entries = IdentifiedArray(
                    uniqueElements: entries.sorted { $0.recordedAt > $1.recordedAt }
                )
                return .none

            case let .loadFailed(messageKey):
                state.isLoading = false
                state.errorMessageKey = messageKey
                return .none

            case .addButtonTapped:
                state.editingEntryID = nil
                state.selectedMood = .neutral
                state.spendingTotalText = ""
                state.noteText = ""
                state.editorErrorMessageKey = nil
                state.isEditorPresented = true
                return .none

            case let .editButtonTapped(entry):
                state.editingEntryID = entry.id
                state.selectedMood = entry.mood
                state.spendingTotalText = entry.spendingTotalSnapshot > 0
                    ? entry.spendingTotalSnapshot.formatted(.number.grouping(.automatic))
                    : ""
                state.noteText = entry.note ?? ""
                state.editorErrorMessageKey = nil
                state.isEditorPresented = true
                return .none

            case .editorDismissed:
                state.isEditorPresented = false
                return .none

            case let .moodChanged(mood):
                state.selectedMood = mood
                state.editorErrorMessageKey = nil
                return .none

            case let .spendingTotalChanged(text):
                state.spendingTotalText = text
                state.editorErrorMessageKey = nil
                return .none

            case let .noteChanged(text):
                state.noteText = text
                return .none

            case .saveButtonTapped:
                let spending = MoodAmountParser.parse(state.spendingTotalText) ?? 0
                if spending < 0 {
                    state.editorErrorMessageKey = "moodJournal.error.invalidAmount"
                    return .none
                }
                let note = state.noteText.trimmingCharacters(in: .whitespacesAndNewlines)
                let entry: MoodEntry = {
                    if let id = state.editingEntryID, var existing = state.entries[id: id] {
                        existing.mood = state.selectedMood
                        existing.spendingTotalSnapshot = spending
                        existing.note = note.isEmpty ? nil : note
                        return existing
                    } else {
                        return MoodEntry(
                            id: uuid(),
                            mood: state.selectedMood,
                            spendingTotalSnapshot: spending,
                            note: note.isEmpty ? nil : note,
                            recordedAt: date.now
                        )
                    }
                }()
                state.isEditorPresented = false
                return .run { send in
                    do {
                        try await repository.save(entry)
                        await send(.entrySaved(entry))
                    } catch {
                        await send(.saveFailed("moodJournal.error.saveFailed"))
                    }
                }

            case let .entrySaved(entry):
                state.entries.remove(id: entry.id)
                state.entries.insert(entry, at: 0)
                state.entries = IdentifiedArray(
                    uniqueElements: state.entries.sorted { $0.recordedAt > $1.recordedAt }
                )
                return .none

            case let .saveFailed(messageKey):
                state.errorMessageKey = messageKey
                return .none

            case let .deleteButtonTapped(id):
                return .run { send in
                    do {
                        try await repository.delete(id)
                        await send(.entryDeleted(id))
                    } catch {
                        await send(.deleteFailed("moodJournal.error.deleteFailed"))
                    }
                }

            case let .entryDeleted(id):
                state.entries.remove(id: id)
                return .none

            case let .deleteFailed(messageKey):
                state.errorMessageKey = messageKey
                return .none
            }
        }
    }
}

public enum MoodAmountParser {
    public static func parse(_ text: String) -> Decimal? {
        let cleaned = text
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: " ", with: "")
        if cleaned.isEmpty {
            return 0
        }
        return Decimal(string: cleaned)
    }
}
