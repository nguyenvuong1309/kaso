import Foundation

/// A bundled, template-only prompt for a topic. Content keys resolve from the
/// MoneyTherapistFeature module bundle (Vietnamese + English). No PII is ever
/// sent off-device; the "AI" experience is template-driven by design.
public struct TherapistPrompt: Equatable, Sendable {
    public let topic: TherapistTopic
    public let openingMessageKey: String
    public let reflectionQuestionKeys: [String]
    public let closingMessageKey: String
    public let suggestedActionKeys: [String]

    public init(
        topic: TherapistTopic,
        openingMessageKey: String,
        reflectionQuestionKeys: [String],
        closingMessageKey: String,
        suggestedActionKeys: [String]
    ) {
        self.topic = topic
        self.openingMessageKey = openingMessageKey
        self.reflectionQuestionKeys = reflectionQuestionKeys
        self.closingMessageKey = closingMessageKey
        self.suggestedActionKeys = suggestedActionKeys
    }
}

public enum TherapistPromptLibrary {
    public static func prompt(for topic: TherapistTopic) -> TherapistPrompt {
        TherapistPrompt(
            topic: topic,
            openingMessageKey: "moneyTherapist.topic.\(topic.rawValue).opening",
            reflectionQuestionKeys: [
                "moneyTherapist.topic.\(topic.rawValue).question.0",
                "moneyTherapist.topic.\(topic.rawValue).question.1",
                "moneyTherapist.topic.\(topic.rawValue).question.2",
            ],
            closingMessageKey: "moneyTherapist.topic.\(topic.rawValue).closing",
            suggestedActionKeys: [
                "moneyTherapist.topic.\(topic.rawValue).action.0",
                "moneyTherapist.topic.\(topic.rawValue).action.1",
            ]
        )
    }
}
