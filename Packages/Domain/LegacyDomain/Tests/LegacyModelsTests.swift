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

private func fixedID(_ value: Int) throws -> UUID {
    let suffix = String(format: "%012d", value)
    return try #require(UUID(uuidString: "00000000-0000-0000-0000-\(suffix)"))
}

// MARK: - LegacyAccountType

@Test("account type exposes all cases")
func accountTypeAllCases() {
    #expect(LegacyAccountType.allCases.count == 6)
    #expect(LegacyAccountType.allCases.contains(.bank))
    #expect(LegacyAccountType.allCases.contains(.wallet))
    #expect(LegacyAccountType.allCases.contains(.crypto))
    #expect(LegacyAccountType.allCases.contains(.brokerage))
    #expect(LegacyAccountType.allCases.contains(.insurance))
    #expect(LegacyAccountType.allCases.contains(.other))
}

@Test("account type id matches raw value")
func accountTypeIDMatchesRawValue() {
    for type in LegacyAccountType.allCases {
        #expect(type.id == type.rawValue)
    }
}

@Test("account type title key uses namespaced prefix")
func accountTypeTitleKey() {
    #expect(LegacyAccountType.bank.titleKey == "legacy.accountType.bank")
    #expect(LegacyAccountType.crypto.titleKey == "legacy.accountType.crypto")
    #expect(LegacyAccountType.other.titleKey == "legacy.accountType.other")
}

@Test("account type codable round trip preserves raw value")
func accountTypeCodableRoundTrip() throws {
    for type in LegacyAccountType.allCases {
        let data = try JSONEncoder().encode(type)
        let decoded = try JSONDecoder().decode(LegacyAccountType.self, from: data)
        #expect(decoded == type)
    }
}

// MARK: - LegacyAccount

@Test("account default initializer leaves optionals nil")
func accountDefaultInitializer() throws {
    let id = try fixedID(1)
    let created = try makeDate(year: 2026, month: 1, day: 1)
    let account = LegacyAccount(
        id: id,
        institutionName: "Bank A",
        accountType: .bank,
        contactInfo: "hotline",
        createdAt: created
    )

    #expect(account.id == id)
    #expect(account.lastFourDigits == nil)
    #expect(account.approximateBalance == nil)
    #expect(account.notes == nil)
    #expect(account.accountType == .bank)
    #expect(account.createdAt == created)
}

@Test("account stores full detail values")
func accountFullValues() throws {
    let id = try fixedID(2)
    let created = try makeDate(year: 2026, month: 3, day: 15)
    let account = LegacyAccount(
        id: id,
        institutionName: "Brokerage X",
        accountType: .brokerage,
        lastFourDigits: "9876",
        approximateBalance: Decimal(string: "12500000"),
        contactInfo: "broker@example.com",
        notes: "Long term",
        createdAt: created
    )

    #expect(account.lastFourDigits == "9876")
    #expect(account.approximateBalance == Decimal(12_500_000))
    #expect(account.notes == "Long term")
    #expect(account.accountType == .brokerage)
}

@Test("account codable round trip with decimal balance")
func accountCodableRoundTrip() throws {
    let account = LegacyAccount(
        id: try fixedID(3),
        institutionName: "Bank B",
        accountType: .wallet,
        lastFourDigits: "0001",
        approximateBalance: Decimal(string: "999999.99"),
        contactInfo: "info",
        notes: nil,
        createdAt: try makeDate(year: 2025, month: 12, day: 31)
    )

    let data = try JSONEncoder().encode(account)
    let decoded = try JSONDecoder().decode(LegacyAccount.self, from: data)
    #expect(decoded == account)
}

@Test("accounts with differing fields are not equal")
func accountInequality() throws {
    let id = try fixedID(4)
    let created = try makeDate(year: 2026, month: 1, day: 1)
    let base = LegacyAccount(id: id, institutionName: "Bank", accountType: .bank, contactInfo: "c", createdAt: created)
    let differentType = LegacyAccount(id: id, institutionName: "Bank", accountType: .crypto, contactInfo: "c", createdAt: created)
    #expect(base != differentType)
}

// MARK: - LegacyInsurance

@Test("insurance initializer and codable round trip")
func insuranceRoundTrip() throws {
    let insurance = LegacyInsurance(
        id: try fixedID(10),
        provider: "Provider",
        policyName: "Life",
        contactInfo: "agent",
        notes: "yearly"
    )
    #expect(insurance.notes == "yearly")

    let data = try JSONEncoder().encode(insurance)
    let decoded = try JSONDecoder().decode(LegacyInsurance.self, from: data)
    #expect(decoded == insurance)
}

@Test("insurance default notes are nil")
func insuranceDefaultNotes() throws {
    let insurance = LegacyInsurance(id: try fixedID(11), provider: "P", policyName: "N", contactInfo: "c")
    #expect(insurance.notes == nil)
}

// MARK: - LegacyInvestment

@Test("investment initializer and codable round trip")
func investmentRoundTrip() throws {
    let investment = LegacyInvestment(
        id: try fixedID(20),
        institutionName: "Fund House",
        assetDescription: "Index fund",
        contactInfo: "manager",
        notes: nil
    )
    #expect(investment.notes == nil)

    let data = try JSONEncoder().encode(investment)
    let decoded = try JSONDecoder().decode(LegacyInvestment.self, from: data)
    #expect(decoded == investment)
}

// MARK: - LegacyDebt

