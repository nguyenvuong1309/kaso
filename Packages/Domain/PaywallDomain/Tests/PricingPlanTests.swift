import Foundation
import Testing
@testable import PaywallDomain

struct PricingPlanTests {
    @Test("id mirrors productID")
    func idMatchesProductID() {
        let plan = PricingPlan(
            productID: "com.kaso.test.monthly",
            tier: .pro,
            cycle: .monthly,
            priceVND: 49_000
        )
        #expect(plan.id == "com.kaso.test.monthly")
        #expect(plan.id == plan.productID)
    }

    @Test("isRecommended defaults to false")
    func isRecommendedDefault() {
        let plan = PricingPlan(
            productID: "com.kaso.test.yearly",
            tier: .family,
            cycle: .yearly,
            priceVND: 599_000
        )
        #expect(plan.isRecommended == false)
    }

    @Test("billing cycle Codable round-trips")
    func billingCycleCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for cycle in [PricingPlan.BillingCycle.monthly, .yearly] {
            let data = try encoder.encode(cycle)
            let decoded = try decoder.decode(PricingPlan.BillingCycle.self, from: data)
            #expect(decoded == cycle)
        }
    }

    @Test("bundled catalogue contains four plans")
    func bundledCatalogueCount() {
        #expect(PricingPlan.bundledCatalogue.count == 4)
    }

    @Test("bundled catalogue product IDs are unique")
    func bundledCatalogueUniqueIDs() {
        let ids = PricingPlan.bundledCatalogue.map(\.productID)
        #expect(Set(ids).count == ids.count)
    }

    @Test("only the pro yearly plan is recommended")
    func singleRecommendedPlan() {
        let recommended = PricingPlan.bundledCatalogue.filter(\.isRecommended)
        #expect(recommended.count == 1)
        #expect(recommended.first?.tier == .pro)
        #expect(recommended.first?.cycle == .yearly)
    }

    @Test("bundledPlans filters to a single tier")
    func bundledPlansForTier() {
        let proPlans = PricingPlan.bundledPlans(for: .pro)
        #expect(proPlans.count == 2)
        #expect(proPlans.allSatisfy { $0.tier == .pro })

        let familyPlans = PricingPlan.bundledPlans(for: .family)
        #expect(familyPlans.count == 2)
        #expect(familyPlans.allSatisfy { $0.tier == .family })
    }

    @Test("bundledPlans returns empty for the free tier")
    func bundledPlansForFree() {
        #expect(PricingPlan.bundledPlans(for: .free).isEmpty)
    }

    @Test("every bundled plan carries a positive VND price")
    func positivePrices() {
        for plan in PricingPlan.bundledCatalogue {
            #expect(plan.priceVND > 0)
        }
    }

    @Test("equatable distinguishes plans by their fields")
    func equatable() {
        let a = PricingPlan(productID: "x", tier: .pro, cycle: .monthly, priceVND: 49_000)
        let b = PricingPlan(productID: "x", tier: .pro, cycle: .monthly, priceVND: 49_000)
        let c = PricingPlan(productID: "x", tier: .pro, cycle: .yearly, priceVND: 49_000)
        #expect(a == b)
        #expect(a != c)
    }
}
