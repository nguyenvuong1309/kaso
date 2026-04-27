import Foundation
import Testing
@testable import CompatibilityDomain

@Test("perfect match scores 85 to 100 when every answer matches")
func perfectMatchScoresHighWhenAnswersMatch() {
    let questions = CompatibilityQuestionBank.defaultQuestions
    let userAnswers = answers(for: questions, selectedOptionIndex: 2, respondent: .user)
    let partnerAnswers = answers(for: questions, selectedOptionIndex: 2, respondent: .partner)

    let result = CompatibilityCalculator.calculate(
        questions: questions,
        userAnswers: userAnswers,
        partnerAnswers: partnerAnswers,
        generatedAt: Date(timeIntervalSince1970: 0)
    )

    #expect(result.overallScore >= 85)
    #expect(result.overallScore <= 100)
    #expect(result.compatibilityType == .perfectMatch)
    #expect(result.highlightedConflicts.isEmpty)
}

@Test("opposites attract when five of six dimensions are fully opposite")
func oppositesAttractWhenMostDimensionsAreOpposite() {
    let questions = CompatibilityQuestionBank.defaultQuestions
    let userAnswers = answers(for: questions, selectedOptionIndex: 0, respondent: .user)
    let partnerAnswers = questions.enumerated().map { index, question in
        CompatibilityAnswer(
            questionId: question.id,
            selectedOptionIndex: index < 5 ? 3 : 0,
            respondent: .partner
        )
    }

    let result = CompatibilityCalculator.calculate(
        questions: questions,
        userAnswers: userAnswers,
        partnerAnswers: partnerAnswers
    )

    #expect(result.compatibilityType == .oppositesAttract)
    #expect(result.highlightedConflicts.count == 5)
}

@Test("conflict highlights only appear for dimension score under forty")
func conflictHighlightsOnlyAppearBelowThreshold() {
    let questions = CompatibilityQuestionBank.defaultQuestions
    let userAnswers = answers(for: questions, selectedOptionIndex: 0, respondent: .user)
    let partnerAnswers = answers(for: questions, selectedOptionIndex: 3, respondent: .partner)

    let result = CompatibilityCalculator.calculate(
        questions: questions,
        userAnswers: userAnswers,
        partnerAnswers: partnerAnswers
    )

    #expect(result.highlightedConflicts.isEmpty == false)
    #expect(result.highlightedConflicts.allSatisfy { $0.score < 40 })
}

@Test("conversation starters are not empty for every compatibility type")
func conversationStartersAreNotEmptyForEveryType() {
    for type in CompatibilityType.allCases {
        let starters = CompatibilityCalculator.conversationStarters(
            for: type,
            conflicts: []
        )
        #expect(starters.isEmpty == false)
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
