import ComposableArchitecture
import KasoDesignSystem
import SwiftUI

struct RoundUpManualEntrySheet: View {
    @Bindable var store: StoreOf<RoundUpFeature>

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        "roundUp.manual.amountPlaceholder",
                        text: $store.manualEntryAmountText.sending(\.manualEntryAmountChanged)
                    )
                    .keyboardType(.decimalPad)
                } header: {
                    Text("roundUp.manual.amountHeader", bundle: .module)
                } footer: {
                    Text("roundUp.manual.amountFooter", bundle: .module)
                }

                Section {
                    TextField(
                        "roundUp.manual.notePlaceholder",
                        text: $store.manualEntryNoteText.sending(\.manualEntryNoteChanged)
                    )
                } header: {
                    Text("roundUp.manual.noteHeader", bundle: .module)
                }
            }
            .navigationTitle(Text("roundUp.manual.title", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        store.send(.manualEntryDismissed)
                    } label: {
                        Text("roundUp.manual.cancel", bundle: .module)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        store.send(.manualEntrySubmitted)
                    } label: {
                        Text("roundUp.manual.save", bundle: .module)
                    }
                }
            }
        }
    }
}
