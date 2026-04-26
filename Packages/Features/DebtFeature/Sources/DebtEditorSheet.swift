import SwiftUI
import ComposableArchitecture
import DebtDomain
import KasoDesignSystem

struct DebtEditorSheet: View {
    @Bindable var store: StoreOf<DebtFeature>

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(text: $store.debtNameText.sending(\.debtNameTextChanged)) {
                        Text("debt.name", bundle: .module)
                    }

                    Picker(selection: $store.debtType.sending(\.debtTypeChanged)) {
                        ForEach(DebtType.allCases) { type in
                            Label {
                                Text(LocalizedStringKey(type.nameKey), bundle: .module)
                            } icon: {
                                Image(systemName: type.symbolName)
                            }
                            .tag(type)
                        }
                    } label: {
                        Text("debt.type", bundle: .module)
                    }

                    TextField(text: $store.debtPrincipalText.sending(\.debtPrincipalTextChanged)) {
                        Text("debt.principal", bundle: .module)
                    }

                    TextField(text: $store.debtAnnualRateText.sending(\.debtAnnualRateTextChanged)) {
                        Text("debt.annualRate", bundle: .module)
                    }

                    TextField(text: $store.debtTermMonthsText.sending(\.debtTermMonthsTextChanged)) {
                        Text("debt.termMonths", bundle: .module)
                    }

                    DatePicker(
                        selection: $store.debtStartDate.sending(\.debtStartDateChanged),
                        displayedComponents: .date
                    ) {
                        Text("debt.startDate", bundle: .module)
                    }

                    TextField(text: $store.debtPaymentDayText.sending(\.debtPaymentDayTextChanged)) {
                        Text("debt.paymentDay", bundle: .module)
                    }

                    TextField(text: $store.debtMonthlyPaymentText.sending(\.debtMonthlyPaymentTextChanged)) {
                        Text("debt.monthlyOverride", bundle: .module)
                    }

                    TextField(
                        text: $store.debtNoteText.sending(\.debtNoteTextChanged),
                        axis: .vertical
                    ) {
                        Text("debt.note", bundle: .module)
                    }
                }

                if let errorMessageKey = store.debtEditorErrorMessageKey {
                    DebtEditorErrorLabel(messageKey: errorMessageKey)
                }
            }
            .navigationTitle(Text("debt.editor.title", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        store.send(.debtEditorDismissed)
                    } label: {
                        Text("debt.cancel", bundle: .module)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        store.send(.debtSaveButtonTapped)
                    } label: {
                        if store.isDebtSaving {
                            ProgressView()
                        } else {
                            Text("debt.save", bundle: .module)
                        }
                    }
                    .disabled(store.isDebtSaving)
                }
            }
        }
    }
}

private struct DebtEditorErrorLabel: View {
    let messageKey: String

    var body: some View {
        Label {
            Text(LocalizedStringKey(messageKey), bundle: .module)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.kaso.destructive)
        }
        .font(.kaso.caption)
        .foregroundStyle(Color.kaso.destructive)
    }
}
