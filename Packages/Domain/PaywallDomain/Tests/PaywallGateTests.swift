import Foundation
import Testing
@testable import PaywallDomain

struct PaywallGateTests {
    @Test("free tier is allowed for free-tier features")
    func freeAllowedForFreeFeatures() {
        let decision = PaywallGate.evaluate(feature: .csvExport, entitlement: .free)
        #expect(decision == .allowed)
        #expect(decision.isGated == false)
        #expect(decision.requiresTier == nil)
    }

    @Test("free tier is gated for pro features")
    func freeGatedForProFeatures() {
        let decision = PaywallGate.evaluate(feature: .ocrReceipt, entitlement: .free)
        #expect(decision == .gated(requiresTier: .pro))
        #expect(decision.isGated)
        #expect(decision.requiresTier == .pro)
    }

    @Test("pro tier unlocks pro features but is gated for family-only features")
    func proUnlocksProGatedForFamily() {
        let proEntitlement = SubscriptionEntitlement(tier: .pro)
        let aiDecision = PaywallGate.evaluate(feature: .aiInsights, entitlement: proEntitlement)
        #expect(aiDecision == .allowed)
        let familyDecision = PaywallGate.evaluate(feature: .familySharing, entitlement: proEntitlement)
        #expect(familyDecision == .gated(requiresTier: .family))
    }

    @Test("family tier unlocks every feature flag")
    func familyUnlocksEverything() {
        let entitlement = SubscriptionEntitlement(tier: .family)
        for flag in SubscriptionFeatureFlag.allCases {
            #expect(PaywallGate.evaluate(feature: flag, entitlement: entitlement) == .allowed)
        }
    }

    @Test("tier-only convenience matches entitlement-based call")
    func tierAndEntitlementMatch() {
        for flag in SubscriptionFeatureFlag.allCases {
            for tier in SubscriptionTier.allCases {
                let viaEntitlement = PaywallGate.evaluate(
                    feature: flag,
                    entitlement: SubscriptionEntitlement(tier: tier)
                )
                let viaTier = PaywallGate.evaluate(feature: flag, tier: tier)
                #expect(viaEntitlement == viaTier)
            }
        }
    }
}
