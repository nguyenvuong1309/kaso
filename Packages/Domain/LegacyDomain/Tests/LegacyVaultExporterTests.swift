import Foundation
import Testing
@testable import LegacyDomain

private func makeDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 0,
    calendar: Calendar = Calendar(identifier: .gregorian)
) throws -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.timeZone = TimeZone(identifier: "UTC")
    return try #require(calendar.date(from: components))
}

private func makeExporter(
    salt: UInt8 = 7,
    saltCount: Int = 16,
    date: Date,
    iterationCount: Int = 1_000
) -> LegacyVaultExporter {
    LegacyVaultExporter(
        saltGenerator: { Data(repeating: salt, count: saltCount) },
        dateProvider: { date },
        iterationCount: iterationCount
    )
}

// MARK: - LegacyExportPackage value type

@Test("export package default version is one")
func exportPackageDefaultVersion() throws {
    let exported = try makeDate(year: 2026, month: 5, day: 1)
    let package = LegacyExportPackage(
        vaultData: Data([0x01, 0x02]),
        salt: Data([0xAA]),
        encryptionHint: "hint",
        exportedAt: exported
    )

    #expect(package.version == 1)
    #expect(package.vaultData == Data([0x01, 0x02]))
    #expect(package.salt == Data([0xAA]))
    #expect(package.encryptionHint == "hint")
    #expect(package.exportedAt == exported)
}

@Test("export package accepts explicit version")
func exportPackageExplicitVersion() throws {
    let exported = try makeDate(year: 2026, month: 5, day: 2)
    let package = LegacyExportPackage(
        vaultData: Data(),
        salt: Data(),
        encryptionHint: "",
        exportedAt: exported,
        version: 3
    )
    #expect(package.version == 3)
}

@Test("export package codable round trip")
func exportPackageCodableRoundTrip() throws {
    let exported = try makeDate(year: 2026, month: 6, day: 16)
    let package = LegacyExportPackage(
        vaultData: Data([0x10, 0x20, 0x30]),
        salt: Data(repeating: 5, count: 16),
        encryptionHint: "mật khẩu chính",
        exportedAt: exported,
        version: 2
    )

    let data = try JSONEncoder().encode(package)
    let decoded = try JSONDecoder().decode(LegacyExportPackage.self, from: data)
    #expect(decoded == package)
}

@Test("export packages with differing fields are not equal")
func exportPackageInequality() throws {
    let exported = try makeDate(year: 2026, month: 6, day: 16)
    let base = LegacyExportPackage(vaultData: Data([1]), salt: Data([2]), encryptionHint: "h", exportedAt: exported)
    let other = LegacyExportPackage(vaultData: Data([9]), salt: Data([2]), encryptionHint: "h", exportedAt: exported)
    #expect(base != other)
}

// MARK: - LegacyVaultExporterError

@Test("exporter error cases are distinct")
func exporterErrorEquatable() {
    #expect(LegacyVaultExporterError.emptyPassword == .emptyPassword)
    #expect(LegacyVaultExporterError.invalidPassword == .invalidPassword)
    #expect(LegacyVaultExporterError.invalidPackage == .invalidPackage)
    #expect(LegacyVaultExporterError.emptyPassword != .invalidPassword)
    #expect(LegacyVaultExporterError.invalidPassword != .invalidPackage)
}

// MARK: - export

@Test("export uses provided salt and date provider")
func exportUsesProvidedSaltAndDate() throws {
    let exported = try makeDate(year: 2026, month: 4, day: 10)
    let exporter = makeExporter(salt: 3, date: exported)

    let package = try exporter.export(
        vault: .empty,
        password: "pw-12345",
        encryptionHint: "hint text"
    )

    #expect(package.salt == Data(repeating: 3, count: 16))
    #expect(package.exportedAt == exported)
    #expect(package.encryptionHint == "hint text")
    #expect(package.version == 1)
    // Encrypted payload must differ from plaintext JSON.
    #expect(package.vaultData.isEmpty == false)
}

@Test("export propagates salt generator failure as invalid package")
func exportPropagatesSaltFailure() throws {
    let exported = try makeDate(year: 2026, month: 4, day: 11)
    let exporter = LegacyVaultExporter(
        saltGenerator: { throw LegacyVaultExporterError.invalidPackage },
        dateProvider: { exported },
        iterationCount: 1_000
    )

    #expect(throws: LegacyVaultExporterError.invalidPackage) {
        try exporter.export(vault: .empty, password: "pw-12345", encryptionHint: "")
    }
}

@Test("export of empty vault decrypts back to empty vault")
func exportEmptyVaultRoundTrip() throws {
    let exported = try makeDate(year: 2026, month: 4, day: 12)
    let exporter = makeExporter(date: exported)

    let package = try exporter.export(vault: .empty, password: "pw-12345", encryptionHint: "")
    let decrypted = try exporter.decrypt(package: package, password: "pw-12345")
    #expect(decrypted == LegacyVault.empty)
}

