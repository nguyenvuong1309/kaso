import Foundation

/// Emotional contexts a user may want to reflect on after a transaction.
public enum TherapistTopic: String, CaseIterable, Sendable, Identifiable, Equatable {
    case recentOverspend
    case guilt
    case stressTrigger
    case comparisonAnxiety
    case generalCheckin

    public var id: String { rawValue }

    public var titleKey: String { "moneyTherapist.topic.\(rawValue).title" }
    public var subtitleKey: String { "moneyTherapist.topic.\(rawValue).subtitle" }
    public var iconSystemName: String {
        switch self {
        case .recentOverspend: "exclamationmark.bubble"
        case .guilt: "heart.text.square"
        case .stressTrigger: "wind"
        case .comparisonAnxiety: "person.2"
        case .generalCheckin: "leaf"
        }
    }
}
