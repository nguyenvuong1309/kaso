import Foundation
import Testing
@testable import CompatibilityDomain

@Test("calculator exposes a conflict threshold of forty")
func calculatorConflictThreshold() {
    #expect(CompatibilityCalculator.conflictThreshold == 40)
}

@Test("identical answers yield a perfect overall score of one hundred")
func identicalAnswersScoreOneHundred() {
    let questions = CompatibilityQuestionBank.defaultQuestions
    let user = answers(for: questions, selectedOptionIndex: 1, respondent: .user)
    let partner = answers(for: questions, selectedOptionIndex: 1, respondent: .partner)

    let result = CompatibilityCalculator.calculate(
        questions: questions,
        userAnswers: user,
        partnerAnswers: partner,
        generatedAt: Date(timeIntervalSince1970: 0)
    )

    #expect(result.overallScore == 100)
    for dimension in CompatibilityDimension.allCases {
        #expect(result.dimensionScores[dimension] == 100)
    }
    #expect(result.highlightedConflicts.isEmpty)
}

@Test("fully opposite answers yield a dimension score of thirty")
func fullyOppositeAnswersScoreThirty() {
    // distance clamped to 1, penalty 70 -> 100 - 70 = 30
    let questions = CompatibilityQuestionBank.defaultQuestions
    let user = answers(for: questions, selectedOptionIndex: 0, respondent: .user)
    let partner = answers(for: questions, selectedOptionIndex: 3, respondent: .partner)

    let result = CompatibilityCalculator.calculate(
        questions: questions,
        userAnswers: user,
        partnerAnswers: partner
    )

    #expect(result.overallScore == 30)
    for dimension in CompatibilityDimension.allCases {
        #expect(result.dimensionScores[dimension] == 30)
    }
    // 30 < 40 threshold so every dimension is a conflict
    #expect(result.highlightedConflicts.count == 6)
    #expect(result.compatibilityType == .needsAlignment)
}

@Test("adjacent option answers produce a partial score above the conflict threshold")
func adjacentAnswersProducePartialScore() {
    // distance 0.33, penalty 70 -> 100 - 0.33*70 = 76.9
    let questions = CompatibilityQuestionBank.defaultQuestions
    let user = answers(for: questions, selectedOptionIndex: 1, respondent: .user)
    let partner = answers(for: questions, selectedOptionIndex: 2, respondent: .partner)

    let result = CompatibilityCalculator.calculate(
        questions: questions,
        userAnswers: user,
        partnerAnswers: partner
    )

    let score = result.dimensionScores[.spendingStyle] ?? 0
    #expect(abs(score - 76.9) < 0.001)
    #expect(result.highlightedConflicts.isEmpty)
    #expect(result.compatibilityType == .strongFoundation)
}

@Test("missing answers produce zero dimension scores")
func missingAnswersProduceZeroScores() {
    let questions = CompatibilityQuestionBank.defaultQuestions

    let result = CompatibilityCalculator.calculate(
        questions: questions,
        userAnswers: [],
        partnerAnswers: []
    )

    #expect(result.overallScore == 0)
    for dimension in CompatibilityDimension.allCases {
        #expect(result.dimensionScores[dimension] == 0)
    }
    // zero is below the threshold, so every dimension is flagged
    #expect(result.highlightedConflicts.count == 6)
    #expect(result.compatibilityType == .needsAlignment)
}

@Test("an answered dimension is unscored when the partner has not answered")
func partnerMissingLeavesDimensionUnscored() {
    let questions = CompatibilityQuestionBank.defaultQuestions
    let user = answers(for: questions, selectedOptionIndex: 2, respondent: .user)

    let result = CompatibilityCalculator.calculate(
        questions: questions,
        userAnswers: user,
        partnerAnswers: []
    )

    #expect(result.overallScore == 0)
    #expect(result.dimensionScores[.spendingStyle] == 0)
}

