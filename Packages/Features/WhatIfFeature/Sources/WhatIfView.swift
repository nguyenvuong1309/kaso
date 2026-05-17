import ComposableArchitecture
import KasoDesignSystem
import SwiftUI
import WhatIfDomain

public struct WhatIfRootView: View {
    private let store: StoreOf<WhatIfFeature>

    public init(baselineClient: WhatIfBaselineClient = .empty) {
        store = Store(initialState: WhatIfFeature.State()) {
            WhatIfFeature()
        } withDependencies: {
            $0.whatIfBaselineClient = baselineClient
        }
    }

    public var body: some View {
        WhatIfView(store: store)
    }
}

public struct WhatIfView: View {
    @Bindable private var store: StoreOf<WhatIfFeature>

    public init(store: StoreOf<WhatIfFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    if store.isLoadingBaseline {
                        ProgressView().frame(maxWidth: .infinity)
                    }

                    if let messageKey = store.errorMessageKey {
                        WhatIfErrorLabel(messageKey: messageKey)
                    }

                    KasoCard {
                        WhatIfProjectionCard(projection: store.projection)
                    }

                    KasoCard {
                        WhatIfBaselineCard(baseline: store.baseline)
                    }

                    KasoCard {
                        WhatIfSlidersCard(
                            scenario: store.scenario,
                            onIncomeDelta: { store.send(.incomeDeltaChanged($0)) },
                            onExpenseDelta: { store.send(.expenseDeltaChanged($0)) },
                            onAdditionalSavings: { store.send(.additionalSavingsChanged($0)) },
                            onHorizon: { store.send(.horizonChanged($0)) },
                            onReturnRate: { store.send(.returnRateChanged($0)) }
                        )
                    }

                    KasoCard {
                        WhatIfGoalCard(
                            goalText: $store.goalText.sending(\.goalTextChanged),
                            monthsToGoalWithinHorizon: store.projection.monthsToGoal,
                            monthsToGoalBeyondHorizon: store.monthsToHitGoalIncludingBeyondHorizon,
                            horizonMonths: store.scenario.horizonMonths,
                            onReset: { store.send(.resetTapped) }
                        )
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.kaso.surfacePrimary)
            .navigationTitle(Text("whatIf.title", bundle: .module))
            .task {
                await store.send(.task).finish()
            }
        }
    }
}

private struct WhatIfErrorLabel: View {
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
