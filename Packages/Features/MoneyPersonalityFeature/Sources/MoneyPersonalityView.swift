import ComposableArchitecture
import KasoDesignSystem
import MoneyPersonalityDomain
import SwiftUI

public struct MoneyPersonalityView: View {
    @Bindable var store: StoreOf<MoneyPersonalityFeature>

    public init(store: StoreOf<MoneyPersonalityFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                if store.isAnalyzing {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if store.profile.isSufficient {
                    profileContent
                } else {
                    insufficientState
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
        }
        .task { await store.send(.task).finish() }
        .sheet(isPresented: Binding(
            get: { store.isShareSheetPresented },
            set: { if !$0 { store.send(.shareSheetDismissed) } }
        )) {
            MoneyPersonalityShareCard(profile: store.profile)
                .presentationDetents([.large])
        }
    }

    private var profileContent: some View {
        VStack(spacing: Spacing.lg) {
            MoneyPersonalityHeroCard(profile: store.profile)
            MoneyPersonalityTraitsCard(traits: store.profile.traits)
            MoneyPersonalityAdviceCard(type: store.profile.type)

            Button {
                store.send(.shareButtonTapped)
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "square.and.arrow.up")
                    Text("personality.share.button", bundle: .module)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.kaso.accent)

            Button {
                store.send(.analyze)
            } label: {
                Text("personality.refresh.button", bundle: .module)
                    .font(Font.kaso.caption)
            }
            .buttonStyle(.bordered)
        }
    }

    private var insufficientState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 56))
                .foregroundStyle(Color.kaso.textSecondary.opacity(0.6))

            Text("personality.insufficient.title", bundle: .module)
                .font(Font.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)
                .multilineTextAlignment(.center)

            Text(
                "personality.insufficient.subtitle \(MoneyPersonalityAnalyzer.minimumTransactionCount)",
                bundle: .module
            )
                .font(Font.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
                .multilineTextAlignment(.center)

            if let errorKey = store.errorMessageKey {
                Text(LocalizedStringKey(errorKey), bundle: .module)
                    .font(Font.kaso.caption)
                    .foregroundStyle(Color.kaso.destructive)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 240)
        .padding(Spacing.md)
        .background(Color.kaso.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }
}

private struct MoneyPersonalityHeroCard: View {
    let profile: MoneyPersonalityProfile

    var body: some View {
        VStack(spacing: Spacing.md) {
            Text(profile.type.emoji)
                .font(.system(size: 64))

            Text(LocalizedStringKey(profile.type.nameKey), bundle: .module)
                .font(Font.kaso.titleLarge)
                .foregroundStyle(Color.kaso.textPrimary)

            Text(LocalizedStringKey(profile.type.taglineKey), bundle: .module)
                .font(Font.kaso.body)
                .foregroundStyle(Color.kaso.textSecondary)
                .multilineTextAlignment(.center)

            Text(LocalizedStringKey(profile.type.descriptionKey), bundle: .module)
                .font(Font.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.md)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(heroBackground)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }

    private var heroBackground: some View {
        LinearGradient(
            colors: [
                Color(hex: profile.type.primaryColorHex).opacity(0.25),
                Color(hex: profile.type.secondaryColorHex).opacity(0.15),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct MoneyPersonalityTraitsCard: View {
    let traits: [MoneyPersonalityTrait]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("personality.traits.title", bundle: .module)
                .font(Font.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            ForEach(traits) { trait in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(LocalizedStringKey(trait.labelKey), bundle: .module)
                            .font(Font.kaso.caption)
                            .foregroundStyle(Color.kaso.textSecondary)

                        Spacer()

                        Text(String(format: "%.0f%%", trait.value * 100))
                            .font(Font.kaso.caption)
                            .foregroundStyle(Color.kaso.textPrimary)
                    }

                    ProgressView(value: trait.value)
                        .tint(Color.kaso.accent)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.kaso.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }
}

private struct MoneyPersonalityAdviceCard: View {
    let type: MoneyPersonalityType

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(Color.kaso.warning)

                Text("personality.advice.title", bundle: .module)
                    .font(Font.kaso.titleMedium)
                    .foregroundStyle(Color.kaso.textPrimary)
            }

            Text(LocalizedStringKey(type.adviceKey), bundle: .module)
                .font(Font.kaso.body)
                .foregroundStyle(Color.kaso.textSecondary)
        }
        .padding(Spacing.md)
        .background(Color.kaso.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }
}

private extension Color {
    init(hex: String) {
        var hex = hex
        if hex.hasPrefix("#") {
            hex.removeFirst()
        }
        var rgbValue: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgbValue)
        let red = Double((rgbValue >> 16) & 0xFF) / 255.0
        let green = Double((rgbValue >> 8) & 0xFF) / 255.0
        let blue = Double(rgbValue & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}
