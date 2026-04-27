import Foundation
import Testing
@testable import LegacyDomain

@Test("encrypt decrypt with correct password returns original vault")
func encryptDecryptWithCorrectPasswordReturnsVault() throws {
    let vault = LegacyVault.preview
    let exporter = LegacyVaultExporter(
        saltGenerator: { Data(repeating: 7, count: 16) },
        dateProvider: { Date(timeIntervalSinceReferenceDate: 1_000) },
        iterationCount: 1_000
    )

    let package = try exporter.export(
        vault: vault,
        password: "safe-password-123",
        encryptionHint: "mật khẩu chính"
    )
    let decrypted = try exporter.decrypt(package: package, password: "safe-password-123")

    #expect(decrypted == vault)
    #expect(package.version == 1)
    #expect(package.encryptionHint == "mật khẩu chính")
}

@Test("decrypt with wrong password throws invalid password")
func decryptWithWrongPasswordThrowsInvalidPassword() throws {
    let exporter = LegacyVaultExporter(
        saltGenerator: { Data(repeating: 9, count: 16) },
        dateProvider: { Date(timeIntervalSinceReferenceDate: 2_000) },
        iterationCount: 1_000
    )
    let package = try exporter.export(
        vault: .preview,
        password: "correct-password",
        encryptionHint: ""
    )

    #expect(throws: LegacyVaultExporterError.invalidPassword) {
        try exporter.decrypt(package: package, password: "wrong-password")
    }
}

@Test("empty password is rejected")
func emptyPasswordIsRejected() {
    let exporter = LegacyVaultExporter(
        saltGenerator: { Data(repeating: 1, count: 16) },
        dateProvider: { Date(timeIntervalSinceReferenceDate: 3_000) },
        iterationCount: 1_000
    )

    #expect(throws: LegacyVaultExporterError.emptyPassword) {
        try exporter.export(vault: .preview, password: "", encryptionHint: "")
    }
}

@Test("password strength distinguishes weak and strong inputs")
func passwordStrengthDistinguishesInputs() {
    #expect(LegacyPasswordStrength.evaluate("abc") == .weak)
    #expect(LegacyPasswordStrength.evaluate("abcdef12") == .fair)
    #expect(LegacyPasswordStrength.evaluate("Abcdef12!") == .strong)
}
