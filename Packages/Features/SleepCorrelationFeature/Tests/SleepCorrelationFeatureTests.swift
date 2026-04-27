import Foundation
import ComposableArchitecture
import SleepCorrelationDomain
import Testing
import TransactionDomain
@testable import SleepCorrelationFeature

@MainActor
@Test("task requests no data when permission is denied")
func taskRequestsNoDataWhenPermissionDenied() async {
    let store = TestStore(initialState: SleepCorrelationFeature.State()) {
        SleepCorrelationFeature()
    } withDependencies: {
        $0.healthSleepClient.authorizationStatus = { .sharingDenied }
    }

    await store.send(.task) {
        $0.isLoading = true
    }
    await store.receive(.authorizationStatusLoaded(.sharingDenied)) {
        $0.healthAuthorizationStatus = .sharingDenied
        $0.isLoading = false
    }
}

@MainActor
@Test("authorized task loads data and computes insight")
func authorizedTaskLoadsDataAndComputesInsight() async {
    let points = (0..<21).map {
        SleepSpendingDataPoint(
            date: Date(timeIntervalSinceReferenceDate: Double($0) * 86_400),
            sleepHours: 7,
            totalSpending: 100_000,
            transactionCount: 1,
            categories: []
        )
    }
    let store = TestStore(initialState: SleepCorrelationFeature.State()) {
        SleepCorrelationFeature()
    } withDependencies: {
        $0.healthSleepClient.authorizationStatus = { .sharingAuthorized }
        $0.sleepCorrelationDataClient.loadDataPoints = { points }
        $0.date.now = Date(timeIntervalSinceReferenceDate: 21 * 86_400)
    }

    await store.send(.task) {
        $0.isLoading = true
    }
    await store.receive(.authorizationStatusLoaded(.sharingAuthorized)) {
        $0.healthAuthorizationStatus = .sharingAuthorized
    }
    await store.receive(.loadData)
    await store.receive(.dataLoaded(points)) {
        $0.isLoading = false
        $0.dataPoints = points
        $0.insight = SleepCorrelationAnalyzer.compute(dataPoints: points)
    }
}

@MainActor
@Test("changing period recomputes from filtered points")
func changingPeriodRecomputesFromFilteredPoints() async {
    let oldPoint = SleepSpendingDataPoint(
        date: Date(timeIntervalSinceReferenceDate: -100 * 86_400),
        sleepHours: 5,
        totalSpending: 300_000,
        transactionCount: 2,
        categories: []
    )
    let recentPoints = (0..<25).map {
        SleepSpendingDataPoint(
            date: Date(timeIntervalSinceReferenceDate: Double($0) * 86_400),
            sleepHours: 7,
            totalSpending: 100_000,
            transactionCount: 1,
            categories: []
        )
    }
    let store = TestStore(
        initialState: SleepCorrelationFeature.State(
            dataPoints: [oldPoint] + recentPoints,
            selectedPeriod: .all
        )
    ) {
        SleepCorrelationFeature()
    } withDependencies: {
        $0.date.now = Date(timeIntervalSinceReferenceDate: 24 * 86_400)
    }

    await store.send(.periodChanged(.lastThirtyDays)) {
        $0.selectedPeriod = .lastThirtyDays
        $0.insight = SleepCorrelationAnalyzer.compute(dataPoints: recentPoints)
    }
}
