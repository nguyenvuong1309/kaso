import ComposableArchitecture
import Foundation
import SpendingMapDomain

@Reducer
public struct SpendingMapFeature: Sendable {
    /// Default centre when no entries exist yet — central Saigon to match the
    /// most common Vietnamese user. Users in other cities can pan freely.
    public static let defaultLatitude: Double = 10.7769
    public static let defaultLongitude: Double = 106.7009

    @ObservableState
    public struct State: Equatable {
        public var entries: IdentifiedArrayOf<SpendingMapEntry>
        public var summary: SpendingMapSummary
        public var period: SpendingMapPeriod
        public var isLoading: Bool
        public var isEditorPresented: Bool
        public var editingEntry: SpendingMapEntry?
        public var draftLabel: String
        public var draftAmountText: String
        public var draftCategoryID: String
        public var draftLatitude: Double
        public var draftLongitude: Double
        public var draftOccurredAt: Date
        public var draftNote: String
        public var errorMessageKey: String?
        public var editorErrorMessageKey: String?

        public init(
            entries: IdentifiedArrayOf<SpendingMapEntry> = [],
            summary: SpendingMapSummary = .empty,
            period: SpendingMapPeriod = .last30Days,
            isLoading: Bool = false,
            isEditorPresented: Bool = false,
            editingEntry: SpendingMapEntry? = nil,
            draftLabel: String = "",
            draftAmountText: String = "",
            draftCategoryID: String = "",
            draftLatitude: Double = defaultLatitude,
            draftLongitude: Double = defaultLongitude,
            draftOccurredAt: Date = Date(timeIntervalSinceReferenceDate: 0),
            draftNote: String = "",
            errorMessageKey: String? = nil,
            editorErrorMessageKey: String? = nil
        ) {
            self.entries = entries
            self.summary = summary
            self.period = period
            self.isLoading = isLoading
            self.isEditorPresented = isEditorPresented
            self.editingEntry = editingEntry
            self.draftLabel = draftLabel
            self.draftAmountText = draftAmountText
            self.draftCategoryID = draftCategoryID
            self.draftLatitude = draftLatitude
            self.draftLongitude = draftLongitude
            self.draftOccurredAt = draftOccurredAt
            self.draftNote = draftNote
            self.errorMessageKey = errorMessageKey
            self.editorErrorMessageKey = editorErrorMessageKey
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case entriesLoaded([SpendingMapEntry])
        case loadFailed(String)
        case periodChanged(SpendingMapPeriod)
        case addButtonTapped
        case editButtonTapped(SpendingMapEntry)
        case editorDismissed
        case labelChanged(String)
        case amountTextChanged(String)
        case categoryChanged(String)
        case coordinateChanged(latitude: Double, longitude: Double)
        case occurredAtChanged(Date)
        case noteChanged(String)
        case saveButtonTapped
        case entrySaved(SpendingMapEntry)
        case saveFailed(String)
        case deleteButtonTapped(UUID)
        case entryDeleted(UUID)
        case deleteFailed(String)
    }

    @Dependency(\.spendingMapRepository) private var repository
    @Dependency(\.date.now) private var now
    @Dependency(\.uuid) private var uuid

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                state.errorMessageKey = nil
                return .run { [period = state.period, referenceDate = now] send in
                    do {
                        let entries = try await repository.fetchAll()
                        await send(.entriesLoaded(entries))
                        _ = (period, referenceDate)
                    } catch {
                        await send(.loadFailed("spendingMap.error.loadFailed"))
                    }
                }

            case let .entriesLoaded(entries):
                state.isLoading = false
                state.entries = IdentifiedArray(uniqueElements: entries)
                refreshSummary(&state)
                return .none

            case let .loadFailed(key):
                state.isLoading = false
                state.errorMessageKey = key
                return .none

            case let .periodChanged(period):
                state.period = period
                refreshSummary(&state)
                return .none

