import ComposableArchitecture
import KasoDesignSystem
import SpendingCalendarDomain
import SwiftUI

public struct SpendingCalendarRootView: View {
    private let store: StoreOf<SpendingCalendarFeature>

    public init(contextClient: SpendingCalendarContextClient = .empty) {
        store = Store(initialState: SpendingCalendarFeature.State()) {
            SpendingCalendarFeature()
        } withDependencies: {
            $0.spendingCalendarContextClient = contextClient
        }
    }

    public var body: some View {
        SpendingCalendarView(store: store)
    }
}

public struct SpendingCalendarView: View {
    @Bindable private var store: StoreOf<SpendingCalendarFeature>

    public init(store: StoreOf<SpendingCalendarFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    if store.isLoading {
                        ProgressView().frame(maxWidth: .infinity)
                    }

                    if let messageKey = store.errorMessageKey {
                        SpendingCalendarErrorLabel(messageKey: messageKey)
                    }

                    KasoCard {
                        SpendingCalendarHeaderCard(
                            month: store.calendar.month,
                            actualTotal: store.calendar.actualTotal,
                            forecastTotal: store.calendar.forecastTotal,
                            onPrevious: { store.send(.previousMonthTapped) },
                            onNext: { store.send(.nextMonthTapped) },
                            onToday: { store.send(.todayTapped) }
                        )
                    }

                    KasoCard {
                        SpendingCalendarGrid(
                            month: store.calendar,
                            referenceDate: store.referenceDate,
                            selectedDate: store.selectedDate,
                            onSelectDay: { store.send(.daySelected($0)) }
                        )
                    }

                    if let topDay = store.calendar.topDay {
                        KasoCard {
                            SpendingCalendarTopDayCard(day: topDay)
                        }
                    }

                    if let day = store.selectedDay {
                        KasoCard {
                            SpendingCalendarDayCard(day: day)
                        }
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.kaso.surfacePrimary)
            .navigationTitle(Text("calendar.title", bundle: .module))
            .task {
                await store.send(.task).finish()
            }
        }
    }
}

private struct SpendingCalendarErrorLabel: View {
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
