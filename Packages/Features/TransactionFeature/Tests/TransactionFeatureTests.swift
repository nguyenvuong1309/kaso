import ComposableArchitecture
import Foundation
import Testing
import TransactionDomain
@testable import TransactionFeature

@MainActor
@Test("loads transactions on task")
func loadsTransactionsOnTask() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let date = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26).date
    )
    let transaction = Transaction(
        amount: 45_000,
        kind: .expense,
        category: .food,
        occurredAt: date
    )
    let store = TestStore(initialState: TransactionFeature.State()) {
        TransactionFeature()
    } withDependencies: {
        $0.date.now = date
        $0.transactionRepository.fetchAll = { [transaction] }
    }

    await store.send(.task) {
        $0.isLoading = true
    }
    await store.receive(\.transactionsLoaded) {
        $0.isLoading = false
        $0.transactions = IdentifiedArray(uniqueElements: [transaction])
        $0.summary = MonthlyTransactionSummary(
            income: 0,
            expense: 45_000,
            balance: -45_000
        )
    }
}

@MainActor
@Test("saves valid draft")
func savesValidDraft() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let date = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26).date
    )
    let draft = TransactionDraft(
        amount: 75_000,
        kind: .expense,
        category: .transport,
        occurredAt: date
    )
    let transactionID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
    let expectedTransaction = Transaction(
        id: transactionID,
        amount: 75_000,
        kind: .expense,
        category: .transport,
        occurredAt: date
    )
    let store = TestStore(initialState: TransactionFeature.State()) {
        TransactionFeature()
    } withDependencies: {
        $0.date.now = date
        $0.uuid = .constant(transactionID)
        $0.transactionRepository.save = { _ in }
    }

    await store.send(.saveDraft(draft)) {
        $0.isSaving = true
    }
    await store.receive(.transactionSaved(expectedTransaction)) {
        $0.isSaving = false
        $0.transactions.insert(expectedTransaction, at: 0)
        $0.draftOccurredAt = date
        $0.summary = MonthlyTransactionSummary(
            income: 0,
            expense: 75_000,
            balance: -75_000
        )
    }
}

@MainActor
@Test("rejects invalid draft")
func rejectsInvalidDraft() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let date = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26).date
    )
    let draft = TransactionDraft(
        amount: 0,
        kind: .expense,
        category: .food,
        occurredAt: date
    )
    let store = TestStore(initialState: TransactionFeature.State()) {
        TransactionFeature()
    }

    await store.send(.saveDraft(draft)) {
        $0.errorMessageKey = "transactions.error.invalidDraft"
        $0.formErrorMessageKey = "transactions.error.invalidDraft"
    }
}

@MainActor
@Test("saves transaction from add form")
func savesTransactionFromAddForm() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let date = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26).date
    )
    let transactionID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000002"))
    let expectedTransaction = Transaction(
        id: transactionID,
        amount: 45_000,
        kind: .expense,
        category: .food,
        occurredAt: date,
        note: "Coffee"
    )
    let store = TestStore(initialState: TransactionFeature.State()) {
        TransactionFeature()
    } withDependencies: {
        $0.date.now = date
        $0.uuid = .constant(transactionID)
        $0.transactionRepository.save = { _ in }
    }

    await store.send(.addButtonTapped) {
        $0.isAddSheetPresented = true
        $0.draftOccurredAt = date
    }
    await store.send(.amountTextChanged("45.000")) {
        $0.amountText = "45.000"
    }
    await store.send(.noteChanged(" Coffee ")) {
        $0.draftNote = " Coffee "
    }
    await store.send(.saveButtonTapped) {
        $0.isSaving = true
    }
    await store.receive(.transactionSaved(expectedTransaction)) {
        $0.isSaving = false
        $0.isAddSheetPresented = false
        $0.transactions.insert(expectedTransaction, at: 0)
        $0.amountText = ""
        $0.draftOccurredAt = date
        $0.draftNote = ""
        $0.summary = MonthlyTransactionSummary(
            income: 0,
            expense: 45_000,
            balance: -45_000
        )
    }
}

@MainActor
@Test("shows form error for invalid amount")
func showsFormErrorForInvalidAmount() async {
    let store = TestStore(initialState: TransactionFeature.State()) {
        TransactionFeature()
    }

    await store.send(.amountTextChanged("abc")) {
        $0.amountText = "abc"
    }
    await store.send(.saveButtonTapped) {
        $0.formErrorMessageKey = "transactions.add.error.invalidAmount"
    }
}
