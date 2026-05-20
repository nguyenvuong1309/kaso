import KasoDesignSystem
import PaywallDomain
import SwiftUI

struct PaywallHeroCard: View {
    let entitlement: SubscriptionEntitlement
    let triggeringFeature: SubscriptionFeatureFlag?

    var body: some View {
        KasoCard {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                if let triggeringFeature {
                    Label {
                        Text(LocalizedStringKey(triggeringFeature.minimumTier.titleKey), bundle: .module)
                    } icon: {
                        Image(systemName: "lock.open.fill")
                    }
                    .font(.kaso.caption.weight(.semibold))
                    .foregroundStyle(Color.kaso.accent)

                    Text(
                        "paywall.hero.gateTitle \(String(localized: String.LocalizationValue(triggeringFeature.titleKey), bundle: .module))",
                        bundle: .module
                    )
                    .font(.kaso.titleMedium)
                    .foregroundStyle(Color.kaso.textPrimary)

                    Text("paywall.hero.gateSubtitle", bundle: .module)
                        .font(.kaso.body)
                        .foregroundStyle(Color.kaso.textSecondary)
                } else {
                    Text("paywall.hero.title", bundle: .module)
                        .font(.kaso.titleMedium)
                        .foregroundStyle(Color.kaso.textPrimary)

                    Text("paywall.hero.subtitle", bundle: .module)
                        .font(.kaso.body)
                        .foregroundStyle(Color.kaso.textSecondary)

                    if entitlement.tier.isPaid {
                        Label {
                            Text(LocalizedStringKey(entitlement.tier.titleKey), bundle: .module)
                        } icon: {
                            Image(systemName: "checkmark.seal.fill")
                        }
                        .font(.kaso.caption.weight(.semibold))
                        .foregroundStyle(Color.kaso.accent)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct PaywallTierSelector: View {
    let selectedTier: SubscriptionTier
    let onSelect: (SubscriptionTier) -> Void

    var body: some View {
        Picker(selection: Binding(
            get: { selectedTier },
            set: { onSelect($0) }
        )) {
            ForEach(SubscriptionTier.allCases.filter { $0.isPaid }) { tier in
                Text(LocalizedStringKey(tier.titleKey), bundle: .module)
                    .tag(tier)
            }
        } label: {
            Text("paywall.tier.label", bundle: .module)
        }
        .pickerStyle(.segmented)
    }
}

struct PaywallFeatureList: View {
    let tier: SubscriptionTier

    var body: some View {
        KasoCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(LocalizedStringKey(tier.taglineKey), bundle: .module)
                    .font(.kaso.body.weight(.semibold))
                    .foregroundStyle(Color.kaso.textPrimary)

                ForEach(SubscriptionFeatureFlag.allCases.filter { tier.unlocks($0) }, id: \.self) { feature in
                    Label {
                        Text(LocalizedStringKey(feature.titleKey), bundle: .module)
                            .font(.kaso.caption)
                            .foregroundStyle(Color.kaso.textPrimary)
                    } icon: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.kaso.accent)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct PaywallPlanList: View {
    let plans: [PricingPlan]
    let resolvedProducts: [String: ResolvedProduct]
    let isPurchasing: Bool
    let activePlanID: String?
    let onPurchase: (String) -> Void

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(plans) { plan in
                PaywallPlanRow(
                    plan: plan,
                    resolvedProduct: resolvedProducts[plan.productID],
                    isPurchasing: isPurchasing,
                    isActive: activePlanID == plan.productID,
                    onPurchase: { onPurchase(plan.productID) }
                )
            }
        }
    }
}

struct PaywallPlanRow: View {
    let plan: PricingPlan
    let resolvedProduct: ResolvedProduct?
    let isPurchasing: Bool
    let isActive: Bool
    let onPurchase: () -> Void

    var body: some View {
        KasoCard {
            HStack(alignment: .top, spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.xs) {
                        Text(LocalizedStringKey(cycleTitleKey), bundle: .module)
                            .font(.kaso.body.weight(.semibold))
                            .foregroundStyle(Color.kaso.textPrimary)

                        if plan.isRecommended {
                            Text("paywall.badge.recommended", bundle: .module)
                                .font(.kaso.caption.weight(.semibold))
                                .padding(.horizontal, Spacing.xs)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(Color.kaso.accent.opacity(0.18))
                                )
                                .foregroundStyle(Color.kaso.accent)
                        }
                    }

                    Text(priceLabel)
                        .font(.kaso.body)
                        .foregroundStyle(Color.kaso.textSecondary)
                }

                Spacer()

                if isActive {
                    Label {
                        Text("paywall.action.active", bundle: .module)
                            .font(.kaso.caption.weight(.semibold))
                    } icon: {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    .foregroundStyle(Color.kaso.accent)
                } else {
                    Button(action: onPurchase) {
                        Text("paywall.action.purchase", bundle: .module)
                            .font(.kaso.body.weight(.semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(isPurchasing)
                }
            }
        }
    }

    private var cycleTitleKey: String {
        plan.cycle == .monthly
            ? "paywall.cycle.monthly"
            : "paywall.cycle.yearly"
    }

    private var priceLabel: String {
        if let resolved = resolvedProduct {
            return resolved.displayPrice
        }
        return plan.priceVND.formatted(.currency(code: "VND"))
    }
}

struct PaywallStatusBanner: View {
    let messageKey: String
    let isError: Bool

    var body: some View {
        Label {
            Text(LocalizedStringKey(messageKey), bundle: .module)
        } icon: {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
        }
        .font(.kaso.caption.weight(.semibold))
        .foregroundStyle(isError ? Color.kaso.destructive : Color.kaso.accent)
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill((isError ? Color.kaso.destructive : Color.kaso.accent).opacity(0.12))
        )
    }
}

struct PaywallLegalFooter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("paywall.legal.disclaimer", bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
