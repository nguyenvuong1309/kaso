import Foundation
import Testing
@testable import CompatibilityDomain

// MARK: - CompatibilityOption

@Test("option stores text key and compatibility value")
func optionStoresValues() {
    let option = CompatibilityOption(textKey: "key.a", compatibilityValue: 0.5)
    #expect(option.textKey == "key.a")
    #expect(option.compatibilityValue == 0.5)
}

@Test("option round-trips through Codable")
func optionCodableRoundTrip() throws {
    let option = CompatibilityOption(textKey: "key.b", compatibilityValue: 0.67)
    let data = try JSONEncoder().encode(option)
    let decoded = try JSONDecoder().decode(CompatibilityOption.self, from: data)
    #expect(decoded == option)
}

@Test("options are equatable by both fields")
func optionEquatable() {
    let base = CompatibilityOption(textKey: "k", compatibilityValue: 1)
    #expect(base == CompatibilityOption(textKey: "k", compatibilityValue: 1))
    #expect(base != CompatibilityOption(textKey: "k", compatibilityValue: 0))
    #expect(base != CompatibilityOption(textKey: "other", compatibilityValue: 1))
}

// MARK: - CompatibilityQuestion

@Test("question default initializer applies weight of one and generates an id")
func questionDefaultsWeightAndId() {
    let question = CompatibilityQuestion(
        dimension: .spendingStyle,
        textKey: "q",
        options: []
    )
    #expect(question.weight == 1)
    #expect(question.dimension == .spendingStyle)
    #expect(question.textKey == "q")
    #expect(question.options.isEmpty)
}

@Test("question stores all provided values")
func questionStoresValues() {
    let id = UUID(uuidString: "00000000-0000-0000-0000-000000000abc") ?? UUID()
    let options = [CompatibilityOption(textKey: "o0", compatibilityValue: 0)]
    let question = CompatibilityQuestion(
        id: id,
        dimension: .futureGoals,
        textKey: "future",
        options: options,
        weight: 2.5
    )
    #expect(question.id == id)
    #expect(question.dimension == .futureGoals)
    #expect(question.textKey == "future")
    #expect(question.options == options)
    #expect(question.weight == 2.5)
}

@Test("question round-trips through Codable")
func questionCodableRoundTrip() throws {
    let id = UUID(uuidString: "00000000-0000-0000-0000-000000000def") ?? UUID()
    let question = CompatibilityQuestion(
        id: id,
        dimension: .debtAttitude,
        textKey: "debt",
        options: [
            CompatibilityOption(textKey: "a", compatibilityValue: 0),
            CompatibilityOption(textKey: "b", compatibilityValue: 1),
        ],
        weight: 1.5
    )
    let data = try JSONEncoder().encode(question)
    let decoded = try JSONDecoder().decode(CompatibilityQuestion.self, from: data)
    #expect(decoded == question)
}

// MARK: - CompatibilityRespondent

@Test("respondent raw values are user and partner")
func respondentRawValues() {
    #expect(CompatibilityRespondent.user.rawValue == "user")
    #expect(CompatibilityRespondent.partner.rawValue == "partner")
}

@Test("respondent round-trips through Codable")
func respondentCodableRoundTrip() throws {
    for respondent in [CompatibilityRespondent.user, .partner] {
        let data = try JSONEncoder().encode(respondent)
        let decoded = try JSONDecoder().decode(CompatibilityRespondent.self, from: data)
        #expect(decoded == respondent)
    }
}

// MARK: - CompatibilityAnswer

@Test("answer stores question id, option index, and respondent")
func answerStoresValues() {
    let id = UUID(uuidString: "00000000-0000-0000-0000-000000000111") ?? UUID()
    let answer = CompatibilityAnswer(questionId: id, selectedOptionIndex: 2, respondent: .partner)
    #expect(answer.questionId == id)
    #expect(answer.selectedOptionIndex == 2)
    #expect(answer.respondent == .partner)
}

@Test("answer round-trips through Codable")
func answerCodableRoundTrip() throws {
    let id = UUID(uuidString: "00000000-0000-0000-0000-000000000222") ?? UUID()
    let answer = CompatibilityAnswer(questionId: id, selectedOptionIndex: 1, respondent: .user)
    let data = try JSONEncoder().encode(answer)
    let decoded = try JSONDecoder().decode(CompatibilityAnswer.self, from: data)
    #expect(decoded == answer)
}

// MARK: - ConflictInsight

@Test("conflict insight id equals dimension raw value")
func conflictInsightId() {
    let insight = ConflictInsight(
        dimension: .riskTolerance,
        score: 12,
        titleKey: "t",
        descriptionKey: "d"
    )
    #expect(insight.id == "riskTolerance")
    #expect(insight.id == insight.dimension.rawValue)
}

