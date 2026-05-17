import Foundation

public enum Mood: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case great
    case good
    case neutral
    case stressed
    case sad
    case anxious

    public var id: String {
        rawValue
    }

    public var nameKey: String {
        "mood.\(rawValue)"
    }

    public var emoji: String {
        switch self {
        case .great:
            "😄"
        case .good:
            "🙂"
        case .neutral:
            "😐"
        case .stressed:
            "😣"
        case .sad:
            "😔"
        case .anxious:
            "😟"
        }
    }

    public var positivityScore: Double {
        switch self {
        case .great:
            1.0
        case .good:
            0.6
        case .neutral:
            0.0
        case .stressed:
            -0.5
        case .sad:
            -0.7
        case .anxious:
            -0.6
        }
    }

    public var isNegative: Bool {
        positivityScore < 0
    }
}
