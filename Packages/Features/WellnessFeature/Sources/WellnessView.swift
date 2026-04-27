import ComposableArchitecture
import CompatibilityFeature
import FreelancerFeature
import HoursOfLifeFeature
import KasoDesignSystem
import LegacyFeature
import PhantomExpenseFeature
import SleepCorrelationFeature
import SwiftUI

public struct WellnessView: View {
    @Bindable private var store: StoreOf<WellnessFeature>

    public init(store: StoreOf<WellnessFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            Picker(
                selection: $store.section.sending(\.sectionChanged)
            ) {
                ForEach(WellnessFeature.Section.allCases) { section in
                    Text(LocalizedStringKey(section.titleKey), bundle: .module)
                        .tag(section)
                }
            } label: {
                Text("wellness.section.label", bundle: .module)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color.kaso.surfacePrimary)

            switch store.section {
            case .hoursOfLife:
                HoursOfLifeView(
                    store: store.scope(state: \.hoursOfLife, action: \.hoursOfLife)
                )
            case .phantomExpense:
                PhantomExpenseView(
                    store: store.scope(state: \.phantomExpense, action: \.phantomExpense)
                )
            case .compatibility:
                CompatibilityView(
                    store: store.scope(state: \.compatibility, action: \.compatibility)
                )
            case .freelancer:
                FreelancerView(
                    store: store.scope(state: \.freelancer, action: \.freelancer)
                )
            case .sleepCorrelation:
                SleepCorrelationView(
                    store: store.scope(state: \.sleepCorrelation, action: \.sleepCorrelation)
                )
            case .legacy:
                LegacyView(
                    store: store.scope(state: \.legacy, action: \.legacy)
                )
            }
        }
    }
}
