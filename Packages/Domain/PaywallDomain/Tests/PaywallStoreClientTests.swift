import Foundation
import Testing
@testable import PaywallDomain

struct PaywallStoreClientTests {
    // MARK: - ResolvedProduct

    @Test("ResolvedProduct stores all fields")
    func resolvedProductFields() {
        let product = ResolvedProduct(
            productID: "com.kaso.pro.monthly",
            displayName: "Pro",
            displayPrice: "49.000 ₫",
            priceVND: 49_000
        )
        #expect(product.productID == "com.kaso.pro.monthly")
        #expect(product.displayName == "Pro")
        #expect(product.displayPrice == "49.000 ₫")
        #expect(product.priceVND == 49_000)
    }

    @Test("ResolvedProduct allows nil priceVND")
    func resolvedProductNilPrice() {
        let product = ResolvedProduct(
            productID: "x",
            displayName: "x",
            displayPrice: "—",
            priceVND: nil
        )
        #expect(product.priceVND == nil)
    }

    // MARK: - PaywallPurchaseOutcome

    @Test("purchase outcomes are distinguished by case and payload")
    func outcomeEquatable() {
        #expect(PaywallPurchaseOutcome.userCancelled == .userCancelled)
        #expect(PaywallPurchaseOutcome.pending == .pending)
        #expect(PaywallPurchaseOutcome.failed("a") == .failed("a"))
        #expect(PaywallPurchaseOutcome.failed("a") != .failed("b"))
        #expect(PaywallPurchaseOutcome.purchased(.free) == .purchased(.free))
        #expect(PaywallPurchaseOutcome.purchased(.free) != .userCancelled)
    }

    // MARK: - empty client

    @Test("empty client fetches no products")
    func emptyFetch() async throws {
        let products = try await PaywallStoreClient.empty.fetchProducts(["any"])
        #expect(products.isEmpty)
    }

    @Test("empty client purchase fails with storeUnavailable")
    func emptyPurchase() async {
        let outcome = await PaywallStoreClient.empty.purchase("any")
        #expect(outcome == .failed("paywall.error.storeUnavailable"))
    }

    @Test("empty client restore fails with storeUnavailable")
    func emptyRestore() async {
        let outcome = await PaywallStoreClient.empty.restorePurchases()
        #expect(outcome == .failed("paywall.error.storeUnavailable"))
    }

    @Test("empty client entitlement is free")
    func emptyEntitlement() async {
        let entitlement = await PaywallStoreClient.empty.currentEntitlement()
        #expect(entitlement == .free)
    }

    // MARK: - preview client

    @Test("preview client fetches only the requested products")
    func previewFetchFiltersIDs() async throws {
        let id = "com.vuongnguyen.kaso.pro.monthly"
        let products = try await PaywallStoreClient.preview.fetchProducts([id])
        #expect(products.count == 1)
        let product = try #require(products.first)
        #expect(product.productID == id)
        #expect(product.priceVND == 49_000)
        #expect(product.displayName == "Pro")
    }

    @Test("preview client returns nothing for unknown product IDs")
    func previewFetchUnknown() async throws {
        let products = try await PaywallStoreClient.preview.fetchProducts(["does.not.exist"])
        #expect(products.isEmpty)
    }

    @Test("preview client can fetch multiple matching products")
    func previewFetchMultiple() async throws {
        let ids = PricingPlan.bundledCatalogue.map(\.productID)
        let products = try await PaywallStoreClient.preview.fetchProducts(ids)
        #expect(products.count == PricingPlan.bundledCatalogue.count)
    }

    @Test("preview client purchase succeeds for a known plan")
    func previewPurchaseKnown() async {
        let outcome = await PaywallStoreClient.preview.purchase("com.vuongnguyen.kaso.family.monthly")
        guard case let .purchased(entitlement) = outcome else {
            Issue.record("expected purchased outcome")
            return
        }
        #expect(entitlement.tier == .family)
        #expect(entitlement.activePlanID == "com.vuongnguyen.kaso.family.monthly")
        #expect(entitlement.isInTrial == false)
    }

    @Test("preview client purchase fails for an unknown product")
    func previewPurchaseUnknown() async {
        let outcome = await PaywallStoreClient.preview.purchase("does.not.exist")
        #expect(outcome == .failed("paywall.error.productNotFound"))
    }

    @Test("preview client restore returns the free entitlement")
    func previewRestore() async {
        let outcome = await PaywallStoreClient.preview.restorePurchases()
        #expect(outcome == .purchased(.free))
    }

    @Test("preview client current entitlement is free")
    func previewEntitlement() async {
        let entitlement = await PaywallStoreClient.preview.currentEntitlement()
        #expect(entitlement == .free)
    }
}