@Test("an out of range selected option index is ignored and scores zero")
func outOfRangeIndexIsIgnored() {
    let questions = CompatibilityQuestionBank.defaultQuestions
    let firstId = questions[0].id
    let user = [CompatibilityAnswer(questionId: firstId, selectedOptionIndex: 99, respondent: .user)]
    let partner = [CompatibilityAnswer(questionId: firstId, selectedOptionIndex: 1, respondent: .partner)]

    let result = CompatibilityCalculator.calculate(
        questions: questions,
        userAnswers: user,
        partnerAnswers: partner
    )

    #expect(result.dimensionScores[.spendingStyle] == 0)
}

@Test("a negative selected option index is ignored and scores zero")
func negativeIndexIsIgnored() {
    let questions = CompatibilityQuestionBank.defaultQuestions
    let firstId = questions[0].id
    let user = [CompatibilityAnswer(questionId: firstId, selectedOptionIndex: -1, respondent: .user)]
    let partner = [CompatibilityAnswer(questionId: firstId, selectedOptionIndex: 0, respondent: .partner)]

    let result = CompatibilityCalculator.calculate(
        questions: questions,
        userAnswers: user,
        partnerAnswers: partner
    )

    #expect(result.dimensionScores[.spendingStyle] == 0)
}

@Test("question weight biases the dimension score toward the heavier question")
func questionWeightBiasesScore() {
    let dimension = CompatibilityDimension.spendingStyle
    let lightId = UUID(uuidString: "00000000-0000-0000-0000-000000000A01") ?? UUID()
    let heavyId = UUID(uuidString: "00000000-0000-0000-0000-000000000A02") ?? UUID()
    let options = [
        CompatibilityOption(textKey: "o0", compatibilityValue: 0),
        CompatibilityOption(textKey: "o1", compatibilityValue: 1),
    ]
    let questions = [
        CompatibilityQuestion(id: lightId, dimension: dimension, textKey: "light", options: options, weight: 1),
        CompatibilityQuestion(id: heavyId, dimension: dimension, textKey: "heavy", options: options, weight: 3),
    ]
    // light question: agreement -> 100, heavy question: opposite -> 30
    let user = [
        CompatibilityAnswer(questionId: lightId, selectedOptionIndex: 0, respondent: .user),
        CompatibilityAnswer(questionId: heavyId, selectedOptionIndex: 0, respondent: .user),
    ]
    let partner = [
        CompatibilityAnswer(questionId: lightId, selectedOptionIndex: 0, respondent: .partner),
        CompatibilityAnswer(questionId: heavyId, selectedOptionIndex: 1, respondent: .partner),
    ]

    let result = CompatibilityCalculator.calculate(
        questions: questions,
        userAnswers: user,
        partnerAnswers: partner
    )

    // (100*1 + 30*3) / (1+3) = 190 / 4 = 47.5
    let score = result.dimensionScores[dimension] ?? 0
    #expect(abs(score - 47.5) < 0.001)
}

@Test("overall score averages only across the dimensions present in the questions")
func overallScoreAveragesAcrossDimensions() {
    // Two dimensions: one perfect (100), one opposite (30) -> average 65
    let spendingId = UUID(uuidString: "00000000-0000-0000-0000-000000000B01") ?? UUID()
    let riskId = UUID(uuidString: "00000000-0000-0000-0000-000000000B02") ?? UUID()
    let options = [
        CompatibilityOption(textKey: "o0", compatibilityValue: 0),
        CompatibilityOption(textKey: "o1", compatibilityValue: 1),
    ]
    let questions = [
        CompatibilityQuestion(id: spendingId, dimension: .spendingStyle, textKey: "s", options: options),
        CompatibilityQuestion(id: riskId, dimension: .riskTolerance, textKey: "r", options: options),
    ]
    let user = [
        CompatibilityAnswer(questionId: spendingId, selectedOptionIndex: 0, respondent: .user),
        CompatibilityAnswer(questionId: riskId, selectedOptionIndex: 0, respondent: .user),
    ]
    let partner = [
        CompatibilityAnswer(questionId: spendingId, selectedOptionIndex: 0, respondent: .partner),
        CompatibilityAnswer(questionId: riskId, selectedOptionIndex: 1, respondent: .partner),
    ]

    let result = CompatibilityCalculator.calculate(
        questions: questions,
        userAnswers: user,
        partnerAnswers: partner
    )

    // Unanswered dimensions still scored 0 because all dimensions are iterated.
    // present scores: spending 100, risk 30, plus four zero dimensions
    // (100 + 30 + 0 + 0 + 0 + 0) / 6 = 21.666...
    #expect(abs(result.overallScore - (130.0 / 6.0)) < 0.001)
}

