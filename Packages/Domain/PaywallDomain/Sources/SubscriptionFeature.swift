import Foundation

/// Concrete feature toggles guarded by paid tiers. Each feature has a
/// `minimumTier` describing the lowest tier that unlocks it.
public enum SubscriptionFeatureFlag: String, CaseIterable, Equatable, Sendable {
    case unlimitedHistory
    case ocrReceipt
    case bankStatementImport
    case voiceEntry
    case subscriptionTracker
    case aiInsights
    case spendingForecast
    case savingsGoals
    case advancedReports
    case csvExport
    case iCloudSync
    case widgets
    case appleWatch
    case familySharing
    case familyCompatibility

    public var minimumTier: SubscriptionTier {
        switch self {
        case .csvExport,
             .widgets:
            .free
        case .unlimitedHistory,
             .ocrReceipt,
             .bankStatementImport,
             .voiceEntry,
             .subscriptionTracker,
             .aiInsights,
             .spendingForecast,
             .savingsGoals,
             .advancedReports,
             .iCloudSync,
             .appleWatch:
            .pro
        case .familySharing,
             .familyCompatibility:
            .family
        }
    }

    public var titleKey: String {
        "paywall.feature.\(rawValue).title"
    }
}

public extension SubscriptionTier {
    /// All features unlocked at this tier or below.
    var unlockedFeatures: Set<SubscriptionFeatureFlag> {
        Set(SubscriptionFeatureFlag.allCases.filter { $0.minimumTier <= self })
    }

    func unlocks(_ feature: SubscriptionFeatureFlag) -> Bool {
        self >= feature.minimumTier
    }
}
