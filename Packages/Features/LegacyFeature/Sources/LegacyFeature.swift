import Foundation
import ComposableArchitecture
import LegacyDomain

@Reducer
public struct LegacyFeature: Sendable {
    public enum AuthenticationState: Equatable, Sendable {
        case locked
        case authenticating
        case authenticated
        case failed
    }

    @ObservableState
    public struct State: Equatable {
        public var vault: LegacyVault?
        public var isLocked: Bool
        public var authenticationState: AuthenticationState
        public var isAccountEditorPresented: Bool
        public var isExportSheetPresented: Bool
        public var isExporting: Bool
        public var exportedURL: URL?
        public var editingAccountID: UUID?
        public var accountInstitutionText: String
        public var accountContactText: String
        public var accountLastFourText: String
        public var accountBalanceText: String
        public var accountNotesText: String
        public var accountType: LegacyAccountType
        public var instructionsText: String
        public var exportPassword: String
        public var confirmPassword: String
        public var encryptionHint: String
        public var errorMessageKey: String?
        public var editorErrorMessageKey: String?
        public var exportErrorMessageKey: String?

        public init(
            vault: LegacyVault? = nil,
            isLocked: Bool = true,
            authenticationState: AuthenticationState = .locked,
            isAccountEditorPresented: Bool = false,
            isExportSheetPresented: Bool = false,
            isExporting: Bool = false,
            exportedURL: URL? = nil,
            editingAccountID: UUID? = nil,
            accountInstitutionText: String = "",
            accountContactText: String = "",
            accountLastFourText: String = "",
            accountBalanceText: String = "",
            accountNotesText: String = "",
            accountType: LegacyAccountType = .bank,
            instructionsText: String = "",
            exportPassword: String = "",
            confirmPassword: String = "",
            encryptionHint: String = "",
            errorMessageKey: String? = nil,
            editorErrorMessageKey: String? = nil,
            exportErrorMessageKey: String? = nil
        ) {
            self.vault = vault
            self.isLocked = isLocked
            self.authenticationState = authenticationState
            self.isAccountEditorPresented = isAccountEditorPresented
            self.isExportSheetPresented = isExportSheetPresented
            self.isExporting = isExporting
            self.exportedURL = exportedURL
            self.editingAccountID = editingAccountID
            self.accountInstitutionText = accountInstitutionText
            self.accountContactText = accountContactText
            self.accountLastFourText = accountLastFourText
            self.accountBalanceText = accountBalanceText
            self.accountNotesText = accountNotesText
            self.accountType = accountType
            self.instructionsText = instructionsText
            self.exportPassword = exportPassword
            self.confirmPassword = confirmPassword
            self.encryptionHint = encryptionHint
            self.errorMessageKey = errorMessageKey
            self.editorErrorMessageKey = editorErrorMessageKey
            self.exportErrorMessageKey = exportErrorMessageKey
        }

        public var passwordStrength: LegacyPasswordStrength {
            LegacyPasswordStrength.evaluate(exportPassword)
        }
    }

    public enum Action: Equatable, Sendable {
        case authenticateButtonTapped
        case authenticationResult(Bool)
        case vaultLoaded(LegacyVault)
        case loadFailed(String)
        case addAccountButtonTapped
        case editAccountButtonTapped(LegacyAccount)
        case accountEditorDismissed
        case accountInstitutionChanged(String)
        case accountContactChanged(String)
        case accountLastFourChanged(String)
        case accountBalanceChanged(String)
        case accountNotesChanged(String)
        case accountTypeChanged(LegacyAccountType)
        case saveAccountButtonTapped
        case accountSaved(LegacyVault)
        case deleteAccountButtonTapped(UUID)
        case instructionsChanged(String)
        case saveInstructionsButtonTapped
        case exportButtonTapped
        case exportSheetDismissed
        case exportPasswordChanged(String)
        case confirmPasswordChanged(String)
        case encryptionHintChanged(String)
        case exportVaultButtonTapped
        case vaultExported(URL)
        case exportFailed(String)
        case lock
    }

