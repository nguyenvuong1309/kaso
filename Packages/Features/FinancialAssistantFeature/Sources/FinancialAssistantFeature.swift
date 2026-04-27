import Foundation
import ComposableArchitecture
import InsightDomain

public enum FinancialAssistantSuggestedPrompt: String, CaseIterable, Identifiable, Equatable, Sendable {
    case monthStatus
    case cutTwoMillion
    case affordTrip
    case topCategory

    public var id: String {
        rawValue
    }

    public var titleKey: String {
        "assistant.prompt.\(rawValue)"
    }

    public var defaultQuestion: String {
        switch self {
        case .monthStatus:
            "Tháng này tôi còn bao nhiêu tiền?"
        case .cutTwoMillion:
            "Tôi nên cắt khoản nào để tiết kiệm thêm 2 triệu?"
        case .affordTrip:
            "Tôi còn đủ tiền đi du lịch 5 triệu không?"
        case .topCategory:
            "Tháng này tôi chi nhiều nhất vào danh mục nào?"
        }
    }
}

public struct FinancialAssistantMessage: Identifiable, Equatable, Sendable {
    public enum Role: String, Equatable, Sendable {
        case user
        case assistant
    }

    public let id: UUID
    public var role: Role
    public var text: String
    public var answer: FinancialAssistantAnswer?

    public init(
        id: UUID,
        role: Role,
        text: String = "",
        answer: FinancialAssistantAnswer? = nil
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.answer = answer
    }
}

@Reducer
public struct FinancialAssistantFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var isPresented: Bool
        public var messages: IdentifiedArrayOf<FinancialAssistantMessage>
        public var draftQuestion: String
        public var isLoading: Bool
        public var errorMessageKey: String?
        public var referenceDate: Date

        public init(
            isPresented: Bool = false,
            messages: IdentifiedArrayOf<FinancialAssistantMessage> = [],
            draftQuestion: String = "",
            isLoading: Bool = false,
            errorMessageKey: String? = nil,
            referenceDate: Date = Date(timeIntervalSinceReferenceDate: 0)
        ) {
            self.isPresented = isPresented
            self.messages = messages
            self.draftQuestion = draftQuestion
            self.isLoading = isLoading
            self.errorMessageKey = errorMessageKey
            self.referenceDate = referenceDate
        }

        public var canSend: Bool {
            draftQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                && isLoading == false
        }
    }

    public enum Action: Equatable, Sendable {
        case floatingButtonTapped
        case sheetDismissed
        case draftQuestionChanged(String)
        case suggestedPromptTapped(FinancialAssistantSuggestedPrompt)
        case sendButtonTapped
        case answerGenerated(FinancialAssistantAnswer)
        case loadFailed
        case clearConversationButtonTapped
    }

    @Dependency(\.date.now) private var now
    @Dependency(\.financialAssistantContextClient) private var contextClient
    @Dependency(\.uuid) private var uuid

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .floatingButtonTapped:
                state.isPresented = true
                return .none

            case .sheetDismissed:
                state.isPresented = false
                return .none

            case let .draftQuestionChanged(question):
                state.draftQuestion = question
                return .none

            case let .suggestedPromptTapped(prompt):
                state.draftQuestion = prompt.defaultQuestion
                return .send(.sendButtonTapped)

            case .sendButtonTapped:
                let question = state.draftQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
                guard question.isEmpty == false, state.isLoading == false else {
                    return .none
                }

                let referenceDate = now
                state.draftQuestion = ""
                state.errorMessageKey = nil
                state.isLoading = true
                state.referenceDate = referenceDate
                state.messages.append(
                    FinancialAssistantMessage(
                        id: uuid(),
                        role: .user,
                        text: question
                    )
                )

                return .run { [contextClient, question, referenceDate] send in
                    do {
                        let transactions = try await contextClient.loadTransactions()
                        let answer = FinancialAssistantEngine.answer(
                            question: question,
                            transactions: transactions,
                            referenceDate: referenceDate
                        )
                        await send(.answerGenerated(answer))
                    } catch {
                        await send(.loadFailed)
                    }
                }

            case let .answerGenerated(answer):
                state.isLoading = false
                state.messages.append(
                    FinancialAssistantMessage(
                        id: uuid(),
                        role: .assistant,
                        answer: answer
                    )
                )
                return .none

            case .loadFailed:
                state.isLoading = false
                state.errorMessageKey = "assistant.error.loadFailed"
                return .none

            case .clearConversationButtonTapped:
                state.messages.removeAll()
                state.errorMessageKey = nil
                return .none
            }
        }
    }
}
