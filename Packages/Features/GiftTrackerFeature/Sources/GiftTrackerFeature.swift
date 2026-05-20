import ComposableArchitecture
import Foundation
import GiftTrackerDomain

@Reducer
public struct GiftTrackerFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var records: IdentifiedArrayOf<GiftRecord>
        public var personSummaries: [GiftPersonSummary]
        public var yearlySummary: GiftYearlySummary
        public var isLoading: Bool
        public var isEditorPresented: Bool
        public var editingRecord: GiftRecord?
        public var selectedPersonName: String?
        public var draftPersonName: String
        public var draftEventKind: GiftEventKind
        public var draftDirection: GiftDirection
        public var draftAmountText: String
        public var draftEventDate: Date
        public var draftNote: String
        public var errorMessageKey: String?
        public var editorErrorMessageKey: String?

        public var filteredPersonRecords: [GiftRecord] {
            guard let name = selectedPersonName else { return [] }
            return records.filter { $0.personName == name }
                .sorted { $0.eventDate > $1.eventDate }
        }

        public init(
            records: IdentifiedArrayOf<GiftRecord> = [],
            personSummaries: [GiftPersonSummary] = [],
            yearlySummary: GiftYearlySummary = .init(year: 0, totalGiven: 0, totalReceived: 0, recordCount: 0),
            isLoading: Bool = false,
            isEditorPresented: Bool = false,
            editingRecord: GiftRecord? = nil,
            selectedPersonName: String? = nil,
            draftPersonName: String = "",
            draftEventKind: GiftEventKind = .tet,
            draftDirection: GiftDirection = .given,
            draftAmountText: String = "",
            draftEventDate: Date = Date(timeIntervalSinceReferenceDate: 0),
            draftNote: String = "",
            errorMessageKey: String? = nil,
            editorErrorMessageKey: String? = nil
        ) {
            self.records = records
            self.personSummaries = personSummaries
            self.yearlySummary = yearlySummary
            self.isLoading = isLoading
            self.isEditorPresented = isEditorPresented
            self.editingRecord = editingRecord
            self.selectedPersonName = selectedPersonName
            self.draftPersonName = draftPersonName
            self.draftEventKind = draftEventKind
            self.draftDirection = draftDirection
            self.draftAmountText = draftAmountText
            self.draftEventDate = draftEventDate
            self.draftNote = draftNote
            self.errorMessageKey = errorMessageKey
            self.editorErrorMessageKey = editorErrorMessageKey
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case recordsLoaded([GiftRecord])
        case loadFailed(String)
        case addButtonTapped
        case editButtonTapped(GiftRecord)
        case editorDismissed
        case personNameChanged(String)
        case eventKindChanged(GiftEventKind)
        case directionChanged(GiftDirection)
        case amountTextChanged(String)
        case eventDateChanged(Date)
        case noteChanged(String)
        case saveButtonTapped
        case recordSaved(GiftRecord)
        case saveFailed(String)
        case deleteButtonTapped(UUID)
        case recordDeleted(UUID)
        case deleteFailed(String)
        case personSelected(String)
        case personDeselected
    }

    @Dependency(\.giftTrackerRepository) private var repository
    @Dependency(\.date.now) private var now
    @Dependency(\.uuid) private var uuid

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                return .run { send in
                    do {
                        let records = try await repository.fetchAll()
                        await send(.recordsLoaded(records))
                    } catch {
                        await send(.loadFailed("gift.error.loadFailed"))
                    }
                }

            case let .recordsLoaded(records):
                state.isLoading = false
                state.records = IdentifiedArray(uniqueElements: records)
                refreshSummaries(&state)
                return .none

            case let .loadFailed(key):
                state.isLoading = false
                state.errorMessageKey = key
                return .none

            case .addButtonTapped:
                state.editingRecord = nil
                state.draftPersonName = ""
                state.draftEventKind = .tet
                state.draftDirection = .given
                state.draftAmountText = ""
                state.draftEventDate = now
                state.draftNote = ""
                state.editorErrorMessageKey = nil
                state.isEditorPresented = true
                return .none

            case let .editButtonTapped(record):
                state.editingRecord = record
                state.draftPersonName = record.personName
                state.draftEventKind = record.eventKind
                state.draftDirection = record.direction
                state.draftAmountText = record.amount.description
                state.draftEventDate = record.eventDate
                state.draftNote = record.note ?? ""
                state.editorErrorMessageKey = nil
                state.isEditorPresented = true
                return .none

            case .editorDismissed:
                state.isEditorPresented = false
                state.editorErrorMessageKey = nil
                return .none

            case let .personNameChanged(name):
                state.draftPersonName = name
                state.editorErrorMessageKey = nil
                return .none

            case let .eventKindChanged(kind):
                state.draftEventKind = kind
                return .none

            case let .directionChanged(direction):
                state.draftDirection = direction
                return .none

            case let .amountTextChanged(text):
                state.draftAmountText = text
                state.editorErrorMessageKey = nil
                return .none

            case let .eventDateChanged(date):
                state.draftEventDate = date
                return .none

            case let .noteChanged(note):
                state.draftNote = note
                return .none

            case .saveButtonTapped:
                let name = state.draftPersonName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard name.isEmpty == false else {
                    state.editorErrorMessageKey = "gift.error.nameRequired"
                    return .none
                }
                guard let amount = Decimal(string: state.draftAmountText.replacingOccurrences(of: ".", with: ""), locale: nil),
                      amount > 0 else {
                    state.editorErrorMessageKey = "gift.error.invalidAmount"
                    return .none
                }
                let note = state.draftNote.trimmingCharacters(in: .whitespacesAndNewlines)
                let record = GiftRecord(
                    id: state.editingRecord?.id ?? uuid(),
                    personName: name,
                    eventKind: state.draftEventKind,
                    direction: state.draftDirection,
                    amount: amount,
                    eventDate: state.draftEventDate,
                    note: note.isEmpty ? nil : note
                )
                return .run { send in
                    do {
                        try await repository.save(record)
                        await send(.recordSaved(record))
                    } catch {
                        await send(.saveFailed("gift.error.saveFailed"))
                    }
                }

            case let .recordSaved(record):
                state.isEditorPresented = false
                state.records.updateOrAppend(record)
                refreshSummaries(&state)
                return .none

            case let .saveFailed(key):
                state.editorErrorMessageKey = key
                return .none

            case let .deleteButtonTapped(id):
                return .run { send in
                    do {
                        try await repository.delete(id)
                        await send(.recordDeleted(id))
                    } catch {
                        await send(.deleteFailed("gift.error.deleteFailed"))
                    }
                }

            case let .recordDeleted(id):
                state.records.remove(id: id)
                refreshSummaries(&state)
                return .none

            case let .deleteFailed(key):
                state.errorMessageKey = key
                return .none

            case let .personSelected(name):
                state.selectedPersonName = name
                return .none

            case .personDeselected:
                state.selectedPersonName = nil
                return .none
            }
        }
    }

    private func refreshSummaries(_ state: inout State) {
        let allRecords = Array(state.records)
        state.personSummaries = GiftPersonSummaryBuilder.build(from: allRecords)
        state.yearlySummary = GiftYearlySummaryBuilder.build(from: allRecords)
    }
}
