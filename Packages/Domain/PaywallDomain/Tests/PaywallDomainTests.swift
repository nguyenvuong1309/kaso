import Foundation
import Testing
@testable import PaywallDomain

struct PaywallDomainTests {
    @Test("tier ranks are ordered free < pro < family")
    func tierRankOrder() {
        #expect(SubscriptionTier.free.rank == 0)
        #expect(SubscriptionTier.free < .pro)
        #expect(SubscriptionTier.pro < .family)
        #expect(SubscriptionTier.family > .free)
    }

    @Test("free tier unlocks only features marked .free")
    func freeUnlocksFreeFeatures() {
        let unlocked = SubscriptionTier.free.unlockedFeatures
        #expect(unlocked.contains(.csvExport))
        #expect(unlocked.contains(.widgets))
        #expect(unlocked.contains(.aiInsights) == false)
        #expect(unlocked.contains(.familySharing) == false)
    }

    @Test("pro tier unlocks everything below family")
    func proUnlocksProAndFreeFeatures() {
        let pro = SubscriptionTier.pro.unlockedFeatures
        #expect(pro.contains(.aiInsights))
        #expect(pro.contains(.iCloudSync))
        #expect(pro.contains(.appleWatch))
        #expect(pro.contains(.familySharing) == false)
        #expect(pro.contains(.csvExport))
    }

    @Test("family tier unlocks every feature")
    func familyUnlocksEverything() {
        let family = SubscriptionTier.family.unlockedFeatures
        #expect(family == Set(SubscriptionFeatureFlag.allCases))
    }

    @Test("bundled catalogue prices match plan.md")
    func bundledCataloguePricesMatchPlan() {
        let proMonthly = PricingPlan.bundledCatalogue.first { $0.tier == .pro && $0.cycle == .monthly }
        #expect(proMonthly?.priceVND == 49_000)
        let proYearly = PricingPlan.bundledCatalogue.first { $0.tier == .pro && $0.cycle == .yearly }
        #expect(proYearly?.priceVND == 399_000)
        #expect(proYearly?.isRecommended == true)
        let familyMonthly = PricingPlan.bundledCatalogue.first { $0.tier == .family && $0.cycle == .monthly }
        #expect(familyMonthly?.priceVND == 79_000)
        let familyYearly = PricingPlan.bundledCatalogue.first { $0.tier == .family && $0.cycle == .yearly }
        #expect(familyYearly?.priceVND == 599_000)
    }

    @Test("entitlement defaults to free")
    func entitlementDefaultsFree() {
        let entitlement = SubscriptionEntitlement.free
        #expect(entitlement.tier == .free)
        #expect(entitlement.activePlanID == nil)
        #expect(entitlement.expiresAt == nil)
        #expect(entitlement.isInTrial == false)
    }

    @Test("preview store client returns purchased entitlement matching plan")
    func previewStorePurchasedTier() async {
        let outcome = await PaywallStoreClient.preview.purchase("com.vuongnguyen.kaso.pro.yearly")
        guard case let .purchased(entitlement) = outcome else {
            Issue.record("expected purchased outcome")
            return
        }
        #expect(entitlement.tier == .pro)
        #expect(entitlement.activePlanID == "com.vuongnguyen.kaso.pro.yearly")
    }
}
