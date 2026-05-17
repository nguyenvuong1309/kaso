import ComposableArchitecture
import Foundation
import GuiltFreeBudgetDomain
import Testing
@testable import GuiltFreeBudgetFeature

@MainActor
@Test("loads configuration on task")
func loadsConfigurationOnTask() async throws {
    let referenceDate = try date(2026, 4, 26)
    let config = GuiltFreeBudgetConfiguration(monthlyIncome: 10_000_000)
    let store = TestStore(initialState: GuiltFreeBudgetFeature.State()) {
        GuiltFreeBudgetFeature()
    } withDependencies: {
        $0.date.now = referenceDate
        $0.guiltFreeBudgetRepository.load = { config }
    }

    await store.send(.task) {
        $0.referenceDate = referenceDate
        $0.isLoading = true
    }
    await store.receive(.configurationLoaded(config)) {
        $0.isLoading = false
        $0.configuration = config
    }
}

@MainActor
@Test("saving income persists the new configuration")
func savingIncomePersists() async throws {
    let referenceDate = try date(2026, 4, 26)
    let saved = LockIsolated<[GuiltFreeBudgetConfiguration]>([])
    let store = TestStore(
        initialState: GuiltFreeBudgetFeature.State(
            isIncomeEditorPresented: true,
            incomeText: "25.000.000",
            savingsText: "5.000.000",
            emergencyText: "1.000.000"
        )
    ) {
        GuiltFreeBudgetFeature()
    } withDependencies: {
        $0.date.now = referenceDate
        $0.guiltFreeBudgetRepository.save = { config in
            saved.withValue { $0.append(config) }
        }
    }

    let expected = GuiltFreeBudgetConfiguration(
        monthlyIncome: 25_000_000,
        monthlySavingsTarget: 5_000_000,
        emergencyFundMonthlyContribution: 1_000_000,
        fixedCosts: [],
        updatedAt: referenceDate
    )

    await store.send(.incomeSaveTapped) {
        $0.isIncomeEditorPresented = false
        $0.isSaving = true
        $0.configuration = expected
    }
    await store.receive(.configurationSaved(expected)) {
        $0.isSaving = false
    }

    #expect(saved.value == [expected])
}

@MainActor
@Test("invalid income shows error and stays in editor")
func invalidIncomeShowsError() async {
    let store = TestStore(
        initialState: GuiltFreeBudgetFeature.State(
            isIncomeEditorPresented: true,
            incomeText: "abc"
        )
    ) {
        GuiltFreeBudgetFeature()
    }

    await store.send(.incomeSaveTapped) {
        $0.editorErrorMessageKey = "guiltFree.error.invalidAmount"
    }
}

@MainActor
@Test("adding a fixed cost appends to configuration and saves")
func addingFixedCostAppendsAndSaves() async throws {
    let referenceDate = try date(2026, 4, 26)
    let costID = try #require(UUID(uuidString: "11111111-2222-3333-4444-555555555555"))
    let saved = LockIsolated<[GuiltFreeBudgetConfiguration]>([])
    let store = TestStore(
        initialState: GuiltFreeBudgetFeature.State(
            configuration: GuiltFreeBudgetConfiguration(monthlyIncome: 10_000_000),
            isFixedCostEditorPresented: true,
            fixedCostNameText: "Tiền nhà",
            fixedCostAmountText: "5.000.000",
            fixedCostKind: .housing
        )
    ) {
        GuiltFreeBudgetFeature()
    } withDependencies: {
        $0.date.now = referenceDate
        $0.uuid = UUIDGenerator { costID }
        $0.guiltFreeBudgetRepository.save = { config in
            saved.withValue { $0.append(config) }
        }
    }

    let expectedConfig = GuiltFreeBudgetConfiguration(
        monthlyIncome: 10_000_000,
        fixedCosts: [
            GuiltFreeFixedCost(id: costID, name: "Tiền nhà", amount: 5_000_000, kind: .housing),
        ],
        updatedAt: referenceDate
    )

    await store.send(.fixedCostSaveTapped) {
        $0.isFixedCostEditorPresented = false
        $0.isSaving = true
        $0.configuration = expectedConfig
    }
    await store.receive(.configurationSaved(expectedConfig)) {
        $0.isSaving = false
    }

    #expect(saved.value == [expectedConfig])
}

private func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
    let calendar = Calendar(identifier: .gregorian)
    return try #require(DateComponents(calendar: calendar, year: year, month: month, day: day).date)
}
