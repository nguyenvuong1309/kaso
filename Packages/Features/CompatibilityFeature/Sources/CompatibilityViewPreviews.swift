import SwiftUI
import ComposableArchitecture
import CompatibilityDomain

#Preview("Compatibility Intro Light") {
    CompatibilityView(store: introStore)
}

#Preview("Compatibility Intro Dark") {
    CompatibilityView(store: introStore)
        .preferredColorScheme(.dark)
}

#Preview("Compatibility Quiz Dynamic Type XL") {
    CompatibilityView(store: quizStore)
        .environment(\.dynamicTypeSize, .accessibility1)
}

#Preview("Compatibility Result Light") {
    CompatibilityView(store: resultStore)
}

#Preview("Compatibility Share Card") {
    CompatibilityShareCard(result: previewResult)
}

@MainActor
private var introStore: StoreOf<CompatibilityFeature> {
    Store(initialState: CompatibilityFeature.State()) {
        CompatibilityFeature()
    }
}

@MainActor
private var quizStore: StoreOf<CompatibilityFeature> {
    let questions = CompatibilityQuestionBank.defaultQuestions
    return Store(
        initialState: CompatibilityFeature.State(
            phase: .selfQuiz,
            questions: questions
        )
    ) {
        CompatibilityFeature()
    }
}

@MainActor
private var resultStore: StoreOf<CompatibilityFeature> {
    Store(
        initialState: CompatibilityFeature.State(
            phase: .result,
            result: previewResult
        )
    ) {
        CompatibilityFeature()
    }
}

private var previewResult: CompatibilityResult {
    let questions = CompatibilityQuestionBank.defaultQuestions
    return CompatibilityCalculator.calculate(
        questions: questions,
        userAnswers: answers(for: questions, selectedOptionIndex: 1, respondent: .user),
        partnerAnswers: answers(for: questions, selectedOptionIndex: 2, respondent: .partner)
    )
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
