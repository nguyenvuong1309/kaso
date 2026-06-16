import Foundation
import Testing
@testable import CompatibilityDomain

@Test("default question bank has exactly one question per dimension")
func bankHasOneQuestionPerDimension() {
    let questions = CompatibilityQuestionBank.defaultQuestions
    #expect(questions.count == CompatibilityDimension.allCases.count)
    let dimensions = questions.map(\.dimension)
    #expect(Set(dimensions) == Set(CompatibilityDimension.allCases))
    #expect(dimensions == CompatibilityDimension.allCases)
}

@Test("default questions use deterministic stable identifiers")
func bankUsesStableIdentifiers() {
    let questions = CompatibilityQuestionBank.defaultQuestions
    let expectedIds = [
        "00000000-0000-0000-0000-000000018101",
        "00000000-0000-0000-0000-000000018102",
        "00000000-0000-0000-0000-000000018103",
        "00000000-0000-0000-0000-000000018104",
        "00000000-0000-0000-0000-000000018105",
        "00000000-0000-0000-0000-000000018106",
    ]
    #expect(questions.map { $0.id.uuidString.lowercased() } == expectedIds)
}

@Test("default questions have unique identifiers")
func bankIdentifiersAreUnique() {
    let ids = CompatibilityQuestionBank.defaultQuestions.map(\.id)
    #expect(Set(ids).count == ids.count)
}

@Test("each default question has four options with ascending values")
func bankOptionsHaveExpectedValues() {
    for question in CompatibilityQuestionBank.defaultQuestions {
        #expect(question.options.count == 4)
        #expect(question.options.map(\.compatibilityValue) == [0, 0.33, 0.67, 1])
    }
}

@Test("each default question carries the default weight of one")
func bankQuestionsUseDefaultWeight() {
    for question in CompatibilityQuestionBank.defaultQuestions {
        #expect(question.weight == 1)
    }
}

@Test("default question text keys are namespaced by dimension")
func bankQuestionTextKeys() {
    for question in CompatibilityQuestionBank.defaultQuestions {
        #expect(question.textKey == "compatibility.question.\(question.dimension.rawValue).text")
    }
}

@Test("default option text keys are namespaced by dimension and index")
func bankOptionTextKeys() {
    for question in CompatibilityQuestionBank.defaultQuestions {
        for (index, option) in question.options.enumerated() {
            #expect(option.textKey == "compatibility.question.\(question.dimension.rawValue).option.\(index)")
        }
    }
}

@Test("default question bank is stable across repeated access")
func bankIsStableAcrossAccess() {
    #expect(CompatibilityQuestionBank.defaultQuestions == CompatibilityQuestionBank.defaultQuestions)
}
