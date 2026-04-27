import Foundation
import ComposableArchitecture
import FreelancerDomain
import Testing
@testable import FreelancerFeature

@MainActor
@Test("task loads profile and computes smoothed view")
func taskLoadsProfileAndComputesView() async {
    let now = Date(timeIntervalSinceReferenceDate: 799_200_000)
    let profile = FreelancerProfile(
        monthlyIncomes: [
            MonthlyIncome(month: YearMonth(year: 2026, month: 4), grossAmount: 18_000_000),
        ],
        bufferBalance: 12_000_000,
        bufferTargetMultiplier: 2,
        workType: .freelancer,
        taxRate: 0.1
    )
    let expectedView = FreelancerIncomeSmoother.compute(
        profile: profile,
        window: profile.smoothingWindow,
        asOf: now
    )
    let expectedReminders = FreelancerIncomeSmoother.reminders(
        for: profile,
        view: expectedView,
        asOf: now
    )
    let store = TestStore(initialState: FreelancerFeature.State()) {
        FreelancerFeature()
    } withDependencies: {
        $0.freelancerProfileRepository.load = { profile }
        $0.date.now = now
    }

    await store.send(.task) {
        $0.isLoading = true
        $0.errorMessageKey = nil
    }
    await store.receive(.profileLoaded(profile)) {
        $0.isLoading = false
        $0.profile = profile
        $0.incomeHistory = profile.monthlyIncomes
        $0.selectedWindow = profile.smoothingWindow
        $0.bufferBalanceText = "12000000"
        $0.bufferTargetMonthsText = "2"
        $0.taxRateText = "10"
        $0.workType = .freelancer
        $0.smoothedView = expectedView
        $0.reminders = expectedReminders
    }
}

@MainActor
@Test("changing smoothing window recomputes immediately")
func changingSmoothingWindowRecomputesImmediately() async {
    let now = Date(timeIntervalSinceReferenceDate: 799_200_000)
    let profile = FreelancerProfile(
        monthlyIncomes: [
            MonthlyIncome(month: YearMonth(year: 2026, month: 2), grossAmount: 10_000_000),
            MonthlyIncome(month: YearMonth(year: 2026, month: 3), grossAmount: 20_000_000),
            MonthlyIncome(month: YearMonth(year: 2026, month: 4), grossAmount: 30_000_000),
        ],
        smoothingWindow: .threeMonths,
        bufferBalance: 10_000_000,
        bufferTargetMultiplier: 2,
        workType: .freelancer
    )
    var expectedProfile = profile
    expectedProfile.smoothingWindow = .sixMonths
    let expectedView = FreelancerIncomeSmoother.compute(
        profile: expectedProfile,
        window: .sixMonths,
        asOf: now
    )
    let expectedReminders = FreelancerIncomeSmoother.reminders(
        for: expectedProfile,
        view: expectedView,
        asOf: now
    )
    let store = TestStore(initialState: FreelancerFeature.State(profile: profile)) {
        FreelancerFeature()
    } withDependencies: {
        $0.date.now = now
    }

    await store.send(.smoothingWindowChanged(.sixMonths)) {
        $0.selectedWindow = .sixMonths
        $0.profile?.smoothingWindow = .sixMonths
        $0.smoothedView = expectedView
        $0.reminders = expectedReminders
    }
}

@MainActor
@Test("saving income appends to history and persists profile")
func savingIncomeAppendsToHistoryAndPersistsProfile() async {
    let now = Date(timeIntervalSinceReferenceDate: 799_200_000)
    let profileID = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
    let expectedProfile = FreelancerProfile(
        id: profileID,
        monthlyIncomes: [
            MonthlyIncome(month: YearMonth(date: now), grossAmount: 24_000_000),
        ],
        smoothingWindow: .threeMonths,
        bufferBalance: 0,
        bufferTargetMultiplier: 2,
        workType: .freelancer,
        taxRate: nil,
        createdAt: now,
        updatedAt: now
    )
    let expectedView = FreelancerIncomeSmoother.compute(
        profile: expectedProfile,
        window: .threeMonths,
        asOf: now
    )
    let expectedReminders = FreelancerIncomeSmoother.reminders(
        for: expectedProfile,
        view: expectedView,
        asOf: now
    )
    let store = TestStore(initialState: FreelancerFeature.State(incomeDate: now)) {
        FreelancerFeature()
    } withDependencies: {
        $0.freelancerProfileRepository.save = { _ in }
        $0.uuid = .incrementing
        $0.date.now = now
    }

    await store.send(.incomeGrossTextChanged("24000000")) {
        $0.incomeGrossText = "24000000"
    }
    await store.send(.saveIncomeButtonTapped) {
        $0.isSavingIncome = true
    }
    await store.receive(.incomeSaved(expectedProfile)) {
        $0.isSavingIncome = false
        $0.isIncomeEditorPresented = false
        $0.profile = expectedProfile
        $0.incomeHistory = expectedProfile.monthlyIncomes
        $0.bufferBalanceText = "0"
        $0.bufferTargetMonthsText = "2"
        $0.taxRateText = ""
        $0.workType = .freelancer
        $0.smoothedView = expectedView
        $0.reminders = expectedReminders
        $0.incomeGrossText = ""
        $0.incomeDeductionText = ""
    }
}
