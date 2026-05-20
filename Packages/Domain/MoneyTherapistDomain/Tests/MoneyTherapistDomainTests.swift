import Foundation
import Testing
@testable import MoneyTherapistDomain

struct MoneyTherapistDomainTests {
    @Test("prompt library returns prompts for every topic")
    func libraryCoversAllTopics() {
        for topic in TherapistTopic.allCases {
            let prompt = TherapistPromptLibrary.prompt(for: topic)
            #expect(prompt.topic == topic)
            #expect(prompt.openingMessageKey.isEmpty == false)
            #expect(prompt.closingMessageKey.isEmpty == false)
            #expect(prompt.reflectionQuestionKeys.count == 3)
            #expect(prompt.suggestedActionKeys.count == 2)
        }
    }

    @Test("reflection defaults to fresh id and current date")
    func reflectionDefaults() {
        let before = Date()
        let reflection = TherapistReflection(topic: .guilt, note: "test")
        let after = Date()
        #expect(reflection.topic == .guilt)
        #expect(reflection.note == "test")
        #expect(reflection.recordedAt >= before && reflection.recordedAt <= after)
    }
}