    @Dependency(\.legacyVaultRepository) private var repository
    @Dependency(\.biometricAuthClient) private var authClient
    @Dependency(\.legacyExportFileClient) private var exportClient
    @Dependency(\.date) private var date
    @Dependency(\.uuid) private var uuid

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .authenticateButtonTapped:
                state.authenticationState = .authenticating
                state.errorMessageKey = nil
                return .run { send in
                    let reason = String(localized: "legacy.auth.reason", bundle: .module)
                    await send(.authenticationResult(await authClient.authenticate(reason)))
                }

            case let .authenticationResult(success):
                if success {
                    state.authenticationState = .authenticated
                    state.isLocked = false
                    return loadVaultEffect()
                } else {
                    state.authenticationState = .failed
                    state.errorMessageKey = "legacy.error.authFailed"
                    return .none
                }

            case let .vaultLoaded(vault):
                state.vault = vault
                state.instructionsText = vault.instructions
                return .none

            case let .loadFailed(messageKey):
                state.errorMessageKey = messageKey
                return .none

            case .addAccountButtonTapped:
                clearAccountEditor(&state)
                state.isAccountEditorPresented = true
                return .none

            case let .editAccountButtonTapped(account):
                populateAccountEditor(&state, account: account)
                state.isAccountEditorPresented = true
                return .none

            case .accountEditorDismissed:
                state.isAccountEditorPresented = false
                state.editorErrorMessageKey = nil
                return .none

            case let .accountInstitutionChanged(text):
                state.accountInstitutionText = text
                state.editorErrorMessageKey = nil
                return .none

            case let .accountContactChanged(text):
                state.accountContactText = text
                state.editorErrorMessageKey = nil
                return .none

            case let .accountLastFourChanged(text):
                state.accountLastFourText = text
                return .none

            case let .accountBalanceChanged(text):
                state.accountBalanceText = text
                return .none

            case let .accountNotesChanged(text):
                state.accountNotesText = text
                return .none

            case let .accountTypeChanged(type):
                state.accountType = type
                return .none

            case .saveAccountButtonTapped:
                return saveAccountEffect(&state)

            case let .accountSaved(vault):
                state.vault = vault
                state.isAccountEditorPresented = false
                clearAccountEditor(&state)
                return .none

            case let .deleteAccountButtonTapped(id):
                return deleteAccountEffect(&state, id: id)

            case let .instructionsChanged(text):
                state.instructionsText = text
                return .none

            case .saveInstructionsButtonTapped:
                return saveInstructionsEffect(&state)

            case .exportButtonTapped:
                state.isExportSheetPresented = true
                state.exportErrorMessageKey = nil
                state.exportedURL = nil
                return .none

            case .exportSheetDismissed:
                state.isExportSheetPresented = false
                state.exportPassword = ""
                state.confirmPassword = ""
                state.encryptionHint = ""
                state.exportErrorMessageKey = nil
                return .none

            case let .exportPasswordChanged(text):
                state.exportPassword = text
                state.exportErrorMessageKey = nil
                return .none

            case let .confirmPasswordChanged(text):
                state.confirmPassword = text
                state.exportErrorMessageKey = nil
                return .none

            case let .encryptionHintChanged(text):
                state.encryptionHint = text
                return .none

            case .exportVaultButtonTapped:
                return exportVaultEffect(&state)

            case let .vaultExported(url):
                state.isExporting = false
                state.exportedURL = url
                state.exportPassword = ""
                state.confirmPassword = ""
                state.encryptionHint = ""
                return .none

            case let .exportFailed(messageKey):
                state.isExporting = false
                state.exportErrorMessageKey = messageKey
                state.exportPassword = ""
                state.confirmPassword = ""
                return .none

