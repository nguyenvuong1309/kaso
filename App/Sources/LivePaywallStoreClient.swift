import Foundation
import PaywallDomain
import StoreKit

enum LivePaywallStoreClient {
    static func make() -> PaywallStoreClient {
        PaywallStoreClient(
            fetchProducts: { productIDs in
                let products = try await Product.products(for: productIDs)
                return products.map { product in
                    ResolvedProduct(
                        productID: product.id,
                        displayName: product.displayName,
                        displayPrice: product.displayPrice,
                        priceVND: priceVND(for: product)
                    )
                }
            },
            purchase: { productID in
                do {
                    let products = try await Product.products(for: [productID])
                    guard let product = products.first else {
                        return .failed("paywall.error.productNotFound")
                    }
                    let result = try await product.purchase()
                    switch result {
                    case let .success(verification):
                        switch verification {
                        case let .verified(transaction):
                            await transaction.finish()
                            return .purchased(entitlement(from: transaction))
                        case .unverified:
                            return .failed("paywall.error.unverified")
                        }
                    case .userCancelled:
                        return .userCancelled
                    case .pending:
                        return .pending
                    @unknown default:
                        return .failed("paywall.error.storeUnavailable")
                    }
                } catch {
                    return .failed("paywall.error.storeUnavailable")
                }
            },
            restorePurchases: {
                do {
                    try await AppStore.sync()
                    if let entitlement = await activeEntitlement() {
                        return .purchased(entitlement)
                    }
                    return .purchased(.free)
                } catch {
                    return .failed("paywall.error.restoreFailed")
                }
            },
            currentEntitlement: {
                await activeEntitlement() ?? .free
            }
        )
    }

    private static func activeEntitlement() async -> SubscriptionEntitlement? {
        for await result in Transaction.currentEntitlements {
            guard case let .verified(transaction) = result else { continue }
            if transaction.revocationDate != nil { continue }
            return entitlement(from: transaction)
        }
        return nil
    }

    private static func entitlement(from transaction: Transaction) -> SubscriptionEntitlement {
        let tier = tier(forProductID: transaction.productID)
        return SubscriptionEntitlement(
            tier: tier,
            activePlanID: transaction.productID,
            purchasedAt: transaction.purchaseDate,
            expiresAt: transaction.expirationDate,
            isInTrial: transaction.offerType == .introductory
        )
    }

    private static func tier(forProductID productID: String) -> SubscriptionTier {
        if productID.contains(".family.") { return .family }
        if productID.contains(".pro.") { return .pro }
        return .free
    }

    private static func priceVND(for product: Product) -> Decimal? {
        guard product.priceFormatStyle.currencyCode == "VND" else {
            return nil
        }
        return product.price
    }
}
