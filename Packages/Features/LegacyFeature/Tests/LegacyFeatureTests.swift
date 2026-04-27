import Foundation
import ComposableArchitecture
import LegacyDomain
import Testing
@testable import LegacyFeature

@MainActor
@Test("vault is accessible only after successful authentication")
func vaultAccessibleOnlyAfterAuthentication() async {
    let store = TestStore(initialState: LegacyFeature.State()) {
        LegacyFeature()
    } withDependencies: {
        $0.biometricAuthClient.authenticate = { _ in true }
        $0.legacyVaultRepository.load = { .preview }
    }

    await store.send(.authenticateButtonTapped) {
        $0.authenticationState = .authenticating
        $0.errorMessageKey = nil
    }
    await store.receive(.authenticationResult(true)) {
        $0.authenticationState = .authenticated
        $0.isLocked = false
    }
    await store.receive(.vaultLoaded(.preview)) {
        $0.vault = .preview
        $0.instructionsText = LegacyVault.preview.instructions
    }
}

@MainActor
@Test("lock action immediately hides vault")
func lockActionImmediatelyHidesVault() async {
    let store = TestStore(
        initialState: LegacyFeature.State(vault: .preview, isLocked: false)
    ) {
        LegacyFeature()
    }

    await store.send(.lock) {
        $0.isLocked = true
        $0.authenticationState = .locked
        $0.exportPassword = ""
        $0.confirmPassword = ""
    }
}

@MainActor
@Test("export clears password state after completion")
func exportClearsPasswordStateAfterCompletion() async {
    let exportURL = URL(fileURLWithPath: "/tmp/kaso-test.kasovault")
    let store = TestStore(
        initialState: LegacyFeature.State(
            vault: .preview,
            isLocked: false,
            exportPassword: "Abcdef12!",
            confirmPassword: "Abcdef12!"
        )
    ) {
        LegacyFeature()
    } withDependencies: {
        $0.legacyExportFileClient.export = { _, _, _ in exportURL }
    }

    await store.send(.exportVaultButtonTapped) {
        $0.isExporting = true
        $0.exportErrorMessageKey = nil
    }
    await store.receive(.vaultExported(exportURL)) {
        $0.isExporting = false
        $0.exportedURL = exportURL
        $0.exportPassword = ""
        $0.confirmPassword = ""
        $0.encryptionHint = ""
    }
}
