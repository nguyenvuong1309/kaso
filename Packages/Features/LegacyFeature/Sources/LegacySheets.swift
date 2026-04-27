import SwiftUI
import ComposableArchitecture
import KasoDesignSystem
import LegacyDomain

struct LegacyAccountEditorSheet: View {
    @Bindable var store: StoreOf<LegacyFeature>

    var body: some View {
        NavigationStack {
            Form {
                TextField(
                    String(localized: "legacy.account.institution", bundle: .module),
                    text: $store.accountInstitutionText.sending(\.accountInstitutionChanged)
                )
                TextField(
                    String(localized: "legacy.account.contact", bundle: .module),
                    text: $store.accountContactText.sending(\.accountContactChanged)
                )

                Picker(
                    selection: $store.accountType.sending(\.accountTypeChanged)
                ) {
                    ForEach(LegacyAccountType.allCases) { type in
                        Text(LocalizedStringKey(type.titleKey), bundle: .module)
                            .tag(type)
                    }
                } label: {
                    Text("legacy.account.type", bundle: .module)
                }

                TextField(
                    String(localized: "legacy.account.lastFour", bundle: .module),
                    text: $store.accountLastFourText.sending(\.accountLastFourChanged)
                )
                TextField(
                    String(localized: "legacy.account.balance", bundle: .module),
                    text: $store.accountBalanceText.sending(\.accountBalanceChanged)
                )
                .kasoDecimalKeyboard()
                TextField(
                    String(localized: "legacy.account.notes", bundle: .module),
                    text: $store.accountNotesText.sending(\.accountNotesChanged),
                    axis: .vertical
                )

                if let messageKey = store.editorErrorMessageKey {
                    Text(LocalizedStringKey(messageKey), bundle: .module)
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.destructive)
                }
            }
            .navigationTitle(Text("legacy.account.editor", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        store.send(.accountEditorDismissed)
                    } label: {
                        Text("legacy.cancel", bundle: .module)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        store.send(.saveAccountButtonTapped)
                    } label: {
                        Text("legacy.save", bundle: .module)
                    }
                }
            }
        }
    }
}

struct LegacyExportSheet: View {
    @Bindable var store: StoreOf<LegacyFeature>

    var body: some View {
        NavigationStack {
            Form {
                SecureField(
                    String(localized: "legacy.export.password", bundle: .module),
                    text: $store.exportPassword.sending(\.exportPasswordChanged)
                )
                SecureField(
                    String(localized: "legacy.export.confirm", bundle: .module),
                    text: $store.confirmPassword.sending(\.confirmPasswordChanged)
                )
                TextField(
                    String(localized: "legacy.export.hint", bundle: .module),
                    text: $store.encryptionHint.sending(\.encryptionHintChanged)
                )

                LegacyPasswordStrengthView(strength: store.passwordStrength)

                if let messageKey = store.exportErrorMessageKey {
                    Text(LocalizedStringKey(messageKey), bundle: .module)
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.destructive)
                }

                if let exportedURL = store.exportedURL {
                    ShareLink(item: exportedURL) {
                        Label {
                            Text("legacy.export.share", bundle: .module)
                        } icon: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .navigationTitle(Text("legacy.export", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        store.send(.exportSheetDismissed)
                    } label: {
                        Text("legacy.cancel", bundle: .module)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        store.send(.exportVaultButtonTapped)
                    } label: {
                        if store.isExporting {
                            ProgressView()
                        } else {
                            Text("legacy.export.create", bundle: .module)
                        }
                    }
                    .disabled(store.isExporting)
                }
            }
        }
    }
}

struct LegacyPasswordStrengthView: View {
    let strength: LegacyPasswordStrength

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("legacy.export.strength", bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
            ProgressView(value: value)
                .tint(color)
            Text(LocalizedStringKey("legacy.password.\(strength.rawValue)"), bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(color)
        }
    }

    private var value: Double {
        switch strength {
        case .weak:
            0.33
        case .fair:
            0.66
        case .strong:
            1
        }
    }

    private var color: Color {
        switch strength {
        case .weak:
            Color.kaso.destructive
        case .fair:
            Color.kaso.warning
        case .strong:
            Color.kaso.positive
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
