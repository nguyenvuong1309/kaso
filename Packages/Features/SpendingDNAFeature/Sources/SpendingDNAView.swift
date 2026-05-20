import ComposableArchitecture
import KasoDesignSystem
import SpendingDNADomain
import SwiftUI

public struct SpendingDNAView: View {
    @Bindable var store: StoreOf<SpendingDNAFeature>

    public init(store: StoreOf<SpendingDNAFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            Group {
                if store.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if store.report.isSufficient == false {
                    emptyState
                } else {
                    content
                }
            }
            .navigationTitle(Text("dna.title", bundle: .module))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.send(.shareButtonTapped)
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(store.report.isSufficient == false)
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { store.isShareSheetPresented },
            set: { if !$0 { store.send(.shareSheetDismissed) } }
        )) {
            SpendingDNAShareCard(report: store.report)
        }
        .task { await store.send(.task).finish() }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                heroCard
                statsCard
                topCategoriesCard
            }
            .padding(Spacing.md)
        }
    }

    private var heroCard: some View {
        VStack(spacing: Spacing.sm) {
            Text(String(store.report.year))
                .font(Font.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)

            Text(store.report.type.emoji)
                .font(.system(size: 64))

            Text(LocalizedStringKey(store.report.type.titleKey), bundle: .module)
                .font(Font.kaso.titleLarge)
                .foregroundStyle(Color.kaso.textPrimary)

            Text(LocalizedStringKey(store.report.type.taglineKey), bundle: .module)
                .font(Font.kaso.body)
                .foregroundStyle(Color.kaso.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .background(
            LinearGradient(
                colors: [Color.kaso.accent.opacity(0.25), Color.kaso.surfaceSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            statRow(
                titleKey: "dna.stat.savingsRate",
                value: "\(Int(store.report.savingsRate * 100))%"
            )
            Divider()
            statRow(
                titleKey: "dna.stat.totalExpense",
                value: store.report.totalExpense.formatted(.currency(code: "VND"))
            )
            Divider()
            statRow(
                titleKey: "dna.stat.largest",
                value: store.report.largestTransaction.formatted(.currency(code: "VND"))
            )
            Divider()
            statRow(
                titleKey: "dna.stat.transactions",
                value: String(store.report.transactionCount)
            )
        }
        .padding(Spacing.md)
        .background(Color.kaso.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }

    private func statRow(titleKey: String, value: String) -> some View {
        HStack {
            Text(LocalizedStringKey(titleKey), bundle: .module)
                .font(Font.kaso.body)
                .foregroundStyle(Color.kaso.textSecondary)
            Spacer()
            Text(value)
                .font(Font.kaso.body)
                .foregroundStyle(Color.kaso.textPrimary)
        }
    }

    private var topCategoriesCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("dna.section.topCategories", bundle: .module)
                .font(Font.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)

            ForEach(store.report.topCategories) { category in
                HStack {
                    Text(category.categoryID.capitalized)
                        .font(Font.kaso.body)
                        .foregroundStyle(Color.kaso.textPrimary)
                    Spacer()
                    Text("\(Int(category.percentage * 100))%")
                        .font(Font.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                    Text(category.totalAmount, format: .currency(code: "VND"))
                        .font(Font.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary.opacity(0.7))
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.kaso.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 52))
                .foregroundStyle(Color.kaso.textSecondary.opacity(0.6))

            Text("dna.empty.title", bundle: .module)
                .font(Font.kaso.body)
                .foregroundStyle(Color.kaso.textPrimary)

            Text("dna.empty.subtitle", bundle: .module)
                .font(Font.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