@Test("debt initializer keeps optional amount")
func debtOptionalAmount() throws {
    let debt = LegacyDebt(id: try fixedID(30), lenderName: "Lender", contactInfo: "c")
    #expect(debt.amount == nil)
    #expect(debt.notes == nil)
}

@Test("debt codable round trip with amount")
func debtRoundTrip() throws {
    let debt = LegacyDebt(
        id: try fixedID(31),
        lenderName: "Lender",
        amount: Decimal(string: "5000000"),
        contactInfo: "c",
        notes: "monthly"
    )
    let data = try JSONEncoder().encode(debt)
    let decoded = try JSONDecoder().decode(LegacyDebt.self, from: data)
    #expect(decoded == debt)
    #expect(decoded.amount == Decimal(5_000_000))
}

// MARK: - LegacyDigitalAsset

@Test("digital asset initializer and round trip")
func digitalAssetRoundTrip() throws {
    let asset = LegacyDigitalAsset(
        id: try fixedID(40),
        name: "Crypto wallet",
        locationHint: "hardware device",
        notes: "seed phrase offline"
    )
    let data = try JSONEncoder().encode(asset)
    let decoded = try JSONDecoder().decode(LegacyDigitalAsset.self, from: data)
    #expect(decoded == asset)
    #expect(decoded.locationHint == "hardware device")
}

// MARK: - EmergencyContact

@Test("emergency contact initializer and round trip")
func emergencyContactRoundTrip() throws {
    let contact = EmergencyContact(
        id: try fixedID(50),
        name: "Jane",
        relationship: "Spouse",
        contactInfo: "phone"
    )
    let data = try JSONEncoder().encode(contact)
    let decoded = try JSONDecoder().decode(EmergencyContact.self, from: data)
    #expect(decoded == contact)
    #expect(decoded.relationship == "Spouse")
}

// MARK: - LegacyVault

@Test("vault default initializer yields empty collections")
func vaultDefaultCollections() throws {
    let created = try makeDate(year: 2026, month: 1, day: 1)
    let vault = LegacyVault(id: try fixedID(60), owner: "Owner", createdAt: created, lastUpdatedAt: created)

    #expect(vault.financialAccounts.isEmpty)
    #expect(vault.insurancePolicies.isEmpty)
    #expect(vault.investments.isEmpty)
    #expect(vault.debts.isEmpty)
    #expect(vault.digitalAssets.isEmpty)
    #expect(vault.emergencyContacts.isEmpty)
    #expect(vault.instructions.isEmpty)
    #expect(vault.owner == "Owner")
}

@Test("vault codable round trip preserves nested collections")
func vaultCodableRoundTrip() throws {
    let created = try makeDate(year: 2026, month: 2, day: 1)
    let updated = try makeDate(year: 2026, month: 2, day: 2)
    let vault = LegacyVault(
        id: try fixedID(61),
        owner: "Family",
        createdAt: created,
        lastUpdatedAt: updated,
        financialAccounts: [
            LegacyAccount(id: try fixedID(62), institutionName: "Bank", accountType: .bank, contactInfo: "c", createdAt: created),
        ],
        insurancePolicies: [
            LegacyInsurance(id: try fixedID(63), provider: "P", policyName: "N", contactInfo: "c"),
        ],
        investments: [
            LegacyInvestment(id: try fixedID(64), institutionName: "Fund", assetDescription: "A", contactInfo: "c"),
        ],
        debts: [
            LegacyDebt(id: try fixedID(65), lenderName: "L", amount: Decimal(100), contactInfo: "c"),
        ],
        digitalAssets: [
            LegacyDigitalAsset(id: try fixedID(66), name: "W", locationHint: "h"),
        ],
        instructions: "Follow steps",
        emergencyContacts: [
            EmergencyContact(id: try fixedID(67), name: "C", relationship: "R", contactInfo: "c"),
        ]
    )

    let data = try JSONEncoder().encode(vault)
    let decoded = try JSONDecoder().decode(LegacyVault.self, from: data)
    #expect(decoded == vault)
    #expect(decoded.financialAccounts.count == 1)
    #expect(decoded.emergencyContacts.count == 1)
}

@Test("vault empty static has Kaso owner and no entries")
func vaultEmptyStatic() {
    let vault = LegacyVault.empty
    #expect(vault.owner == "Kaso")
    #expect(vault.financialAccounts.isEmpty)
    #expect(vault.instructions.isEmpty)
}

@Test("vault preview static is populated deterministically")
func vaultPreviewStatic() {
    let vault = LegacyVault.preview
    #expect(vault.owner == "Gia đình")
    #expect(vault.createdAt == Date(timeIntervalSinceReferenceDate: 1_000))
    #expect(vault.lastUpdatedAt == Date(timeIntervalSinceReferenceDate: 2_000))
    #expect(vault.financialAccounts.count == 1)
    let account = vault.financialAccounts.first
    #expect(account?.accountType == .bank)
    #expect(account?.lastFourDigits == "1234")
    #expect(account?.approximateBalance == Decimal(20_000_000))
    #expect(vault.instructions == "Liên hệ ngân hàng trước khi tất toán.")
}

@Test("vault preview round trips through JSON")
func vaultPreviewRoundTrip() throws {
    let data = try JSONEncoder().encode(LegacyVault.preview)
    let decoded = try JSONDecoder().decode(LegacyVault.self, from: data)
    #expect(decoded == LegacyVault.preview)
}
