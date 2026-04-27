import SwiftUI
import ComposableArchitecture
import FreelancerDomain
import KasoDesignSystem

struct FreelancerIncomeEditorSheet: View {
    @Bindable var store: StoreOf<FreelancerFeature>

    var body: some View {
        NavigationStack {
            Form {
                DatePicker(
                    selection: $store.incomeDate.sending(\.incomeDateChanged),
                    displayedComponents: [.date]
                ) {
                    Text("freelancer.income.month", bundle: .module)
                }

                TextField(
                    String(localized: "freelancer.income.gross", bundle: .module),
                    text: $store.incomeGrossText.sending(\.incomeGrossTextChanged)
                )
                .kasoDecimalKeyboard()

                TextField(
                    String(localized: "freelancer.income.deduction", bundle: .module),
                    text: $store.incomeDeductionText.sending(\.incomeDeductionTextChanged)
                )
                .kasoDecimalKeyboard()

                if let messageKey = store.editorErrorMessageKey {
                    Text(LocalizedStringKey(messageKey), bundle: .module)
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.destructive)
                }
            }
            .navigationTitle(Text("freelancer.income.title", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        store.send(.incomeEditorDismissed)
                    } label: {
                        Text("freelancer.cancel", bundle: .module)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        store.send(.saveIncomeButtonTapped)
                    } label: {
                        Text("freelancer.save", bundle: .module)
                    }
                    .disabled(store.isSavingIncome)
                }
            }
        }
    }
}

struct FreelancerProfileEditorSheet: View {
    @Bindable var store: StoreOf<FreelancerFeature>

    var body: some View {
        NavigationStack {
            Form {
                Picker(
                    selection: $store.workType.sending(\.workTypeChanged)
                ) {
                    ForEach(FreelancerWorkType.allCases) { workType in
                        Text(LocalizedStringKey(workType.titleKey), bundle: .module)
                            .tag(workType)
                    }
                } label: {
                    Text("freelancer.profile.workType", bundle: .module)
                }

                TextField(
                    String(localized: "freelancer.profile.buffer", bundle: .module),
                    text: $store.bufferBalanceText.sending(\.bufferBalanceTextChanged)
                )
                .kasoDecimalKeyboard()

                TextField(
                    String(localized: "freelancer.profile.target", bundle: .module),
                    text: $store.bufferTargetMonthsText.sending(\.bufferTargetMonthsTextChanged)
                )
                .kasoDecimalKeyboard()

                TextField(
                    String(localized: "freelancer.profile.tax", bundle: .module),
                    text: $store.taxRateText.sending(\.taxRateTextChanged)
                )
                .kasoDecimalKeyboard()

                if let messageKey = store.editorErrorMessageKey {
                    Text(LocalizedStringKey(messageKey), bundle: .module)
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.destructive)
                }
            }
            .navigationTitle(Text("freelancer.profile", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        store.send(.profileEditorDismissed)
                    } label: {
                        Text("freelancer.cancel", bundle: .module)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        store.send(.saveProfileButtonTapped)
                    } label: {
                        Text("freelancer.save", bundle: .module)
                    }
                    .disabled(store.isSavingProfile)
                }
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func kasoDecimalKeyboard() -> some View {
        #if os(iOS)
        keyboardType(.decimalPad)
        #else
        self
        #endif
    }
}
