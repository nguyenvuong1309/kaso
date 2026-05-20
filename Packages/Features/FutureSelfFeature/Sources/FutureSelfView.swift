import ComposableArchitecture
import FutureSelfDomain
import KasoDesignSystem
import SwiftUI

public struct FutureSelfView: View {
    @Bindable var store: StoreOf<FutureSelfFeature>

    public init(store: StoreOf<FutureSelfFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            Group {
                if store.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if store.letter.isSufficient == false {
                    emptyState
                } else {
                    content
                }
            }
            .navigationTitle(Text("futureSelf.title", bundle: .module))
            .navigationBarTitleDisplayMode(.large)
        }
        .task { await store.send(.task).finish() }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                letterCard
                projectionCard
            }
            .padding(Spacing.md)
        }
    }

    private var letterCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(store.letter.tone.emoji)
                    .font(.system(size: 44))
                Text(LocalizedStringKey(store.letter.tone.headlineKey), bundle: .module)
                    .font(Font.kaso.titleMedium)
                    .foregroundStyle(Color.kaso.textPrimary)
                Text("futureSelf.greeting \(store.letter.quarterLabel)", bundle: .module)
                    .font(Font.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
            }

            ForEach(store.letter.paragraphKeys, id: \.self) { key in
                Text(LocalizedStringKey(key), bundle: .module)
                    .font(Font.kaso.body)
                    .foregroundStyle(Color.kaso.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("futureSelf.signature", bundle: .module)
                .font(Font.kaso.body)
                .italic()
                .foregroundStyle(Color.kaso.textSecondary)
        }
        .padding(Spacing.lg)
        .background(
            LinearGradient(
                colors: [Color.kaso.accent.opacity(0.18), Color.kaso.surfaceSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }

    private var projectionCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("futureSelf.projection.age", bundle: .module)
                    .font(Font.kaso.body)
                    .foregroundStyle(Color.kaso.textSecondary)
                Spacer()
                Text(String(store.letter.projectedAge))
                    .font(Font.kaso.body)
                    .foregroundStyle(Color.kaso.textPrimary)
            }
            Divider()
            HStack {
                Text("futureSelf.projection.annualSavings", bundle: .module)
                    .font(Font.kaso.body)
                    .foregroundStyle(Color.kaso.textSecondary)
                Spacer()
                Text(store.letter.projectedAnnualSavings, format: .currency(code: "VND"))
                    .font(Font.kaso.body)
                    .foregroundStyle(Color.kaso.positive)
            }
            Divider()
            HStack {
                Text("futureSelf.projection.savingsRate", bundle: .module)
                    .font(Font.kaso.body)
                    .foregroundStyle(Color.kaso.textSecondary)
                Spacer()
                Text("\(Int(store.letter.savingsRate * 100))%")
                    .font(Font.kaso.body)
                    .foregroundStyle(Color.kaso.textPrimary)
            }
        }
        .padding(Spacing.md)
        .background(Color.kaso.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "envelope.badge.person.crop")
                .font(.system(size: 52))
                .foregroundStyle(Color.kaso.textSecondary.opacity(0.6))

            Text("futureSelf.empty.title", bundle: .module)
                .font(Font.kaso.body)
                .foregroundStyle(Color.kaso.textPrimary)

            Text("futureSelf.empty.subtitle", bundle: .module)
                .font(Font.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
