import ComposableArchitecture
import KasoDesignSystem
import PaywallDomain
import SwiftUI

public struct PaywallView: View {
    @Bindable private var store: StoreOf<PaywallFeature>

    public init(store: StoreOf<PaywallFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                PaywallHeroCard(
                    entitlement: store.entitlement,
                    triggeringFeature: store.triggeringFeature
                )

                PaywallTierSelector(
                    selectedTier: store.selectedTier,
                    onSelect: { store.send(.selectTier($0)) }
                )

                PaywallFeatureList(tier: store.selectedTier)

                if store.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    PaywallPlanList(
                        plans: store.plansForSelectedTier,
                        resolvedProducts: store.resolvedProducts,
                        isPurchasing: store.isPurchasing,
                        activePlanID: store.entitlement.activePlanID,
                        onPurchase: { store.send(.purchaseButtonTapped($0)) }
                    )
                }

                Button {
                    store.send(.restoreButtonTapped)
                } label: {
                    if store.isRestoring {
                        ProgressView()
                    } else {
                        Text("paywall.action.restore", bundle: .module)
                    }
                }
                .buttonStyle(.borderless)
                .frame(maxWidth: .infinity)
                .disabled(store.isRestoring || store.isPurchasing)

                if let successKey = store.successMessageKey {
                    PaywallStatusBanner(messageKey: successKey, isError: false)
                }

                if let errorKey = store.errorMessageKey {
                    PaywallStatusBanner(messageKey: errorKey, isError: true)
                }

                PaywallLegalFooter()
            }
            .padding(Spacing.md)
        }
        .background(Color.kaso.surfacePrimary)
        .task {
            await store.send(.task).finish()
        }
    }
}
