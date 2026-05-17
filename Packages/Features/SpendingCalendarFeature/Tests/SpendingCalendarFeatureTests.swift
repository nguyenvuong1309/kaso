import ComposableArchitecture
import Foundation
import SpendingCalendarDomain
import Testing
@testable import SpendingCalendarFeature

@MainActor
@Test("loads transactions and recurring on task")
func loadsOnTask() async throws {
    let reference = Date(timeIntervalSinceReferenceDate: 1_000_000)
    let txs = [
        SpendingCalendarTransaction(amount: 100_000, occurredAt: reference, label: "Cafe"),
    ]
    let recurring = [
        SpendingCalendarRecurringEvent(
            label: "Internet",
            amount: 250_000,
            firstOccurrence: reference,
            intervalDays: 30
        ),
    ]
    let store = TestStore(initialState: SpendingCalendarFeature.State()) {
        SpendingCalendarFeature()
    } withDependencies: {
        $0.date.now = reference
        $0.spendingCalendarContextClient.fetchTransactions = { txs }
        $0.spendingCalendarContextClient.fetchRecurringEvents = { recurring }
    }

    await store.send(.task) {
        $0.referenceDate = reference
        $0.displayedMonth = reference
        $0.isLoading = true
    }
    await store.receive(.dataLoaded(transactions: txs, recurring: recurring)) {
        $0.isLoading = false
        $0.transactions = txs
        $0.recurringEvents = recurring
    }
}

@MainActor
@Test("navigation moves displayed month and clears selection")
func navigationMovesMonth() async {
    let reference = Date(timeIntervalSinceReferenceDate: 1_000_000)
    let store = TestStore(
        initialState: SpendingCalendarFeature.State(
            referenceDate: reference,
            displayedMonth: reference,
            selectedDate: reference
        )
    ) {
        SpendingCalendarFeature()
    }

    await store.send(.previousMonthTapped) {
        $0.displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: reference) ?? reference
        $0.selectedDate = nil
    }
    await store.send(.nextMonthTapped) {
        $0.displayedMonth = Calendar.current.date(byAdding: .month, value: 0, to: reference) ?? reference
    }
}

@MainActor
@Test("todayTapped resets month and selects today")
func todayTappedResetsMonth() async {
    let reference = Date(timeIntervalSinceReferenceDate: 1_000_000)
    let store = TestStore(
        initialState: SpendingCalendarFeature.State(
            referenceDate: reference,
            displayedMonth: Date(timeIntervalSinceReferenceDate: 0)
        )
    ) {
        SpendingCalendarFeature()
    } withDependencies: {
        $0.date.now = reference
    }

    await store.send(.todayTapped) {
        $0.displayedMonth = reference
        $0.selectedDate = reference
    }
}
