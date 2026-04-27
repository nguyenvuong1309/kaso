import Foundation
import ComposableArchitecture
import InsightDomain
import Testing
import TransactionDomain
@testable import FinancialAssistantFeature

@MainActor
@Test("opening assistant presents sheet")
func openingAssistantPresentsSheet() async {
    let store = TestStore(initialState: FinancialAssistantFeature.State()) {
        FinancialAssistantFeature()
    }

    await store.send(.floatingButtonTapped) {
        $0.isPresented = true
    }
}

@MainActor
@Test("sending question appends user message and generated answer")
func sendingQuestionAppendsUserMessageAndGeneratedAnswer() async throws {
    let now = try date(2026, 4, 30)
    let transactions = [
        Transaction(
            amount: 8_000_000,
            kind: .income,
            category: .salary,
            occurredAt: now
        ),
        Transaction(
            amount: 3_000_000,
            kind: .expense,
            category: .food,
            occurredAt: now
        ),
    ]
    let store = TestStore(
        initialState: FinancialAssistantFeature.State(
            draftQuestion: "Tháng này tôi còn bao nhiêu tiền?"
        )
    ) {
        FinancialAssistantFeature()
    } withDependencies: {
        $0.date.now = now
        $0.uuid = .incrementing
        $0.financialAssistantContextClient.loadTransactions = { transactions }
    }
    let expectedAnswer = FinancialAssistantEngine.answer(
        question: "Tháng này tôi còn bao nhiêu tiền?",
        transactions: transactions,
        referenceDate: now
    )

    await store.send(.sendButtonTapped) {
        $0.draftQuestion = ""
        $0.isLoading = true
        $0.referenceDate = now
        $0.messages.append(
            FinancialAssistantMessage(
                id: UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)),
                role: .user,
                text: "Tháng này tôi còn bao nhiêu tiền?"
            )
        )
    }
    await store.receive(.answerGenerated(expectedAnswer)) {
        $0.isLoading = false
        $0.messages.append(
            FinancialAssistantMessage(
                id: UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1)),
                role: .assistant,
                answer: expectedAnswer
            )
        )
    }
}

@MainActor
@Test("load failure clears loading and exposes error")
func loadFailureClearsLoadingAndExposesError() async {
    struct LoadFailure: Error {}

    let store = TestStore(
        initialState: FinancialAssistantFeature.State(draftQuestion: "Tháng này ổn không?")
    ) {
        FinancialAssistantFeature()
    } withDependencies: {
        $0.date.now = Date(timeIntervalSinceReferenceDate: 0)
        $0.uuid = .incrementing
        $0.financialAssistantContextClient.loadTransactions = {
            throw LoadFailure()
        }
    }

    await store.send(.sendButtonTapped) {
        $0.draftQuestion = ""
        $0.isLoading = true
        $0.messages.append(
            FinancialAssistantMessage(
                id: UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)),
                role: .user,
                text: "Tháng này ổn không?"
            )
        )
    }
    await store.receive(.loadFailed) {
        $0.isLoading = false
        $0.errorMessageKey = "assistant.error.loadFailed"
    }
}

@MainActor
@Test("suggested prompt sends default question")
func suggestedPromptSendsDefaultQuestion() async {
    let now = Date(timeIntervalSinceReferenceDate: 799_200_000)
    let store = TestStore(initialState: FinancialAssistantFeature.State()) {
        FinancialAssistantFeature()
    } withDependencies: {
        $0.date.now = now
        $0.uuid = .incrementing
        $0.financialAssistantContextClient.loadTransactions = { [] }
    }
    let question = FinancialAssistantSuggestedPrompt.monthStatus.defaultQuestion
    let expectedAnswer = FinancialAssistantEngine.answer(
        question: question,
        transactions: [],
        referenceDate: now
    )

    await store.send(.suggestedPromptTapped(.monthStatus)) {
        $0.draftQuestion = question
    }
    await store.receive(.sendButtonTapped) {
        $0.draftQuestion = ""
        $0.isLoading = true
        $0.referenceDate = now
        $0.messages.append(
            FinancialAssistantMessage(
                id: UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)),
                role: .user,
                text: question
            )
        )
    }
    await store.receive(.answerGenerated(expectedAnswer)) {
        $0.isLoading = false
        $0.messages.append(
            FinancialAssistantMessage(
                id: UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1)),
                role: .assistant,
                answer: expectedAnswer
            )
        )
    }
}

private func date(
    _ year: Int,
    _ month: Int,
    _ day: Int
) throws -> Date {
    try #require(
        DateComponents(
            calendar: Calendar(identifier: .gregorian),
            year: year,
            month: month,
            day: day,
            hour: 12
        ).date
    )
}