@Test("conflict insight stores all values")
func conflictInsightStoresValues() {
    let insight = ConflictInsight(
        dimension: .familySupport,
        score: 30,
        titleKey: "title.key",
        descriptionKey: "description.key"
    )
    #expect(insight.dimension == .familySupport)
    #expect(insight.score == 30)
    #expect(insight.titleKey == "title.key")
    #expect(insight.descriptionKey == "description.key")
}

@Test("conflict insight round-trips through Codable")
func conflictInsightCodableRoundTrip() throws {
    let insight = ConflictInsight(
        dimension: .splittingApproach,
        score: 22.5,
        titleKey: "t.k",
        descriptionKey: "d.k"
    )
    let data = try JSONEncoder().encode(insight)
    let decoded = try JSONDecoder().decode(ConflictInsight.self, from: data)
    #expect(decoded == insight)
}

// MARK: - CompatibilityResult

@Test("result stores all fields and round-trips through Codable")
func resultCodableRoundTrip() throws {
    let calendar = Calendar(identifier: .gregorian)
    let generatedAt = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let result = CompatibilityResult(
        overallScore: 73.4,
        dimensionScores: [
            .spendingStyle: 80,
            .riskTolerance: 60,
        ],
        compatibilityType: .strongFoundation,
        highlightedConflicts: [
            ConflictInsight(dimension: .riskTolerance, score: 35, titleKey: "t", descriptionKey: "d"),
        ],
        conversationStarters: ["starter.one", "starter.two"],
        generatedAt: generatedAt
    )
    let data = try JSONEncoder().encode(result)
    let decoded = try JSONDecoder().decode(CompatibilityResult.self, from: data)
    #expect(decoded == result)
    #expect(decoded.overallScore == 73.4)
    #expect(decoded.dimensionScores[.spendingStyle] == 80)
    #expect(decoded.compatibilityType == .strongFoundation)
    #expect(decoded.highlightedConflicts.count == 1)
    #expect(decoded.conversationStarters == ["starter.one", "starter.two"])
    #expect(decoded.generatedAt == generatedAt)
}

// MARK: - CompatibilityType

@Test("type init maps score 85 and above to perfect match")
func typeInitPerfectMatch() {
    #expect(CompatibilityType(score: 85) == .perfectMatch)
    #expect(CompatibilityType(score: 92) == .perfectMatch)
    #expect(CompatibilityType(score: 100) == .perfectMatch)
}

@Test("type init maps score 70 to under 85 to strong foundation")
func typeInitStrongFoundation() {
    #expect(CompatibilityType(score: 70) == .strongFoundation)
    #expect(CompatibilityType(score: 84.999) == .strongFoundation)
}

@Test("type init maps score 50 to under 70 to work in progress")
func typeInitWorkInProgress() {
    #expect(CompatibilityType(score: 50) == .workInProgress)
    #expect(CompatibilityType(score: 69.999) == .workInProgress)
}

@Test("type init maps score 30 to under 50 to opposites attract")
func typeInitOppositesAttract() {
    #expect(CompatibilityType(score: 30) == .oppositesAttract)
    #expect(CompatibilityType(score: 49.999) == .oppositesAttract)
}

@Test("type init maps score below 30 to needs alignment")
func typeInitNeedsAlignment() {
    #expect(CompatibilityType(score: 29.999) == .needsAlignment)
    #expect(CompatibilityType(score: 0) == .needsAlignment)
    #expect(CompatibilityType(score: -10) == .needsAlignment)
}

@Test("type exposes all five cases")
func typeAllCases() {
    #expect(CompatibilityType.allCases.count == 5)
    #expect(Set(CompatibilityType.allCases) == [
        .perfectMatch,
        .strongFoundation,
        .workInProgress,
        .oppositesAttract,
        .needsAlignment,
    ])
}

@Test("type title and description keys are namespaced by raw value")
func typeTitleAndDescriptionKeys() {
    for type in CompatibilityType.allCases {
        #expect(type.titleKey == "compatibility.type.\(type.rawValue).title")
        #expect(type.descriptionKey == "compatibility.type.\(type.rawValue).description")
    }
}

@Test("type color names map to expected palette entries")
func typeColorNames() {
    #expect(CompatibilityType.perfectMatch.colorName == "green")
    #expect(CompatibilityType.strongFoundation.colorName == "mint")
    #expect(CompatibilityType.workInProgress.colorName == "blue")
    #expect(CompatibilityType.oppositesAttract.colorName == "orange")
    #expect(CompatibilityType.needsAlignment.colorName == "purple")
}

@Test("type round-trips through Codable")
func typeCodableRoundTrip() throws {
    for type in CompatibilityType.allCases {
        let data = try JSONEncoder().encode(type)
        let decoded = try JSONDecoder().decode(CompatibilityType.self, from: data)
        #expect(decoded == type)
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
