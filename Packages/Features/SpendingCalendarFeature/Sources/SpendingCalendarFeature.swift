import ComposableArchitecture
import Foundation
import SpendingCalendarDomain

@Reducer
public struct SpendingCalendarFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var referenceDate: Date
        public var displayedMonth: Date
        public var transactions: [SpendingCalendarTransaction]
        public var recurringEvents: [SpendingCalendarRecurringEvent]
        public var selectedDate: Date?
        public var isLoading: Bool
        public var errorMessageKey: String?

        public init(
            referenceDate: Date = Date(timeIntervalSinceReferenceDate: 0),
            displayedMonth: Date = Date(timeIntervalSinceReferenceDate: 0),
            transactions: [SpendingCalendarTransaction] = [],
            recurringEvents: [SpendingCalendarRecurringEvent] = [],
            selectedDate: Date? = nil,
            isLoading: Bool = false,
            errorMessageKey: String? = nil
        ) {
            self.referenceDate = referenceDate
            self.displayedMonth = displayedMonth
            self.transactions = transactions
            self.recurringEvents = recurringEvents
            self.selectedDate = selectedDate
            self.isLoading = isLoading
            self.errorMessageKey = errorMessageKey
        }

        public var calendar: SpendingCalendarMonth {
            SpendingCalendarBuilder.build(
                month: displayedMonth,
                transactions: transactions,
                recurringEvents: recurringEvents,
                referenceDate: referenceDate
            )
        }

        public var selectedDay: DailySpending? {
            guard let selectedDate else {
                return nil
            }
            return calendar.days.first { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case dataLoaded(transactions: [SpendingCalendarTransaction], recurring: [SpendingCalendarRecurringEvent])
        case loadFailed(String)
        case previousMonthTapped
        case nextMonthTapped
        case todayTapped
        case daySelected(Date?)
    }

    @Dependency(\.spendingCalendarContextClient) private var contextClient
    @Dependency(\.date) private var date

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.referenceDate = date.now
                if state.displayedMonth == Date(timeIntervalSinceReferenceDate: 0) {
                    state.displayedMonth = date.now
                }
                state.isLoading = true
                state.errorMessageKey = nil
                return .run { send in
                    do {
                        async let txs = contextClient.fetchTransactions()
                        async let recurring = contextClient.fetchRecurringEvents()
                        await send(.dataLoaded(transactions: try await txs, recurring: try await recurring))
                    } catch {
                        await send(.loadFailed("calendar.error.loadFailed"))
                    }
                }

            case let .dataLoaded(transactions, recurring):
                state.isLoading = false
                state.transactions = transactions
                state.recurringEvents = recurring
                return .none

            case let .loadFailed(messageKey):
                state.isLoading = false
                state.errorMessageKey = messageKey
                return .none

            case .previousMonthTapped:
                state.displayedMonth = Calendar.current.date(
                    byAdding: .month,
                    value: -1,
                    to: state.displayedMonth
                ) ?? state.displayedMonth
                state.selectedDate = nil
                return .none

            case .nextMonthTapped:
                state.displayedMonth = Calendar.current.date(
                    byAdding: .month,
                    value: 1,
                    to: state.displayedMonth
                ) ?? state.displayedMonth
                state.selectedDate = nil
                return .none

            case .todayTapped:
                state.displayedMonth = date.now
                state.selectedDate = date.now
                return .none

            case let .daySelected(day):
                state.selectedDate = day
                return .none
            }
        }
    }
}