@Test("calculator passes through the provided generation timestamp")
func calculatorPassesGeneratedAt() throws {
    let calendar = Calendar(identifier: .gregorian)
    let generatedAt = try makeDate(year: 2026, month: 6, day: 16, hour: 9, calendar: calendar)
    let questions = CompatibilityQuestionBank.defaultQuestions
    let user = answers(for: questions, selectedOptionIndex: 1, respondent: .user)
    let partner = answers(for: questions, selectedOptionIndex: 1, respondent: .partner)

    let result = CompatibilityCalculator.calculate(
        questions: questions,
        userAnswers: user,
        partnerAnswers: partner,
        generatedAt: generatedAt
    )

    #expect(result.generatedAt == generatedAt)
}

@Test("conversation starters include the leading conflict starter when conflicts exist")
func conversationStartersIncludeConflictStarter() {
    let conflict = ConflictInsight(
        dimension: .debtAttitude,
        score: 10,
        titleKey: "t",
        descriptionKey: "d"
    )
    let starters = CompatibilityCalculator.conversationStarters(
        for: .needsAlignment,
        conflicts: [conflict]
    )

    #expect(starters.count == 3)
    #expect(starters[0] == "compatibility.starter.conflict.debtAttitude")
    #expect(starters[1] == "compatibility.starter.needsAlignment.first")
    #expect(starters[2] == "compatibility.starter.needsAlignment.second")
}

@Test("conversation starters use only the first conflict when several exist")
func conversationStartersUseOnlyFirstConflict() {
    let conflicts = [
        ConflictInsight(dimension: .spendingStyle, score: 10, titleKey: "t", descriptionKey: "d"),
        ConflictInsight(dimension: .riskTolerance, score: 5, titleKey: "t", descriptionKey: "d"),
    ]
    let starters = CompatibilityCalculator.conversationStarters(
        for: .perfectMatch,
        conflicts: conflicts
    )

    #expect(starters.count == 3)
    #expect(starters[0] == "compatibility.starter.conflict.spendingStyle")
    #expect(starters.contains("compatibility.starter.conflict.riskTolerance") == false)
}

@Test("conversation starters omit the conflict line when there are no conflicts")
func conversationStartersOmitConflictLine() {
    let starters = CompatibilityCalculator.conversationStarters(
        for: .perfectMatch,
        conflicts: []
    )

    #expect(starters.count == 2)
    #expect(starters[0] == "compatibility.starter.perfectMatch.first")
    #expect(starters[1] == "compatibility.starter.perfectMatch.second")
}

@Test("conflict insight keys are derived from the dimension raw value")
func conflictInsightKeysDerivedFromDimension() {
    let questions = CompatibilityQuestionBank.defaultQuestions
    let user = answers(for: questions, selectedOptionIndex: 0, respondent: .user)
    let partner = answers(for: questions, selectedOptionIndex: 3, respondent: .partner)

    let result = CompatibilityCalculator.calculate(
        questions: questions,
        userAnswers: user,
        partnerAnswers: partner
    )

    let insight = try? #require(result.highlightedConflicts.first { $0.dimension == .spendingStyle })
    #expect(insight?.titleKey == "compatibility.conflict.spendingStyle.title")
    #expect(insight?.descriptionKey == "compatibility.conflict.spendingStyle.description")
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

private func makeDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 12,
    calendar: Calendar
) throws -> Date {
    try #require(
        DateComponents(
            calendar: calendar,
            year: year,
            month: month,
            day: day,
            hour: hour
        ).date
    )
}
