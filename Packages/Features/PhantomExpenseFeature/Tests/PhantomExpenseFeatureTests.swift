import Foundation
import Testing
import ComposableArchitecture
import PhantomExpenseDomain
@testable import PhantomExpenseFeature

@MainActor
@Test("loads phantom expenses on task")
func loadsPhantomExpensesOnTask() async throws {
    let referenceDate = try date(2026, 4, 26)
    let expense = PhantomExpense(
        title: "Bỏ giỏ hàng",
        amount: 700_000,
        category: .cart,
        avoidedAt: referenceDate
    )
    let store = TestStore(initialState: PhantomExpenseFeature.State()) {
        PhantomExpenseFeature()
    } withDependencies: {
        $0.date.now = referenceDate
        $0.phantomExpenseRepository.fetchAll = { [expense] }
    }

    await store.send(.task) {
        $0.referenceDate = referenceDate
        $0.isLoading = true
    }
    await store.receive(.expensesLoaded([expense])) {
        $0.isLoading = false
        $0.expenses = IdentifiedArray(uniqueElements: [expense])
    }
}

@MainActor
@Test("saves phantom expense from editor")
func savesPhantomExpenseFromEditor() async throws {
    let referenceDate = try date(2026, 4, 26)
    let expenseID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    let expectedExpense = PhantomExpense(
        id: expenseID,
        title: "Bỏ giỏ hàng sneaker",
        amount: 1_500_000,
        category: .cart,
        avoidedAt: referenceDate,
        createdAt: referenceDate
    )
    let store = TestStore(initialState: PhantomExpenseFeature.State(referenceDate: referenceDate)) {
        PhantomExpenseFeature()
    } withDependencies: {
        $0.date.now = referenceDate
        $0.uuid = .incrementing
        $0.phantomExpenseRepository.save = { _ in }
    }

    await store.send(.addButtonTapped) {
        $0.isEditorPresented = true
        $0.category = .cart
        $0.avoidedAt = referenceDate
        $0.editorErrorMessageKey = nil
    }
    await store.send(.titleTextChanged("  Bỏ giỏ hàng sneaker  ")) {
        $0.titleText = "  Bỏ giỏ hàng sneaker  "
        $0.editorErrorMessageKey = nil
    }
    await store.send(.amountTextChanged("1.500.000")) {
        $0.amountText = "1.500.000"
        $0.editorErrorMessageKey = nil
    }
    await store.send(.saveButtonTapped) {
        $0.isSaving = true
    }
    await store.receive(.expenseSaved(expectedExpense)) {
        $0.isSaving = false
        $0.isEditorPresented = false
        $0.expenses = IdentifiedArray(uniqueElements: [expectedExpense])
        $0.titleText = ""
        $0.amountText = ""
        $0.noteText = ""
        $0.editorErrorMessageKey = nil
    }
}

@MainActor
@Test("rejects invalid phantom expense input")
func rejectsInvalidPhantomExpenseInput() async {
    let store = TestStore(
        initialState: PhantomExpenseFeature.State(
            isEditorPresented: true,
            titleText: "Không mua game",
            amountText: "0"
        )
    ) {
        PhantomExpenseFeature()
    }

    await store.send(.saveButtonTapped) {
        $0.editorErrorMessageKey = "phantom.error.amountMustBePositive"
    }
}

@MainActor
@Test("deletes phantom expense")
func deletesPhantomExpense() async throws {
    let referenceDate = try date(2026, 4, 26)
    let expense = PhantomExpense(
        title: "Huỷ subscription",
        amount: 300_000,
        category: .subscription,
        avoidedAt: referenceDate
    )
    let store = TestStore(
        initialState: PhantomExpenseFeature.State(
            expenses: IdentifiedArray(uniqueElements: [expense]),
            referenceDate: referenceDate
        )
    ) {
        PhantomExpenseFeature()
    } withDependencies: {
        $0.phantomExpenseRepository.delete = { _ in }
    }

    await store.send(.deleteButtonTapped(expense))
    await store.receive(.expenseDeleted(expense.id)) {
        $0.expenses = []
    }
}

private func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
    let calendar = Calendar(identifier: .gregorian)
    return try #require(DateComponents(calendar: calendar, year: year, month: month, day: day).date)
}
