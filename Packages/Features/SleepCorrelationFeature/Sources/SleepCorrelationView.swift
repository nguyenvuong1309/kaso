import SwiftUI
import ComposableArchitecture
import KasoDesignSystem
import SleepCorrelationDomain

public struct SleepCorrelationRootView: View {
    private let store: StoreOf<SleepCorrelationFeature>

    public init(
        healthSleepClient: HealthSleepClient = .empty,
        dataClient: SleepCorrelationDataClient = .empty
    ) {
        store = Store(initialState: SleepCorrelationFeature.State()) {
            SleepCorrelationFeature()
        } withDependencies: {
            $0.healthSleepClient = healthSleepClient
            $0.sleepCorrelationDataClient = dataClient
        }
    }

    public var body: some View {
        SleepCorrelationView(store: store)
    }
}

public struct SleepCorrelationView: View {
    @Bindable private var store: StoreOf<SleepCorrelationFeature>

    public init(store: StoreOf<SleepCorrelationFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    if store.healthAuthorizationStatus != .sharingAuthorized {
                        SleepPermissionBanner {
                            store.send(.requestHealthKitPermission)
                        }
                    }

                    if store.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }

                    if let errorMessageKey = store.errorMessageKey {
                        SleepErrorLabel(messageKey: errorMessageKey)
                    }

                    SleepPeriodPicker(
                        selectedPeriod: $store.selectedPeriod.sending(\.periodChanged)
                    )

                    if let insight = store.insight,
                       insight.significance != .insufficient {
                        KasoCard {
                            SleepScatterPlotCard(points: store.dataPoints)
                        }
                        KasoCard {
                            SleepInsightCard(
                                insight: insight,
                                isExpanded: store.isInsightExpanded,
                                onToggle: {
                                    store.send(.insightExpandedToggled)
                                }
                            )
                        }
                        KasoCard {
                            SleepQualityBreakdown(points: store.dataPoints)
                        }
                    } else {
                        KasoCard {
                            SleepInsufficientDataView(
                                currentCount: store.insight?.dataPointCount ?? store.dataPoints.count
                            )
                        }
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.kaso.surfacePrimary)
            .navigationTitle(Text("sleep.title", bundle: .module))
            .task {
                await store.send(.task).finish()
            }
        }
    }
}

private struct SleepErrorLabel: View {
    let messageKey: String

    var body: some View {
        Label {
            Text(LocalizedStringKey(messageKey), bundle: .module)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
        }
        .font(.kaso.caption)
        .foregroundStyle(Color.kaso.destructive)
    }
}
