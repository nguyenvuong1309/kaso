import ComposableArchitecture
import KasoDesignSystem
import SwiftUI
import WrappedDomain

public struct WrappedView: View {
    @Bindable var store: StoreOf<WrappedFeature>

    public init(store: StoreOf<WrappedFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Picker(
                    selection: Binding(
                        get: { store.selectedScope },
                        set: { store.send(.scopeChanged($0)) }
                    )
                ) {
                    ForEach(WrappedScope.allCases) { scope in
                        Text(LocalizedStringKey(scope.titleKey), bundle: .module)
                            .tag(scope)
                    }
                } label: {
                    Text("wrapped.scope.label", bundle: .module)
                }
                .pickerStyle(.segmented)

                if store.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if store.report.isSufficient {
                    reportContent
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
            WrappedShareCard(report: store.report)
                .presentationDetents([.large])
        }
    }

    @ViewBuilder
    private var reportContent: some View {
        WrappedHeroCard(report: store.report)
        WrappedStatsCard(report: store.report)
        WrappedTopCategoriesCard(report: store.report)

        Button {
            store.send(.shareButtonTapped)
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "square.and.arrow.up")
                Text("wrapped.share.button", bundle: .module)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.kaso.accent)
    }

    private var insufficientState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "gift.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.kaso.textSecondary.opacity(0.6))

            Text("wrapped.insufficient.title", bundle: .module)
                .font(Font.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)
                .multilineTextAlignment(.center)

            Text("wrapped.insufficient.subtitle", bundle: .module)
                .font(Font.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 240)
        .padding(Spacing.md)
        .background(Color.kaso.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }
}

private struct WrappedHeroCard: View {
    let report: WrappedReport

    var body: some View {
        VStack(spacing: Spacing.md) {
            Text("✨")
                .font(.system(size: 56))

            Text("wrapped.hero.title", bundle: .module)
                .font(Font.kaso.titleLarge)
                .foregroundStyle(Color.kaso.textPrimary)

            Text(report.periodLabel)
                .font(Font.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            HStack(spacing: Spacing.lg) {
                VStack(spacing: 4) {
                    Text("wrapped.hero.income", bundle: .module)
                        .font(Font.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                    Text(report.totalIncome, format: .currency(code: "VND"))
                        .font(Font.kaso.body)
                        .foregroundStyle(Color.kaso.positive)
                }

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Text("wrapped.hero.expense", bundle: .module)
                        .font(Font.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                    Text(report.totalExpense, format: .currency(code: "VND"))
                        .font(Font.kaso.body)
                        .foregroundStyle(Color.kaso.textPrimary)
                }
            }

            Text(report.netBalance, format: .currency(code: "VND"))
                .font(Font.kaso.titleMedium)
                .foregroundStyle(report.netBalance >= 0 ? Color.kaso.positive : Color.kaso.destructive)

            Text("wrapped.hero.netLabel", bundle: .module)
                .font(Font.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.kaso.accent.opacity(0.25), Color.kaso.accent.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }
}

private struct WrappedStatsCard: View {
    let report: WrappedReport

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("wrapped.stats.title", bundle: .module)
                .font(Font.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            statRow(
                icon: "number",
                label: Text("wrapped.stats.transactionCount", bundle: .module),
                value: "\(report.transactionCount)"
            )

            statRow(
                icon: "bolt.fill",
                label: Text("wrapped.stats.largest", bundle: .module),
                value: report.largestTransaction.formatted(.currency(code: "VND"))
            )

            statRow(
                icon: "moon.zzz.fill",
                label: Text("wrapped.stats.noSpendDays", bundle: .module),
                value: "\(report.noSpendDays)"
            )

            statRow(
                icon: "flame.fill",
                label: Text("wrapped.stats.bestStreak", bundle: .module),
                value: "\(report.bestStreak)"
            )
        }
        .padding(Spacing.md)
        .background(Color.kaso.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }

    private func statRow(icon: String, label: Text, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(Color.kaso.accent)
                .frame(width: 24)
            label
                .font(Font.kaso.body)
                .foregroundStyle(Color.kaso.textPrimary)
            Spacer()
            Text(value)
                .font(Font.kaso.body)
                .foregroundStyle(Color.kaso.textSecondary)
        }
    }
}

private struct WrappedTopCategoriesCard: View {
    let report: WrappedReport

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("wrapped.topCategories.title", bundle: .module)
                .font(Font.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            ForEach(Array(report.topCategories.enumerated()), id: \.element.id) { index, category in
                HStack {
                    Text("#\(index + 1)")
                        .font(Font.kaso.titleMedium)
                        .foregroundStyle(Color.kaso.accent)
                        .frame(width: 30, alignment: .leading)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.categoryID.capitalized)
                            .font(Font.kaso.body)
                            .foregroundStyle(Color.kaso.textPrimary)

                        Text("\(category.transactionCount) giao dịch · \(Int(category.percentage * 100))%")
                            .font(Font.kaso.caption)
                            .foregroundStyle(Color.kaso.textSecondary)
                    }

                    Spacer()

                    Text(category.totalAmount, format: .currency(code: "VND"))
                        .font(Font.kaso.body)
                        .foregroundStyle(Color.kaso.textPrimary)
                }

                if index < report.topCategories.count - 1 {
                    Divider()
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.kaso.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }
}
