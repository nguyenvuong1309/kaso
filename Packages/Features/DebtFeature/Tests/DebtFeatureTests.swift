import Foundation
import Testing
import ComposableArchitecture
import DebtDomain
import WealthDomain
@testable import DebtFeature

@MainActor
@Test("loads debts and syncs auto tracked liabilities")
func loadsDebtsAndSyncsAutoTrackedLiabilities() async throws {
    let referenceDate = try date(2026, 4, 26)
    let debt = Debt(
        name: "Vay mua nhà",
        type: .mortgage,
        principal: 1_000_000_000,
        annualInterestRatePercent: 8,
        termMonths: 240,
        startDate: try date(2026, 1, 1),
        paymentDay: 5,
        createdAt: referenceDate
    )
    let recorder = LiabilityRecorder()
    let store = TestStore(initialState: DebtFeature.State()) {
        DebtFeature()
    } withDependencies: {
        $0.date.now = referenceDate
        $0.debtRepository.fetchAll = { [debt] }
        $0.debtLiabilitySyncClient.replaceAutoTracked = { await recorder.save($0) }
    }

    await store.send(.task) {
        $0.referenceDate = referenceDate
        $0.isLoading = true
    }
    await store.receive(.debtsLoaded([debt])) {
        $0.isLoading = false
        $0.debts = IdentifiedArray(uniqueElements: [debt])
        $0.selectedDebtID = debt.id
    }
    await store.receive(.liabilitiesSynced)

    let syncedLiabilities = await recorder.liabilities()
    #expect(syncedLiabilities.count == 1)
    #expect(syncedLiabilities.first?.id == debt.id)
    #expect(syncedLiabilities.first?.isAutoTracked == true)
}

@MainActor
@Test("saves debt from editor")
func savesDebtFromEditor() async throws {
    let referenceDate = try date(2026, 4, 26)
    let debtID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    let expectedDebt = Debt(
        id: debtID,
        name: "Vay xe",
        type: .autoLoan,
        principal: 600_000_000,
        annualInterestRatePercent: 9,
        termMonths: 60,
        startDate: referenceDate,
        paymentDay: 10,
        createdAt: referenceDate
    )
    let store = TestStore(initialState: DebtFeature.State(referenceDate: referenceDate)) {
        DebtFeature()
    } withDependencies: {
        $0.date.now = referenceDate
        $0.uuid = .incrementing
        $0.debtRepository.save = { _ in }
        $0.debtLiabilitySyncClient.replaceAutoTracked = { _ in }
    }

    await store.send(.debtAddButtonTapped) {
        $0.isDebtEditorPresented = true
        $0.editingDebtID = nil
        $0.debtNameText = ""
        $0.debtPrincipalText = ""
        $0.debtAnnualRateText = ""
        $0.debtTermMonthsText = "12"
        $0.debtPaymentDayText = "1"
        $0.debtMonthlyPaymentText = ""
        $0.debtStartDate = referenceDate
        $0.debtType = .personalLoan
        $0.debtNoteText = ""
        $0.debtEditorErrorMessageKey = nil
    }
    await store.send(.debtNameTextChanged(" Vay xe ")) {
        $0.debtNameText = " Vay xe "
        $0.debtEditorErrorMessageKey = nil
    }
    await store.send(.debtTypeChanged(.autoLoan)) {
        $0.debtType = .autoLoan
        $0.debtEditorErrorMessageKey = nil
    }
    await store.send(.debtPrincipalTextChanged("600.000.000")) {
        $0.debtPrincipalText = "600.000.000"
        $0.debtEditorErrorMessageKey = nil
    }
    await store.send(.debtAnnualRateTextChanged("9")) {
        $0.debtAnnualRateText = "9"
        $0.debtEditorErrorMessageKey = nil
    }
    await store.send(.debtTermMonthsTextChanged("60")) {
        $0.debtTermMonthsText = "60"
        $0.debtEditorErrorMessageKey = nil
    }
    await store.send(.debtPaymentDayTextChanged("10")) {
        $0.debtPaymentDayText = "10"
        $0.debtEditorErrorMessageKey = nil
    }
    await store.send(.debtSaveButtonTapped) {
        $0.isDebtSaving = true
    }
    await store.receive(.debtSaved(expectedDebt)) {
        $0.isDebtSaving = false
        $0.isDebtEditorPresented = false
        $0.debts = IdentifiedArray(uniqueElements: [expectedDebt])
        $0.selectedDebtID = expectedDebt.id
        $0.debtNameText = ""
        $0.debtPrincipalText = ""
        $0.debtAnnualRateText = ""
        $0.debtTermMonthsText = "12"
        $0.debtPaymentDayText = "1"
        $0.debtMonthlyPaymentText = ""
        $0.debtNoteText = ""
    }
    await store.receive(.liabilitiesSynced)
}

@MainActor
@Test("rejects invalid debt input")
func rejectsInvalidDebtInput() async throws {
    let referenceDate = try date(2026, 4, 26)
    let store = TestStore(
        initialState: DebtFeature.State(
            referenceDate: referenceDate,
            isDebtEditorPresented: true,
            debtNameText: "",
            debtPrincipalText: "0",
            debtAnnualRateText: "8",
            debtTermMonthsText: "12",
            debtPaymentDayText: "1"
        )
    ) {
        DebtFeature()
    } withDependencies: {
        $0.date.now = referenceDate
        $0.uuid = .constant(UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)))
    }

    await store.send(.debtSaveButtonTapped) {
        $0.debtEditorErrorMessageKey = "debt.error.nameRequired"
    }
}

@MainActor
@Test("derives extra payment simulation")
func derivesExtraPaymentSimulation() async throws {
    let referenceDate = try date(2026, 4, 26)
    let debt = Debt(
        name: "Vay xe",
        type: .autoLoan,
        principal: 600_000_000,
        annualInterestRatePercent: 9,
        termMonths: 60,
        startDate: try date(2026, 1, 1)
    )
    let state = DebtFeature.State(
        debts: IdentifiedArray(uniqueElements: [debt]),
        selectedDebtID: debt.id,
        referenceDate: referenceDate,
        extraMonthlyPaymentText: "5.000.000"
    )

    let simulation = try #require(state.extraPaymentResult)

    #expect(simulation.monthsSaved > 0)
    #expect(simulation.interestSaved > 0)
}

private func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
    let calendar = Calendar(identifier: .gregorian)
    return try #require(DateComponents(calendar: calendar, year: year, month: month, day: day).date)
}

private actor LiabilityRecorder {
    private var storedLiabilities: [Liability] = []

    func save(_ liabilities: [Liability]) {
        storedLiabilities = liabilities
    }

    func liabilities() -> [Liability] {
        storedLiabilities
    }
}
