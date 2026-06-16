import Foundation
import Testing
@testable import PaywallDomain

/// Focused coverage of the `PaywallGateDecision` enum accessors and the
/// tier-only `PaywallGate.evaluate` overload boundaries, complementing the
/// scenario-driven `PaywallGateTests`.
struct PaywallGateDecisionTests {
    @Test("allowed decision reports not gated and no required tier")
    func allowedAccessors() {
        let decision = PaywallGateDecision.allowed
        #expect(decision.isGated == false)
        #expect(decision.requiresTier == nil)
    }

    @Test("gated decision exposes the required tier")
    func gatedAccessors() {
        let proGate = PaywallGateDecision.gated(requiresTier: .pro)
        #expect(proGate.isGated)
        #expect(proGate.requiresTier == .pro)

        let familyGate = PaywallGateDecision.gated(requiresTier: .family)
        #expect(familyGate.isGated)
        #expect(familyGate.requiresTier == .family)
    }

    @Test("equatable distinguishes allowed from gated and gated tiers")
    func equatable() {
        #expect(PaywallGateDecision.allowed == .allowed)
        #expect(PaywallGateDecision.allowed != .gated(requiresTier: .pro))
        #expect(PaywallGateDecision.gated(requiresTier: .pro) != .gated(requiresTier: .family))
    }

    @Test("tier-only evaluate gates free users behind the feature minimum tier")
    func tierOnlyGatesFree() {
        #expect(PaywallGate.evaluate(feature: .familySharing, tier: .free) == .gated(requiresTier: .family))
        #expect(PaywallGate.evaluate(feature: .aiInsights, tier: .free) == .gated(requiresTier: .pro))
        #expect(PaywallGate.evaluate(feature: .csvExport, tier: .free) == .allowed)
    }

    @Test("tier-only evaluate allows pro users for pro features but gates family-only")
    func tierOnlyPro() {
        #expect(PaywallGate.evaluate(feature: .aiInsights, tier: .pro) == .allowed)
        #expect(PaywallGate.evaluate(feature: .familyCompatibility, tier: .pro) == .gated(requiresTier: .family))
    }

    @Test("required tier on a gate is always the feature minimum tier")
    func gatedTierIsMinimum() {
        for flag in SubscriptionFeatureFlag.allCases {
            let decision = PaywallGate.evaluate(feature: flag, tier: .free)
            if case let .gated(tier) = decision {
                #expect(tier == flag.minimumTier)
            }
        }
    }
}
