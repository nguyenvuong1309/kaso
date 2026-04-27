import ComposableArchitecture
import Foundation
import Testing
import TransactionDomain
import WellnessDomain
@testable import HoursOfLifeFeature

@MainActor
@Test("loads stored configuration and recent transactions on task")
func loadsStoredConfigurationAndRecentTransactionsOnTask() async throws {
    let configuration = HoursOfLifeConfiguration(
        monthlyNetIncome: 20_000_000,
        averageMonthlyWorkHours: 160
    )
    let now = try date(2026, 4, 27)
    let yesterday = try date(2026, 4, 26)
    let recent = Transaction(
        amount: 65_000,
        kind: .expense,
        category: .food,
        occurredAt: now
    )
    let older = Transaction(
        amount: 320_000,
        kind: .expense,
        category: .transport,
        occurredAt: yesterday
    )
    let income = Transaction(
        amount: 18_000_000,
        kind: .income,
        category: .salary,
        occurredAt: yesterday
    )

    let store = TestStore(initialState: HoursOfLifeFeature.State()) {
        HoursOfLifeFeature()
    } withDependencies: {
        $0.hoursOfLifeConfigurationRepository.load = { configuration }
        $0.hoursOfLifeContextClient.recentTransactions = { [recent, older, income] }
        $0.hoursOfLifeContextClient.defaultMonthlyIncome = { 20_000_000 }
    }

    await store.send(.task) {
        $0.isLoading = true
    }
    await store.receive(.configurationLoaded(configuration)) {
        $0.isLoading = false
        $0.configuration = configuration
        $0.monthlyNetIncomeText = "20000000"
        $0.monthlyWorkHoursText = "160"
    }
    await store.receive(.transactionsLoaded([recent, older, income])) {
        $0.recentExpenses = [recent, older]
    }
}

@MainActor
@Test("falls back to onboarding income when no configuration is stored")
func fallsBackToOnboardingIncomeWhenNoConfigurationIsStored() async {
    let store = TestStore(initialState: HoursOfLifeFeature.State()) {
        HoursOfLifeFeature()
    } withDependencies: {
        $0.hoursOfLifeConfigurationRepository.load = { nil }
        $0.hoursOfLifeContextClient.recentTransactions = { [] }
        $0.hoursOfLifeContextClient.defaultMonthlyIncome = { 24_000_000 }
    }

    await store.send(.task) {
        $0.isLoading = true
    }
    await store.receive(.configurationLoaded(nil)) {
        $0.isLoading = false
    }
    await store.receive(.transactionsLoaded([]))
    await store.receive(.onboardingFallbackLoaded(24_000_000)) {
        $0.configuration = HoursOfLifeConfiguration(
            monthlyNetIncome: 24_000_000,
            averageMonthlyWorkHours: 160
        )
        $0.monthlyNetIncomeText = "24000000"
        $0.monthlyWorkHoursText = "160"
    }
}

@MainActor
@Test("does not override stored configuration with onboarding fallback")
func doesNotOverrideStoredConfigurationWithOnboardingFallback() async {
    let configuration = HoursOfLifeConfiguration(
        monthlyNetIncome: 18_000_000,
        averageMonthlyWorkHours: 168
    )
    let store = TestStore(
        initialState: HoursOfLifeFeature.State(configuration: configuration)
    ) {
        HoursOfLifeFeature()
    }

    await store.send(.onboardingFallbackLoaded(40_000_000))
}

@MainActor
@Test("ignores onboarding fallback when income is missing or non-positive")
func ignoresOnboardingFallbackWhenIncomeIsMissingOrNonPositive() async {
    let store = TestStore(initialState: HoursOfLifeFeature.State()) {
        HoursOfLifeFeature()
    }

    await store.send(.onboardingFallbackLoaded(nil))
    await store.send(.onboardingFallbackLoaded(0))
    await store.send(.onboardingFallbackLoaded(-1))
}

@MainActor
@Test("calculator amount changes update conversion via state")
func calculatorAmountChangesUpdateConversionViaState() async {
    let configuration = HoursOfLifeConfiguration(
        monthlyNetIncome: 20_000_000,
        averageMonthlyWorkHours: 160
    )
    let store = TestStore(
        initialState: HoursOfLifeFeature.State(configuration: configuration)
    ) {
        HoursOfLifeFeature()
    }

    await store.send(.calculatorAmountChanged("62.500")) {
        $0.calculatorAmountText = "62.500"
    }

    let conversion = store.state.calculatorConversion
    #expect(conversion?.workMinutes == 30)
    #expect(conversion?.wholeHours == 0)
    #expect(conversion?.remainingMinutes == 30)
}