            case .lock:
                state.isLocked = true
                state.authenticationState = .locked
                state.exportPassword = ""
                state.confirmPassword = ""
                return .none
            }
        }
    }

    private func loadVaultEffect() -> Effect<Action> {
        .run { send in
            do {
                await send(.vaultLoaded(try await repository.load() ?? LegacyVault.empty))
            } catch {
                await send(.loadFailed("legacy.error.loadFailed"))
            }
        }
    }

    private func saveAccountEffect(_ state: inout State) -> Effect<Action> {
        let institution = state.accountInstitutionText.trimmingCharacters(in: .whitespacesAndNewlines)
        let contact = state.accountContactText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard institution.isEmpty == false else {
            state.editorErrorMessageKey = "legacy.error.institutionRequired"
            return .none
        }
        guard contact.isEmpty == false else {
            state.editorErrorMessageKey = "legacy.error.contactRequired"
            return .none
        }

        var vault = state.vault ?? LegacyVault.empty
        let account = LegacyAccount(
            id: state.editingAccountID ?? uuid(),
            institutionName: institution,
            accountType: state.accountType,
            lastFourDigits: emptyToNil(state.accountLastFourText),
            approximateBalance: LegacyFeatureFormatters.parseDecimal(state.accountBalanceText),
            contactInfo: contact,
            notes: emptyToNil(state.accountNotesText),
            createdAt: date.now
        )
        vault.financialAccounts.removeAll { $0.id == account.id }
        vault.financialAccounts.append(account)
        vault.lastUpdatedAt = date.now
        return save(vault: vault, success: Action.accountSaved)
    }

    private func deleteAccountEffect(_ state: inout State, id: UUID) -> Effect<Action> {
        guard var vault = state.vault else {
            return .none
        }
        vault.financialAccounts.removeAll { $0.id == id }
        vault.lastUpdatedAt = date.now
        return save(vault: vault, success: Action.accountSaved)
    }

    private func saveInstructionsEffect(_ state: inout State) -> Effect<Action> {
        var vault = state.vault ?? LegacyVault.empty
        vault.instructions = state.instructionsText
        vault.lastUpdatedAt = date.now
        return save(vault: vault, success: Action.accountSaved)
    }

    private func exportVaultEffect(_ state: inout State) -> Effect<Action> {
        guard let vault = state.vault else {
            state.exportErrorMessageKey = "legacy.error.noVault"
            return .none
        }
        guard state.exportPassword.isEmpty == false else {
            state.exportErrorMessageKey = "legacy.error.passwordRequired"
            return .none
        }
        guard state.exportPassword == state.confirmPassword else {
            state.exportErrorMessageKey = "legacy.error.passwordMismatch"
            return .none
        }

        let password = state.exportPassword
        let hint = state.encryptionHint
        state.isExporting = true
        state.exportErrorMessageKey = nil
        return .run { send in
            do {
                await send(.vaultExported(try await exportClient.export(vault, password, hint)))
            } catch {
                await send(.exportFailed("legacy.error.exportFailed"))
            }
        }
    }

    private func save(
        vault: LegacyVault,
        success: @escaping @Sendable (LegacyVault) -> Action
    ) -> Effect<Action> {
        .run { send in
            do {
                try await repository.save(vault)
                await send(success(vault))
            } catch {
                await send(.loadFailed("legacy.error.saveFailed"))
            }
        }
    }

    private func clearAccountEditor(_ state: inout State) {
        state.editingAccountID = nil
        state.accountInstitutionText = ""
        state.accountContactText = ""
        state.accountLastFourText = ""
        state.accountBalanceText = ""
        state.accountNotesText = ""
        state.accountType = .bank
        state.editorErrorMessageKey = nil
    }

    private func populateAccountEditor(_ state: inout State, account: LegacyAccount) {
        state.editingAccountID = account.id
        state.accountInstitutionText = account.institutionName
        state.accountContactText = account.contactInfo
        state.accountLastFourText = account.lastFourDigits ?? ""
        state.accountBalanceText = account.approximateBalance.map(LegacyFeatureFormatters.amountText) ?? ""
        state.accountNotesText = account.notes ?? ""
        state.accountType = account.accountType
        state.editorErrorMessageKey = nil
    }

    private func emptyToNil(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

enum LegacyFeatureFormatters {
    static func parseDecimal(_ text: String) -> Decimal? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
        guard normalized.isEmpty == false else {
            return nil
        }
        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }

    static func amountText(_ amount: Decimal) -> String {
        NSDecimalNumber(decimal: amount).stringValue
    }
}