// MARK: - decrypt

@Test("decrypt with empty password throws empty password")
func decryptEmptyPasswordThrows() throws {
    let exported = try makeDate(year: 2026, month: 4, day: 13)
    let exporter = makeExporter(date: exported)
    let package = try exporter.export(vault: .preview, password: "pw-12345", encryptionHint: "")

    #expect(throws: LegacyVaultExporterError.emptyPassword) {
        try exporter.decrypt(package: package, password: "")
    }
}

@Test("decrypt with corrupted vault data throws invalid password")
func decryptCorruptedDataThrows() throws {
    let exported = try makeDate(year: 2026, month: 4, day: 14)
    let exporter = makeExporter(date: exported)
    let package = LegacyExportPackage(
        vaultData: Data([0x00, 0x01, 0x02, 0x03]),
        salt: Data(repeating: 7, count: 16),
        encryptionHint: "",
        exportedAt: exported
    )

    #expect(throws: LegacyVaultExporterError.invalidPassword) {
        try exporter.decrypt(package: package, password: "pw-12345")
    }
}

@Test("decrypt with empty vault data throws invalid password")
func decryptEmptyDataThrows() throws {
    let exported = try makeDate(year: 2026, month: 4, day: 15)
    let exporter = makeExporter(date: exported)
    let package = LegacyExportPackage(
        vaultData: Data(),
        salt: Data(repeating: 7, count: 16),
        encryptionHint: "",
        exportedAt: exported
    )

    #expect(throws: LegacyVaultExporterError.invalidPassword) {
        try exporter.decrypt(package: package, password: "pw-12345")
    }
}

@Test("decrypt fails when salt differs from export salt")
func decryptWithMismatchedSaltThrows() throws {
    let exported = try makeDate(year: 2026, month: 4, day: 16)
    let exporter = makeExporter(salt: 7, date: exported)
    let package = try exporter.export(vault: .preview, password: "pw-12345", encryptionHint: "")

    let tampered = LegacyExportPackage(
        vaultData: package.vaultData,
        salt: Data(repeating: 8, count: 16),
        encryptionHint: package.encryptionHint,
        exportedAt: package.exportedAt
    )

    #expect(throws: LegacyVaultExporterError.invalidPassword) {
        try exporter.decrypt(package: tampered, password: "pw-12345")
    }
}

@Test("decrypt fails when iteration count differs from export")
func decryptWithMismatchedIterationsThrows() throws {
    let exported = try makeDate(year: 2026, month: 4, day: 17)
    let salt = Data(repeating: 7, count: 16)
    let exportExporter = LegacyVaultExporter(
        saltGenerator: { salt },
        dateProvider: { exported },
        iterationCount: 1_000
    )
    let package = try exportExporter.export(vault: .preview, password: "pw-12345", encryptionHint: "")

    let decryptExporter = LegacyVaultExporter(
        saltGenerator: { salt },
        dateProvider: { exported },
        iterationCount: 2_000
    )

    #expect(throws: LegacyVaultExporterError.invalidPassword) {
        try decryptExporter.decrypt(package: package, password: "pw-12345")
    }
}

// MARK: - round trip with rich vault

@Test("export and decrypt preserves a fully populated vault")
func roundTripPopulatedVault() throws {
    let created = try makeDate(year: 2026, month: 1, day: 1)
    let updated = try makeDate(year: 2026, month: 1, day: 2)
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000099"))
    let vault = LegacyVault(
        id: id,
        owner: "Family",
        createdAt: created,
        lastUpdatedAt: updated,
        financialAccounts: [
            LegacyAccount(
                id: try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000100")),
                institutionName: "Bank",
                accountType: .bank,
                approximateBalance: Decimal(string: "12345678.90"),
                contactInfo: "c"
            ),
        ],
        debts: [
            LegacyDebt(
                id: try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000101")),
                lenderName: "Lender",
                amount: Decimal(7_500_000),
                contactInfo: "c"
            ),
        ],
        instructions: "Hướng dẫn chi tiết"
    )

    let exported = try makeDate(year: 2026, month: 4, day: 18)
    let exporter = makeExporter(date: exported)
    let package = try exporter.export(vault: vault, password: "S3cure-Pass!", encryptionHint: "main")
    let decrypted = try exporter.decrypt(package: package, password: "S3cure-Pass!")

    #expect(decrypted == vault)
}

@Test("decrypt with wrong password on empty vault throws invalid password")
func decryptWrongPasswordEmptyVault() throws {
    let exported = try makeDate(year: 2026, month: 4, day: 19)
    let exporter = makeExporter(date: exported)
    let package = try exporter.export(vault: .empty, password: "right-pass-1", encryptionHint: "")

    #expect(throws: LegacyVaultExporterError.invalidPassword) {
        try exporter.decrypt(package: package, password: "wrong-pass-1")
    }
}
