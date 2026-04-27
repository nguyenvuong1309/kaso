import SwiftUI
import ComposableArchitecture
import InsightDomain
import KasoDesignSystem

public struct BenchmarkView: View {
    @Bindable private var store: StoreOf<BenchmarkFeature>
    @Environment(\.dismiss) private var dismiss

    public init(store: StoreOf<BenchmarkFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    BenchmarkIntroCard()
                    cohortPicker

                    if store.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }

                    if let errorMessageKey = store.errorMessageKey {
                        Text(LocalizedStringKey(errorMessageKey), bundle: .module)
                            .font(.kaso.caption)
                            .foregroundStyle(Color.kaso.destructive)
                    }

                    if let report = store.report {
                        BenchmarkSummaryCard(report: report)
                        BenchmarkComparisonList(comparisons: report.topComparisons)
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.kaso.surfaceSecondary)
            .navigationTitle(Text("benchmark.title", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        store.send(.sheetDismissed)
                        dismiss()
                    } label: {
                        Text("benchmark.close", bundle: .module)
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.send(.refreshButtonTapped)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(store.isLoading)
                    .accessibilityLabel(Text("benchmark.refresh", bundle: .module))
                }
            }
        }
    }

    private var cohortPicker: some View {
        KasoCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("benchmark.cohort.title", bundle: .module)
                    .font(.kaso.titleMedium)
                    .foregroundStyle(Color.kaso.textPrimary)

                BenchmarkPicker(
                    titleKey: "benchmark.cohort.city",
                    selection: cityBinding,
                    values: AnonymousBenchmarkCity.allCases
                )
                BenchmarkPicker(
                    titleKey: "benchmark.cohort.age",
                    selection: ageGroupBinding,
                    values: AnonymousBenchmarkAgeGroup.allCases
                )
                BenchmarkPicker(
                    titleKey: "benchmark.cohort.income",
                    selection: incomeBandBinding,
                    values: AnonymousBenchmarkIncomeBand.allCases
                )
            }
        }
    }

    private var cityBinding: Binding<AnonymousBenchmarkCity> {
        Binding(
            get: { store.profile.city },
            set: { store.send(.cityChanged($0)) }
        )
    }

    private var ageGroupBinding: Binding<AnonymousBenchmarkAgeGroup> {
        Binding(
            get: { store.profile.ageGroup },
            set: { store.send(.ageGroupChanged($0)) }
        )
    }

    private var incomeBandBinding: Binding<AnonymousBenchmarkIncomeBand> {
        Binding(
            get: { store.profile.incomeBand },
            set: { store.send(.incomeBandChanged($0)) }
        )
    }
}

private struct BenchmarkIntroCard: View {
    var body: some View {
        KasoCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Label {
                    Text("benchmark.intro.title", bundle: .module)
                        .font(.kaso.titleMedium)
                } icon: {
                    Image(systemName: "person.2.wave.2")
                        .foregroundStyle(Color.kaso.accent)
                }

                Text("benchmark.intro.description", bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textSecondary)
            }
        }
    }
}

private struct BenchmarkPicker<Value: CaseIterable & Identifiable & Hashable>: View
where Value.AllCases: RandomAccessCollection, Value: BenchmarkTitleProviding {
    let titleKey: String
    @Binding var selection: Value
    let values: Value.AllCases

    var body: some View {
        Picker(
            selection: $selection,
            label: Text(LocalizedStringKey(titleKey), bundle: .module)
        ) {
            ForEach(values) { value in
                Text(LocalizedStringKey(value.titleKey), bundle: .module)
                    .tag(value)
            }
        }
        .pickerStyle(.menu)
    }
}

private protocol BenchmarkTitleProviding {
    var titleKey: String { get }
}

extension AnonymousBenchmarkCity: BenchmarkTitleProviding {}
extension AnonymousBenchmarkAgeGroup: BenchmarkTitleProviding {}
extension AnonymousBenchmarkIncomeBand: BenchmarkTitleProviding {}