@MainActor
@Test("saves new configuration from settings sheet")
func savesNewConfigurationFromSettingsSheet() async {
    let expected = HoursOfLifeConfiguration(
        monthlyNetIncome: 24_000_000,
        averageMonthlyWorkHours: 168
    )
    let store = TestStore(initialState: HoursOfLifeFeature.State()) {
        HoursOfLifeFeature()
    } withDependencies: {
        $0.hoursOfLifeConfigurationRepository.save = { _ in }
    }

    await store.send(.settingsButtonTapped) {
        $0.isSettingsPresented = true
    }
    await store.send(.incomeTextChanged("24.000.000")) {
        $0.monthlyNetIncomeText = "24.000.000"
    }
    await store.send(.workHoursTextChanged("168")) {
        $0.monthlyWorkHoursText = "168"
    }
    await store.send(.saveSettingsButtonTapped) {
        $0.isSavingSettings = true
    }
    await store.receive(.settingsSaved(expected)) {
        $0.isSavingSettings = false
        $0.isSettingsPresented = false
        $0.configuration = expected
        $0.monthlyNetIncomeText = "24000000"
        $0.monthlyWorkHoursText = "168"
    }
}

@MainActor
@Test("rejects invalid income input in settings")
func rejectsInvalidIncomeInputInSettings() async {
    let store = TestStore(
        initialState: HoursOfLifeFeature.State(
            isSettingsPresented: true,
            monthlyNetIncomeText: "0",
            monthlyWorkHoursText: "160"
        )
    ) {
        HoursOfLifeFeature()
    }

    await store.send(.saveSettingsButtonTapped) {
        $0.settingsErrorMessageKey = "hoursOfLife.error.incomeMustBePositive"
    }
}

@MainActor
@Test("rejects invalid work hours input in settings")
func rejectsInvalidWorkHoursInputInSettings() async {
    let store = TestStore(
        initialState: HoursOfLifeFeature.State(
            isSettingsPresented: true,
            monthlyNetIncomeText: "20000000",
            monthlyWorkHoursText: "0"
        )
    ) {
        HoursOfLifeFeature()
    }

    await store.send(.saveSettingsButtonTapped) {
        $0.settingsErrorMessageKey = "hoursOfLife.error.workHoursMustBePositive"
    }
}

@MainActor
@Test("surfaces save failures from configuration repository")
func surfacesSaveFailuresFromConfigurationRepository() async {
    struct StubFailure: Error {}
    let store = TestStore(
        initialState: HoursOfLifeFeature.State(
            isSettingsPresented: true,
            monthlyNetIncomeText: "20000000",
            monthlyWorkHoursText: "160"
        )
    ) {
        HoursOfLifeFeature()
    } withDependencies: {
        $0.hoursOfLifeConfigurationRepository.save = { _ in throw StubFailure() }
    }

    await store.send(.saveSettingsButtonTapped) {
        $0.isSavingSettings = true
    }
    await store.receive(.saveSettingsFailed("hoursOfLife.error.saveFailed")) {
        $0.isSavingSettings = false
        $0.settingsErrorMessageKey = "hoursOfLife.error.saveFailed"
    }
}

@MainActor
@Test("only converts expenses among recent transactions")
func onlyConvertsExpensesAmongRecentTransactions() async {
    let configuration = HoursOfLifeConfiguration(
        monthlyNetIncome: 20_000_000,
        averageMonthlyWorkHours: 160
    )
    let expense = Transaction(
        amount: 150_000,
        kind: .expense,
        category: .food,
        occurredAt: Date()
    )
    let income = Transaction(
        amount: 5_000_000,
        kind: .income,
        category: .salary,
        occurredAt: Date()
    )

    let store = TestStore(
        initialState: HoursOfLifeFeature.State(configuration: configuration)
    ) {
        HoursOfLifeFeature()
    }

    await store.send(.transactionsLoaded([income, expense])) {
        $0.recentExpenses = [expense]
    }

    let rows = store.state.conversionRows
    #expect(rows.count == 1)
    #expect(rows.first?.transaction == expense)
    #expect(rows.first?.conversion.workMinutes == 72)
}

private func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
    let calendar = Calendar(identifier: .gregorian)
    return try #require(
        DateComponents(
            calendar: calendar,
            year: year,
            month: month,
            day: day
        ).date
    )
}
