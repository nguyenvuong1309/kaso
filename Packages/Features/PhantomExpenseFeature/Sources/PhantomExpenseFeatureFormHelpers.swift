import Foundation
import PhantomExpenseDomain

func resetPhantomExpenseEditor(
    _ state: inout PhantomExpenseFeature.State,
    avoidedAt: Date
) {
    state.editingExpenseID = nil
    state.titleText = ""
    state.amountText = ""
    state.category = .cart
    state.avoidedAt = avoidedAt
    state.noteText = ""
    state.editorErrorMessageKey = nil
}

func clearPhantomExpenseEditor(_ state: inout PhantomExpenseFeature.State) {
    state.editingExpenseID = nil
    state.titleText = ""
    state.amountText = ""
    state.noteText = ""
    state.editorErrorMessageKey = nil
}

func populatePhantomExpenseEditor(
    _ state: inout PhantomExpenseFeature.State,
    expense: PhantomExpense
) {
    state.editingExpenseID = expense.id
    state.titleText = expense.title
    state.amountText = PhantomExpenseFeatureFormatters.amountText(expense.amount)
    state.category = expense.category
    state.avoidedAt = expense.avoidedAt
    state.noteText = expense.note ?? ""
    state.editorErrorMessageKey = nil
}
