import Foundation

/// The three subscription tiers offered in Kaso.
public enum SubscriptionTier: String, Codable, CaseIterable, Equatable, Sendable, Identifiable {
    case free
    case pro
    case family

    public var id: String { rawValue }

    public var titleKey: String {
        switch self {
        case .free: "paywall.tier.free.title"
        case .pro: "paywall.tier.pro.title"
        case .family: "paywall.tier.family.title"
        }
    }

    public var taglineKey: String {
        switch self {
        case .free: "paywall.tier.free.tagline"
        case .pro: "paywall.tier.pro.tagline"
        case .family: "paywall.tier.family.tagline"
        }
    }

    /// `true` when the tier provides paid features.
    public var isPaid: Bool {
        switch self {
        case .free: false
        case .pro, .family: true
        }
    }

    /// Tiers are ordered from least to most capable. Higher rank includes
    /// every feature unlocked by lower ranks.
    public var rank: Int {
        switch self {
        case .free: 0
        case .pro: 1
        case .family: 2
        }
    }
}

extension SubscriptionTier: Comparable {
    public static func < (lhs: SubscriptionTier, rhs: SubscriptionTier) -> Bool {
        lhs.rank < rhs.rank
    }
}
