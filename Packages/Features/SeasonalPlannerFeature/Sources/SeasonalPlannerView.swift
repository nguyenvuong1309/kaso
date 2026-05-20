import ComposableArchitecture
import KasoDesignSystem
import SeasonalPlannerDomain
import SwiftUI

public struct SeasonalPlannerRootView: View {
    private let store: StoreOf<SeasonalPlannerFeature>

    public init(contextClient: SeasonalContextClient = .preview) {
        store = Store(initialState: SeasonalPlannerFeature.State()) {
            SeasonalPlannerFeature()
        } withDependencies: {
            $0.seasonalContextClient = contextClient
        }
    }

    public var body: some View {
        SeasonalPlannerView(store: store)
    }
}

public struct SeasonalPlannerView: View {
    private let store: StoreOf<SeasonalPlannerFeature>

    public init(store: StoreOf<SeasonalPlannerFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                if store.isLoading {
                    ProgressView().frame(maxWidth: .infinity)
                }

                if let messageKey = store.errorMessageKey {
                    SeasonalPlannerErrorLabel(messageKey: messageKey)
                }

                KasoCard {
                    SeasonalPlannerHeaderCard(plan: store.plan)
                }

                if store.plan.spikes.isEmpty {
                    KasoCard {
                        SeasonalPlannerEmptyStateCard(isSufficient: store.plan.isSufficient)
                    }
                } else {
                    ForEach(store.plan.spikes) { spike in
                        KasoCard {
                            SeasonalPlannerSpikeCard(spike: spike)
                        }
                    }
                }
            }
            .padding(Spacing.md)
        }
        .background(Color.kaso.surfacePrimary)
        .task {
            await store.send(.task).finish()
        }
    }
}

private struct SeasonalPlannerErrorLabel: View {
    let messageKey: String

    var body: some View {
        Label {
            Text(LocalizedStringKey(messageKey), bundle: .module)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
        }
        .font(.kaso.caption)
        .foregroundStyle(Color.kaso.destructive)
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Color.kaso.destructive.opacity(0.12))
        )
    }
}
