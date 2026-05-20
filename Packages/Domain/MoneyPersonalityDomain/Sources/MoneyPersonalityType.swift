import Foundation

public enum MoneyPersonalityType: String, CaseIterable, Codable, Equatable, Sendable, Identifiable {
    case planner
    case impulsive
    case minimalist
    case foodie
    case experienceSeeker

    public var id: String { rawValue }

    public var nameKey: String { "personality.type.\(rawValue).name" }
    public var taglineKey: String { "personality.type.\(rawValue).tagline" }
    public var descriptionKey: String { "personality.type.\(rawValue).description" }
    public var adviceKey: String { "personality.type.\(rawValue).advice" }

    public var emoji: String {
        switch self {
        case .planner: "🎯"
        case .impulsive: "⚡"
        case .minimalist: "🧘"
        case .foodie: "🍜"
        case .experienceSeeker: "🌍"
        }
    }

    public var symbolName: String {
        switch self {
        case .planner: "list.bullet.rectangle"
        case .impulsive: "bolt.fill"
        case .minimalist: "leaf.fill"
        case .foodie: "fork.knife"
        case .experienceSeeker: "airplane"
        }
    }

    public var primaryColorHex: String {
        switch self {
        case .planner: "#4A90E2"
        case .impulsive: "#F5A623"
        case .minimalist: "#7ED321"
        case .foodie: "#D0021B"
        case .experienceSeeker: "#9013FE"
        }
    }

    public var secondaryColorHex: String {
        switch self {
        case .planner: "#50E3C2"
        case .impulsive: "#FFD400"
        case .minimalist: "#B8E986"
        case .foodie: "#F87171"
        case .experienceSeeker: "#BD10E0"
        }
    }
}
