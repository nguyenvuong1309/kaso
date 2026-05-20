import ComposableArchitecture
import PaywallDomain

private enum PaywallStoreClientKey: DependencyKey {
    static let liveValue = PaywallStoreClient.empty
    static let previewValue = PaywallStoreClient.preview
    static let testValue = PaywallStoreClient.empty
}

private enum SubscriptionEntitlementRepositoryKey: DependencyKey {
    static let liveValue = SubscriptionEntitlementRepository.empty
    static let previewValue = SubscriptionEntitlementRepository.preview
    static let testValue = SubscriptionEntitlementRepository.empty
}

public extension DependencyValues {
    var paywallStoreClient: PaywallStoreClient {
        get { self[PaywallStoreClientKey.self] }
        set { self[PaywallStoreClientKey.self] = newValue }
    }

    var subscriptionEntitlementRepository: SubscriptionEntitlementRepository {
        get { self[SubscriptionEntitlementRepositoryKey.self] }
        set { self[SubscriptionEntitlementRepositoryKey.self] = newValue }
    }
}
