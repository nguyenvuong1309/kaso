import Foundation
import Testing
import ComposableArchitecture
import CompatibilityDomain
@testable import CompatibilityFeature

@MainActor
@Test("answerQuestion updates user answers during self quiz")
func answerQuestionUpdatesUserAnswersDuringSelfQuiz() async throws {
    let questions = CompatibilityQuestionBank.defaultQuestions
    let question = try #require(questions.first)
    let store = TestStore(
        initialState: CompatibilityFeature.State(
            phase: .selfQuiz,
            questions: questions
        )
    ) {
        CompatibilityFeature()
    }

    await store.send(.answerQuestion(questionId: question.id, optionIndex: 2)) {
        $0.userAnswers = [
            CompatibilityAnswer(
                questionId: question.id,
                selectedOptionIndex: 2,
                respondent: .user
            ),
        ]
    }
}

@MainActor
@Test("nextQuestion moves to partner transition after self answers are done")
func nextQuestionMovesToPartnerTransitionAfterSelfAnswersAreDone() async {
    let questions = CompatibilityQuestionBank.defaultQuestions
    let userAnswers = answers(for: questions, selectedOptionIndex: 1, respondent: .user)
    let store = TestStore(
        initialState: CompatibilityFeature.State(
            phase: .selfQuiz,
            questions: questions,
            userAnswers: userAnswers,
            currentQuestionIndex: questions.count - 1
        )
    ) {
        CompatibilityFeature()
    }

    await store.send(.nextQuestion)
    await store.receive(.switchToPartnerQuiz) {
        $0.phase = .partnerTransition
        $0.currentQuestionIndex = 0
    }
}

@MainActor
@Test("calculateResult sends resultCalculated")
func calculateResultSendsResultCalculated() async {
    let questions = CompatibilityQuestionBank.defaultQuestions
    let userAnswers = answers(for: questions, selectedOptionIndex: 0, respondent: .user)
    let partnerAnswers = answers(for: questions, selectedOptionIndex: 3, respondent: .partner)
    let now = Date(timeIntervalSince1970: 1_777_248_000)
    let expected = CompatibilityCalculator.calculate(
        questions: questions,
        userAnswers: userAnswers,
        partnerAnswers: partnerAnswers,
        generatedAt: now
    )
    let store = TestStore(
        initialState: CompatibilityFeature.State(
            phase: .partnerQuiz,
            questions: questions,
            userAnswers: userAnswers,
            partnerAnswers: partnerAnswers,
            currentQuestionIndex: questions.count - 1
        )
    ) {
        CompatibilityFeature()
    } withDependencies: {
        $0.date.now = now
    }

    await store.send(.calculateResult)
    await store.receive(.resultCalculated(expected)) {
        $0.result = expected
        $0.phase = .result
        $0.isAnimatingReveal = true
    }
}

@MainActor
@Test("nextQuestion requires an answer before moving forward")
func nextQuestionRequiresAnswerBeforeMovingForward() async {
    let store = TestStore(
        initialState: CompatibilityFeature.State(phase: .selfQuiz)
    ) {
        CompatibilityFeature()
    }

    await store.send(.nextQuestion) {
        $0.errorMessageKey = "compatibility.error.answerRequired"
    }
}

private func answers(
    for questions: [CompatibilityQuestion],
    selectedOptionIndex: Int,
    respondent: CompatibilityRespondent
) -> [CompatibilityAnswer] {
    questions.map {
        CompatibilityAnswer(
            questionId: $0.id,
            selectedOptionIndex: selectedOptionIndex,
            respondent: respondent
        )
    }
}
