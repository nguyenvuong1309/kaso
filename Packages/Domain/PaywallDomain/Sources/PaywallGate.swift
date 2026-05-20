import Foundation

/// Outcome of checking whether the current entitlement is enough to use a
/// given feature. Views consume this to decide between rendering the real
/// button and showing a paywall lock instead.
public enum PaywallGateDecision: Equatable, Sendable {
    case allowed
    case gated(requiresTier: SubscriptionTier)

    public var isGated: Bool {
        if case .gated = self { return true }
        return false
    }

    public var requiresTier: SubscriptionTier? {
        if case let .gated(tier) = self { return tier }
        return nil
    }
}

/// Pure, side-effect-free decision helper. Lives in the domain so any
/// feature can gate UI without depending on `PaywallFeature` or the store.
public enum PaywallGate {
    public static func evaluate(
        feature: SubscriptionFeatureFlag,
        entitlement: SubscriptionEntitlement
    ) -> PaywallGateDecision {
        if entitlement.tier.unlocks(feature) {
            return .allowed
        }
        return .gated(requiresTier: feature.minimumTier)
    }

    public static func evaluate(
        feature: SubscriptionFeatureFlag,
        tier: SubscriptionTier
    ) -> PaywallGateDecision {
        if tier.unlocks(feature) {
            return .allowed
        }
        return .gated(requiresTier: feature.minimumTier)
    }
}
