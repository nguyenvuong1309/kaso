import Foundation
import ComposableArchitecture
import InsightDomain
import Testing
import TransactionDomain
@testable import BenchmarkFeature

@MainActor
@Test("opening benchmark loads transactions and inferred income band")
func openingBenchmarkLoadsTransactionsAndInferredIncomeBand() async throws {
    let now = try date(2026, 4, 30)
    let transactions = [
        Transaction(
            amount: 3_000_000,
            kind: .expense,
            category: .food,
            occurredAt: now
        ),
    ]
    let profile = AnonymousBenchmarkProfile(
        city: .hoChiMinh,
        ageGroup: .twentyFiveToThirtyFour,
        incomeBand: .twentyToFortyMillion
    )
    let report = AnonymousBenchmarkReporter.report(
        transactions: transactions,
        profile: profile,
        referenceDate: now
    )
    let store = TestStore(initialState: BenchmarkFeature.State()) {
        BenchmarkFeature()
    } withDependencies: {
        $0.date.now = now
        $0.benchmarkContextClient.loadTransactions = { transactions }
        $0.benchmarkContextClient.defaultMonthlyIncome = { 30_000_000 }
    }

    await store.send(.floatingButtonTapped) {
        $0.isPresented = true
        $0.isLoading = true
        $0.referenceDate = now
    }
    await store.receive(.contextLoaded(transactions, 30_000_000)) {
        $0.isLoading = false
        $0.transactions = transactions
        $0.profile = profile
        $0.report = report
    }
}

@MainActor
@Test("changing cohort recomputes report without reloading")
func changingCohortRecomputesReportWithoutReloading() async throws {
    let now = try date(2026, 4, 30)
    let transactions = [
        Transaction(
            amount: 2_000_000,
            kind: .expense,
            category: .transport,
            occurredAt: now
        ),
    ]
    let initialProfile = AnonymousBenchmarkProfile(
        city: .hoChiMinh,
        ageGroup: .twentyFiveToThirtyFour,
        incomeBand: .tenToTwentyMillion
    )
    var expectedProfile = initialProfile
    expectedProfile.city = .daNang
    let expectedReport = AnonymousBenchmarkReporter.report(
        transactions: transactions,
        profile: expectedProfile,
        referenceDate: now
    )
    let store = TestStore(
        initialState: BenchmarkFeature.State(
            transactions: transactions,
            profile: initialProfile,
            referenceDate: now
        )
    ) {
        BenchmarkFeature()
    }

    await store.send(.cityChanged(.daNang)) {
        $0.profile.city = .daNang
        $0.report = expectedReport
    }
}

@MainActor
@Test("load failure surfaces error")
func loadFailureSurfacesError() async {
    struct LoadFailure: Error {}

    let store = TestStore(initialState: BenchmarkFeature.State()) {
        BenchmarkFeature()
    } withDependencies: {
        $0.date.now = Date(timeIntervalSinceReferenceDate: 0)
        $0.benchmarkContextClient.loadTransactions = {
            throw LoadFailure()
        }
    }

    await store.send(.floatingButtonTapped) {
        $0.isPresented = true
        $0.isLoading = true
    }
    await store.receive(.contextLoadFailed) {
        $0.isLoading = false
        $0.errorMessageKey = "benchmark.error.loadFailed"
    }
}

private func date(
    _ year: Int,
    _ month: Int,
    _ day: Int
) throws -> Date {
    try #require(
        DateComponents(
            calendar: Calendar(identifier: .gregorian),
            year: year,
            month: month,
            day: day,
            hour: 12
        ).date
    )
}
