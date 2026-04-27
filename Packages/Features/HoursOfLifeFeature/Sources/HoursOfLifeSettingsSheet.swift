import ComposableArchitecture
import KasoDesignSystem
import SwiftUI

struct HoursOfLifeSettingsSheet: View {
    @Bindable var store: StoreOf<HoursOfLifeFeature>

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        text: $store.monthlyNetIncomeText.sending(\.incomeTextChanged),
                        prompt: Text("hoursOfLife.settings.incomePrompt", bundle: .module)
                    ) {
                        Text("hoursOfLife.settings.incomeField", bundle: .module)
                    }
                    .kasoDecimalKeyboard()

                    TextField(
                        text: $store.monthlyWorkHoursText.sending(\.workHoursTextChanged),
                        prompt: Text("hoursOfLife.settings.workHoursPrompt", bundle: .module)
                    ) {
                        Text("hoursOfLife.settings.workHoursField", bundle: .module)
                    }
                    .kasoDecimalKeyboard()
                } header: {
                    Text("hoursOfLife.settings.section", bundle: .module)
                } footer: {
                    Text("hoursOfLife.settings.footer", bundle: .module)
                }

                if let errorMessageKey = store.settingsErrorMessageKey {
                    HoursOfLifeSettingsErrorLabel(messageKey: errorMessageKey)
                }
            }
            .navigationTitle(Text("hoursOfLife.settings.title", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        store.send(.settingsDismissed)
                    } label: {
                        Text("hoursOfLife.settings.cancel", bundle: .module)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        store.send(.saveSettingsButtonTapped)
                    } label: {
                        if store.isSavingSettings {
                            ProgressView()
                        } else {
                            Text("hoursOfLife.settings.save", bundle: .module)
                        }
                    }
                    .disabled(store.isSavingSettings)
                }
            }
        }
    }
}

private struct HoursOfLifeSettingsErrorLabel: View {
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
