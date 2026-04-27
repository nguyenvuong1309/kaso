import ComposableArchitecture
import KasoDesignSystem
import SwiftUI
import TransactionDomain
import WellnessDomain

public struct HoursOfLifeRootView: View {
    private let store: StoreOf<HoursOfLifeFeature>

    public init(
        configurationRepository: HoursOfLifeConfigurationRepository = .empty,
        contextClient: HoursOfLifeContextClient = .empty
    ) {
        store = Store(initialState: HoursOfLifeFeature.State()) {
            HoursOfLifeFeature()
        } withDependencies: {
            $0.hoursOfLifeConfigurationRepository = configurationRepository
            $0.hoursOfLifeContextClient = contextClient
        }
    }

    public var body: some View {
        HoursOfLifeView(store: store)
    }
}

public struct HoursOfLifeView: View {
    @Bindable private var store: StoreOf<HoursOfLifeFeature>

    public init(store: StoreOf<HoursOfLifeFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    if store.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }

                    if let errorMessageKey = store.errorMessageKey {
                        HoursOfLifeErrorLabel(messageKey: errorMessageKey)
                    }

                    if let configuration = store.configuration {
                        KasoCard {
                            HoursOfLifeRateCard(configuration: configuration)
                        }
                    } else if store.isLoading == false {
                        KasoCard {
                            HoursOfLifeOnboardingCard {
                                store.send(.settingsButtonTapped)
                            }
                        }
                    }

                    KasoCard {
                        HoursOfLifeCalculatorCard(
                            amountText: $store.calculatorAmountText
                                .sending(\.calculatorAmountChanged),
                            conversion: store.calculatorConversion,
                            isConfigured: store.configuration != nil
                        )
                    }

                    KasoCard {
                        HoursOfLifeRecentCard(rows: store.conversionRows)
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.kaso.surfacePrimary)
            .navigationTitle(Text("hoursOfLife.title", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.send(.settingsButtonTapped)
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    .accessibilityLabel(Text("hoursOfLife.settings.button", bundle: .module))
                }
            }
            .sheet(isPresented: settingsPresented) {
                HoursOfLifeSettingsSheet(store: store)
                    .presentationDetents([.medium, .large])
            }
            .task {
                await store.send(.task).finish()
            }
        }
    }

    private var settingsPresented: Binding<Bool> {
        Binding(
            get: { store.isSettingsPresented },
            set: { isPresented in
                if isPresented == false {
                    store.send(.settingsDismissed)
                }
            }
        )
    }
}

private struct HoursOfLifeErrorLabel: View {
    let messageKey: String

    var body: some View {
        Label {
            Text(LocalizedStringKey(messageKey), bundle: .module)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.kaso.destructive)
        }
        .font(.kaso.caption)
        .foregroundStyle(Color.kaso.destructive)
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Color.kaso.destructive.opacity(Layout.alertBackgroundOpacity))
        )
    }
}

private enum Layout {
    static let alertBackgroundOpacity: Double = 0.12
}
