import ComposableArchitecture
import Foundation
import RegretScoreDomain

@Reducer
public struct RegretScoreFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var ratings: IdentifiedArrayOf<RegretRating>
        public var reminders: IdentifiedArrayOf<RegretReminderCandidate>
        public var referenceDate: Date
        public var isLoading: Bool
        public var isEditorPresented: Bool
        public var editingRatingID: UUID?
        public var prefilledFromReminderID: UUID?
        public var titleText: String
        public var categoryText: String
        public var amountText: String
        public var score: RegretScore
        public var purchasedAt: Date
        public var noteText: String
        public var errorMessageKey: String?
        public var editorErrorMessageKey: String?

        public init(
            ratings: IdentifiedArrayOf<RegretRating> = [],
            reminders: IdentifiedArrayOf<RegretReminderCandidate> = [],
            referenceDate: Date = Date(timeIntervalSinceReferenceDate: 0),
            isLoading: Bool = false,
            isEditorPresented: Bool = false,
            editingRatingID: UUID? = nil,
            prefilledFromReminderID: UUID? = nil,
            titleText: String = "",
            categoryText: String = "other",
            amountText: String = "",
            score: RegretScore = .neutral,
            purchasedAt: Date = Date(timeIntervalSinceReferenceDate: 0),
            noteText: String = "",
            errorMessageKey: String? = nil,
            editorErrorMessageKey: String? = nil
        ) {
            self.ratings = ratings
            self.reminders = reminders
            self.referenceDate = referenceDate
            self.isLoading = isLoading
            self.isEditorPresented = isEditorPresented
            self.editingRatingID = editingRatingID
            self.prefilledFromReminderID = prefilledFromReminderID
            self.titleText = titleText
            self.categoryText = categoryText
            self.amountText = amountText
            self.score = score
            self.purchasedAt = purchasedAt
            self.noteText = noteText
            self.errorMessageKey = errorMessageKey
            self.editorErrorMessageKey = editorErrorMessageKey
        }

        public var summary: RegretSummary {
            RegretSummaryBuilder.build(ratings: Array(ratings))
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case dataLoaded(ratings: [RegretRating], reminders: [RegretReminderCandidate])
        case loadFailed(String)
        case addButtonTapped
        case rateReminderTapped(RegretReminderCandidate)
        case editButtonTapped(RegretRating)
        case editorDismissed
        case titleChanged(String)
        case categoryChanged(String)
        case amountChanged(String)
        case scoreChanged(RegretScore)
        case purchasedAtChanged(Date)
        case noteChanged(String)
        case saveButtonTapped
        case ratingSaved(RegretRating)
        case saveFailed(String)
        case deleteButtonTapped(UUID)
        case ratingDeleted(UUID)
        case deleteFailed(String)
        case dismissReminderTapped(UUID)
    }

    @Dependency(\.regretRatingRepository) private var repository
    @Dependency(\.regretReminderContextClient) private var reminderContext
    @Dependency(\.date) private var date
    @Dependency(\.uuid) private var uuid

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.referenceDate = date.now
                state.isLoading = true
                state.errorMessageKey = nil
                return .run { send in
                    do {
                        async let ratings = repository.fetchAll()
                        async let candidates = reminderContext.fetchCandidates()
                        let loadedRatings = try await ratings
                        let inputs = try await candidates
                        let reminders = RegretReminderBuilder.reminders(
                            from: inputs,
                            ratings: loadedRatings,
                            referenceDate: Date()
                        )
                        await send(.dataLoaded(ratings: loadedRatings, reminders: reminders))
                    } catch {
                        await send(.loadFailed("regret.error.loadFailed"))
                    }
                }

            case let .dataLoaded(ratings, reminders):
                state.isLoading = false
                state.ratings = IdentifiedArray(
                    uniqueElements: ratings.sorted { $0.ratedAt > $1.ratedAt }
                )
                state.reminders = IdentifiedArray(uniqueElements: reminders)
                return .none

            case let .loadFailed(messageKey):
                state.isLoading = false
                state.errorMessageKey = messageKey
                return .none

            case .addButtonTapped:
                resetEditor(&state, purchasedAt: date.now)
                state.isEditorPresented = true
                return .none

            case let .rateReminderTapped(candidate):
                state.editingRatingID = nil
                state.prefilledFromReminderID = candidate.id
                state.titleText = candidate.title
                state.categoryText = candidate.category
                state.amountText = candidate.amount.formatted(.number.grouping(.automatic))
                state.score = .neutral
                state.purchasedAt = candidate.occurredAt
                state.noteText = ""
                state.editorErrorMessageKey = nil
                state.isEditorPresented = true
                return .none

            case let .editButtonTapped(rating):
                state.editingRatingID = rating.id
                state.prefilledFromReminderID = nil
                state.titleText = rating.purchaseTitle
                state.categoryText = rating.category
                state.amountText = rating.amount.formatted(.number.grouping(.automatic))
                state.score = rating.score
                state.purchasedAt = rating.purchasedAt
                state.noteText = rating.note ?? ""
                state.editorErrorMessageKey = nil
                state.isEditorPresented = true
                return .none

            case .editorDismissed:
                state.isEditorPresented = false
                return .none

            case let .titleChanged(text):
                state.titleText = text
                state.editorErrorMessageKey = nil
                return .none

            case let .categoryChanged(text):
                state.categoryText = text.isEmpty ? "other" : text
                return .none

            case let .amountChanged(text):
                state.amountText = text
                state.editorErrorMessageKey = nil
                return .none

            case let .scoreChanged(score):
                state.score = score
                return .none

            case let .purchasedAtChanged(value):
                state.purchasedAt = value
                return .none

            case let .noteChanged(text):
                state.noteText = text
                return .none

            case .saveButtonTapped:
                guard let amount = RegretAmountParser.parse(state.amountText), amount > 0 else {
                    state.editorErrorMessageKey = "regret.error.amountMustBePositive"
                    return .none
                }
                let trimmedTitle = state.titleText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmedTitle.isEmpty == false else {
                    state.editorErrorMessageKey = "regret.error.titleRequired"
                    return .none
                }
                let draft = RegretRatingDraft(
                    purchaseTitle: trimmedTitle,
                    category: state.categoryText,
                    amount: amount,
                    score: state.score,
                    note: state.noteText,
                    purchasedAt: state.purchasedAt
                )
                do {
                    let rating: RegretRating
                    if let id = state.editingRatingID, let existing = state.ratings[id: id] {
                        rating = try draft.updating(existing: existing, now: date.now)
                    } else {
                        rating = try draft.validated(id: uuid(), now: date.now)
                    }
                    let dismissedReminderID = state.prefilledFromReminderID
                    state.isEditorPresented = false
                    state.prefilledFromReminderID = nil
                    if let dismissedReminderID {
                        state.reminders.remove(id: dismissedReminderID)
                    }
                    return .run { send in
                        do {
                            try await repository.save(rating)
                            await send(.ratingSaved(rating))
                        } catch {
                            await send(.saveFailed("regret.error.saveFailed"))
                        }
                    }
                } catch let error as RegretRatingValidationError {
                    state.editorErrorMessageKey = error.messageKey
                    return .none
                } catch {
                    state.editorErrorMessageKey = "regret.error.saveFailed"
                    return .none
                }

            case let .ratingSaved(rating):
                state.ratings.remove(id: rating.id)
                state.ratings.insert(rating, at: 0)
                state.ratings = IdentifiedArray(
                    uniqueElements: state.ratings.sorted { $0.ratedAt > $1.ratedAt }
                )
                return .none

            case let .saveFailed(messageKey):
                state.errorMessageKey = messageKey
                return .none

            case let .deleteButtonTapped(id):
                return .run { send in
                    do {
                        try await repository.delete(id)
                        await send(.ratingDeleted(id))
                    } catch {
                        await send(.deleteFailed("regret.error.deleteFailed"))
                    }
                }

            case let .ratingDeleted(id):
                state.ratings.remove(id: id)
                return .none

            case let .deleteFailed(messageKey):
                state.errorMessageKey = messageKey
                return .none

            case let .dismissReminderTapped(id):
                state.reminders.remove(id: id)
                return .none
            }
        }
    }

    private func resetEditor(_ state: inout State, purchasedAt: Date) {
        state.editingRatingID = nil
        state.prefilledFromReminderID = nil
        state.titleText = ""
        state.categoryText = "other"
        state.amountText = ""
        state.score = .neutral
        state.purchasedAt = purchasedAt
        state.noteText = ""
        state.editorErrorMessageKey = nil
    }
}

public enum RegretAmountParser {
    public static func parse(_ text: String) -> Decimal? {
        let cleaned = text
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: " ", with: "")
        if cleaned.isEmpty {
            return nil
        }
        return Decimal(string: cleaned)
    }
}
