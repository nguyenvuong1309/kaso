import Foundation
import Testing
@testable import MoneyTherapistDomain

@Test("prompt stores all provided fields verbatim")
func promptStoresFields() {
    let prompt = TherapistPrompt(
        topic: .guilt,
        openingMessageKey: "opening.key",
        reflectionQuestionKeys: ["q0", "q1"],
        closingMessageKey: "closing.key",
        suggestedActionKeys: ["a0"]
    )
    #expect(prompt.topic == .guilt)
    #expect(prompt.openingMessageKey == "opening.key")
    #expect(prompt.reflectionQuestionKeys == ["q0", "q1"])
    #expect(prompt.closingMessageKey == "closing.key")
    #expect(prompt.suggestedActionKeys == ["a0"])
}

@Test("prompts with identical fields are equal")
func promptEquality() {
    let lhs = TherapistPrompt(
        topic: .stressTrigger,
        openingMessageKey: "o",
        reflectionQuestionKeys: ["q"],
        closingMessageKey: "c",
        suggestedActionKeys: ["a"]
    )
    let rhs = TherapistPrompt(
        topic: .stressTrigger,
        openingMessageKey: "o",
        reflectionQuestionKeys: ["q"],
        closingMessageKey: "c",
        suggestedActionKeys: ["a"]
    )
    #expect(lhs == rhs)
}

@Test("prompts differing only by topic are not equal")
func promptInequalityByTopic() {
    let base = TherapistPrompt(
        topic: .guilt,
        openingMessageKey: "o",
        reflectionQuestionKeys: ["q"],
        closingMessageKey: "c",
        suggestedActionKeys: ["a"]
    )
    let other = TherapistPrompt(
        topic: .recentOverspend,
        openingMessageKey: "o",
        reflectionQuestionKeys: ["q"],
        closingMessageKey: "c",
        suggestedActionKeys: ["a"]
    )
    #expect(base != other)
}

@Test("library builds the prompt's topic to match the request")
func libraryPromptTopicMatches() {
    for topic in TherapistTopic.allCases {
        #expect(TherapistPromptLibrary.prompt(for: topic).topic == topic)
    }
}

@Test("library namespaces all keys with the topic raw value")
func libraryNamespacesKeys() {
    let prompt = TherapistPromptLibrary.prompt(for: .comparisonAnxiety)
    let raw = TherapistTopic.comparisonAnxiety.rawValue
    #expect(prompt.openingMessageKey == "moneyTherapist.topic.\(raw).opening")
    #expect(prompt.closingMessageKey == "moneyTherapist.topic.\(raw).closing")
    #expect(prompt.reflectionQuestionKeys == [
        "moneyTherapist.topic.\(raw).question.0",
        "moneyTherapist.topic.\(raw).question.1",
        "moneyTherapist.topic.\(raw).question.2",
    ])
    #expect(prompt.suggestedActionKeys == [
        "moneyTherapist.topic.\(raw).action.0",
        "moneyTherapist.topic.\(raw).action.1",
    ])
}

@Test("library produces exactly three reflection questions and two actions")
func libraryKeyCounts() {
    for topic in TherapistTopic.allCases {
        let prompt = TherapistPromptLibrary.prompt(for: topic)
        #expect(prompt.reflectionQuestionKeys.count == 3)
        #expect(prompt.suggestedActionKeys.count == 2)
    }
}

@Test("library keys are non-empty for every topic")
func libraryKeysNonEmpty() {
    for topic in TherapistTopic.allCases {
        let prompt = TherapistPromptLibrary.prompt(for: topic)
        #expect(prompt.openingMessageKey.isEmpty == false)
        #expect(prompt.closingMessageKey.isEmpty == false)
        #expect(prompt.reflectionQuestionKeys.allSatisfy { $0.isEmpty == false })
        #expect(prompt.suggestedActionKeys.allSatisfy { $0.isEmpty == false })
    }
}

@Test("library opening and closing keys differ for every topic")
func libraryOpeningClosingDiffer() {
    for topic in TherapistTopic.allCases {
        let prompt = TherapistPromptLibrary.prompt(for: topic)
        #expect(prompt.openingMessageKey != prompt.closingMessageKey)
    }
}

@Test("library yields distinct opening keys across topics")
func libraryDistinctOpeningKeys() {
    let keys = TherapistTopic.allCases.map { TherapistPromptLibrary.prompt(for: $0).openingMessageKey }
    #expect(Set(keys).count == keys.count)
}

@Test("library is deterministic for repeated requests")
func libraryDeterministic() {
    let first = TherapistPromptLibrary.prompt(for: .generalCheckin)
    let second = TherapistPromptLibrary.prompt(for: .generalCheckin)
    #expect(first == second)
}
