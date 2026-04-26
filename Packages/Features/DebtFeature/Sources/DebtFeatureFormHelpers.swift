import Foundation
import DebtDomain

func resetDebtEditor(_ state: inout DebtFeature.State, startDate: Date) {
    state.editingDebtID = nil
    state.debtNameText = ""
    state.debtPrincipalText = ""
    state.debtAnnualRateText = ""
    state.debtTermMonthsText = "12"
    state.debtStartDate = startDate
    state.debtPaymentDayText = "1"
    state.debtMonthlyPaymentText = ""
    state.debtType = .personalLoan
    state.debtNoteText = ""
    state.debtEditorErrorMessageKey = nil
}

func populateDebtEditor(_ state: inout DebtFeature.State, debt: Debt) {
    state.editingDebtID = debt.id
    state.debtNameText = debt.name
    state.debtPrincipalText = editingAmount(debt.principal)
    state.debtAnnualRateText = editingAmount(debt.annualInterestRatePercent)
    state.debtTermMonthsText = debt.termMonths.formatted(.number.grouping(.never))
    state.debtStartDate = debt.startDate
    state.debtPaymentDayText = debt.paymentDay.formatted(.number.grouping(.never))
    state.debtMonthlyPaymentText = debt.monthlyPaymentOverride.map(editingAmount) ?? ""
    state.debtType = debt.type
    state.debtNoteText = debt.note ?? ""
    state.debtEditorErrorMessageKey = nil
}

func clearDebtEditor(_ state: inout DebtFeature.State) {
    state.editingDebtID = nil
    state.debtNameText = ""
    state.debtPrincipalText = ""
    state.debtAnnualRateText = ""
    state.debtTermMonthsText = "12"
    state.debtPaymentDayText = "1"
    state.debtMonthlyPaymentText = ""
    state.debtNoteText = ""
    state.debtEditorErrorMessageKey = nil
}

private func editingAmount(_ amount: Decimal) -> String {
    NSDecimalNumber(decimal: amount).stringValue
}

extension DebtValidationError {
    var messageKey: String {
        switch self {
        case .nameRequired:
            "debt.error.nameRequired"
        case .principalMustBePositive:
            "debt.error.invalidPrincipal"
        case .annualInterestRateCannotBeNegative:
            "debt.error.invalidAnnualRate"
        case .termMonthsMustBePositive, .termMonthsTooLong:
            "debt.error.invalidTerm"
        case .paymentDayOutOfRange:
            "debt.error.invalidPaymentDay"
        }
    }
}
