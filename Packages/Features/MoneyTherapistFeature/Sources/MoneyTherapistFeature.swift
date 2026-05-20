import ComposableArchitecture
import Foundation
import MoneyTherapistDomain

@Reducer
public struct MoneyTherapistFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var reflections: IdentifiedArrayOf<TherapistReflection>
        public var isLoading: Bool
        public var activeTopic: TherapistTopic?
        public var noteText: String
        public var errorMessageKey: String?

        public init(
            reflections: IdentifiedArrayOf<TherapistReflection> = [],
            isLoading: Bool = false,
            activeTopic: TherapistTopic? = nil,
            noteText: String = "",
            errorMessageKey: String? = nil
        ) {
            self.reflections = reflections
            self.isLoading = isLoading
            self.activeTopic = activeTopic
            self.noteText = noteText
            self.errorMessageKey = errorMessageKey
        }

        public var activePrompt: TherapistPrompt? {
            activeTopic.map(TherapistPromptLibrary.prompt(for:))
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case reflectionsLoaded([TherapistReflection])
        case loadFailed(String)
        case topicSelected(TherapistTopic)
        case sheetDismissed
        case noteChanged(String)
        case saveButtonTapped
        case reflectionSaved(TherapistReflection)
        case saveFailed(String)
        case deleteButtonTapped(UUID)
        case reflectionDeleted(UUID)
        case deleteFailed(String)
    }

    @Dependency(\.therapistRepository) private var repository
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
                        let items = try await repository.fetchAll()
                        await send(.reflectionsLoaded(items))
                    } catch {
                        await send(.loadFailed("moneyTherapist.error.loadFailed"))
                    }
                }

            case let .reflectionsLoaded(items):
                state.isLoading = false
                state.reflections = IdentifiedArray(
                    uniqueElements: items.sorted { $0.recordedAt > $1.recordedAt }
                )
                return .none

            case let .loadFailed(messageKey):
                state.isLoading = false
                state.errorMessageKey = messageKey
                return .none

            case let .topicSelected(topic):
                state.activeTopic = topic
                state.noteText = ""
                return .none

            case .sheetDismissed:
                state.activeTopic = nil
                state.noteText = ""
                return .none

            case let .noteChanged(text):
                state.noteText = text
                return .none

            case .saveButtonTapped:
                guard let topic = state.activeTopic else { return .none }
                let note = state.noteText
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let reflection = TherapistReflection(
                    id: uuid(),
                    topic: topic,
                    note: note.isEmpty ? nil : note,
                    recordedAt: date.now
                )
                state.activeTopic = nil
                state.noteText = ""
                return .run { send in
                    do {
                        try await repository.save(reflection)
                        await send(.reflectionSaved(reflection))
                    } catch {
                        await send(.saveFailed("moneyTherapist.error.saveFailed"))
                    }
                }

            case let .reflectionSaved(reflection):
                state.reflections.insert(reflection, at: 0)
                state.reflections = IdentifiedArray(
                    uniqueElements: state.reflections.sorted { $0.recordedAt > $1.recordedAt }
                )
                return .none

            case let .saveFailed(messageKey):
                state.errorMessageKey = messageKey
                return .none

            case let .deleteButtonTapped(id):
                return .run { send in
                    do {
                        try await repository.delete(id)
                        await send(.reflectionDeleted(id))
                    } catch {
                        await send(.deleteFailed("moneyTherapist.error.deleteFailed"))
                    }
                }

            case let .reflectionDeleted(id):
                state.reflections.remove(id: id)
                return .none

            case let .deleteFailed(messageKey):
                state.errorMessageKey = messageKey
                return .none
            }
        }
    }
}