            case .addButtonTapped:
                state.editingEntry = nil
                state.draftLabel = ""
                state.draftAmountText = ""
                state.draftCategoryID = ""
                state.draftLatitude = Self.defaultLatitude
                state.draftLongitude = Self.defaultLongitude
                state.draftOccurredAt = now
                state.draftNote = ""
                state.editorErrorMessageKey = nil
                state.isEditorPresented = true
                return .none

            case let .editButtonTapped(entry):
                state.editingEntry = entry
                state.draftLabel = entry.label
                state.draftAmountText = NSDecimalNumber(decimal: entry.amount).stringValue
                state.draftCategoryID = entry.categoryID ?? ""
                state.draftLatitude = entry.latitude
                state.draftLongitude = entry.longitude
                state.draftOccurredAt = entry.occurredAt
                state.draftNote = entry.note ?? ""
                state.editorErrorMessageKey = nil
                state.isEditorPresented = true
                return .none

            case .editorDismissed:
                state.isEditorPresented = false
                state.editorErrorMessageKey = nil
                return .none

            case let .labelChanged(text):
                state.draftLabel = text
                state.editorErrorMessageKey = nil
                return .none

            case let .amountTextChanged(text):
                state.draftAmountText = text
                state.editorErrorMessageKey = nil
                return .none

            case let .categoryChanged(text):
                state.draftCategoryID = text
                return .none

            case let .coordinateChanged(latitude, longitude):
                state.draftLatitude = latitude
                state.draftLongitude = longitude
                return .none

            case let .occurredAtChanged(date):
                state.draftOccurredAt = date
                return .none

            case let .noteChanged(note):
                state.draftNote = note
                return .none

            case .saveButtonTapped:
                let label = state.draftLabel.trimmingCharacters(in: .whitespacesAndNewlines)
                guard label.isEmpty == false else {
                    state.editorErrorMessageKey = "spendingMap.error.labelRequired"
                    return .none
                }
                let sanitizedAmount = state.draftAmountText
                    .replacingOccurrences(of: ".", with: "")
                    .replacingOccurrences(of: ",", with: "")
                guard let amount = Decimal(string: sanitizedAmount, locale: nil), amount > 0 else {
                    state.editorErrorMessageKey = "spendingMap.error.invalidAmount"
                    return .none
                }
                let trimmedCategory = state.draftCategoryID.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedNote = state.draftNote.trimmingCharacters(in: .whitespacesAndNewlines)
                let entry = SpendingMapEntry(
                    id: state.editingEntry?.id ?? uuid(),
                    label: label,
                    amount: amount,
                    categoryID: trimmedCategory.isEmpty ? nil : trimmedCategory,
                    latitude: state.draftLatitude,
                    longitude: state.draftLongitude,
                    occurredAt: state.draftOccurredAt,
                    note: trimmedNote.isEmpty ? nil : trimmedNote
                )
                return .run { send in
                    do {
                        try await repository.save(entry)
                        await send(.entrySaved(entry))
                    } catch {
                        await send(.saveFailed("spendingMap.error.saveFailed"))
                    }
                }

            case let .entrySaved(entry):
                state.isEditorPresented = false
                state.entries.updateOrAppend(entry)
                refreshSummary(&state)
                return .none

            case let .saveFailed(key):
                state.editorErrorMessageKey = key
                return .none

            case let .deleteButtonTapped(id):
                return .run { send in
                    do {
                        try await repository.delete(id)
                        await send(.entryDeleted(id))
                    } catch {
                        await send(.deleteFailed("spendingMap.error.deleteFailed"))
                    }
                }

            case let .entryDeleted(id):
                state.entries.remove(id: id)
                refreshSummary(&state)
                return .none

            case let .deleteFailed(key):
                state.errorMessageKey = key
                return .none
            }
        }
    }

    private func refreshSummary(_ state: inout State) {
        state.summary = SpendingMapBuilder.build(
            entries: Array(state.entries),
            period: state.period,
            referenceDate: now
        )
    }
}
