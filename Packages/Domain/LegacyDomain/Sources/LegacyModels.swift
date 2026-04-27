import Foundation

public enum LegacyAccountType: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case bank
    case wallet
    case crypto
    case brokerage
    case insurance
    case other

    public var id: String { rawValue }

    public var titleKey: String {
        "legacy.accountType.\(rawValue)"
    }
}

public struct LegacyAccount: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var institutionName: String
    public var accountType: LegacyAccountType
    public var lastFourDigits: String?
    public var approximateBalance: Decimal?
    public var contactInfo: String
    public var notes: String?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        institutionName: String,
        accountType: LegacyAccountType,
        lastFourDigits: String? = nil,
        approximateBalance: Decimal? = nil,
        contactInfo: String,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.institutionName = institutionName
        self.accountType = accountType
        self.lastFourDigits = lastFourDigits
        self.approximateBalance = approximateBalance
        self.contactInfo = contactInfo
        self.notes = notes
        self.createdAt = createdAt
    }
}

public struct LegacyInsurance: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var provider: String
    public var policyName: String
    public var contactInfo: String
    public var notes: String?

    public init(
        id: UUID = UUID(),
        provider: String,
        policyName: String,
        contactInfo: String,
        notes: String? = nil
    ) {
        self.id = id
        self.provider = provider
        self.policyName = policyName
        self.contactInfo = contactInfo
        self.notes = notes
    }
}

public struct LegacyInvestment: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var institutionName: String
    public var assetDescription: String
    public var contactInfo: String
    public var notes: String?

    public init(
        id: UUID = UUID(),
        institutionName: String,
        assetDescription: String,
        contactInfo: String,
        notes: String? = nil
    ) {
        self.id = id
        self.institutionName = institutionName
        self.assetDescription = assetDescription
        self.contactInfo = contactInfo
        self.notes = notes
    }
}

public struct LegacyDebt: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var lenderName: String
    public var amount: Decimal?
    public var contactInfo: String
    public var notes: String?

    public init(
        id: UUID = UUID(),
        lenderName: String,
        amount: Decimal? = nil,
        contactInfo: String,
        notes: String? = nil
    ) {
        self.id = id
        self.lenderName = lenderName
        self.amount = amount
        self.contactInfo = contactInfo
        self.notes = notes
    }
}

public struct LegacyDigitalAsset: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var locationHint: String
    public var notes: String?

    public init(
        id: UUID = UUID(),
        name: String,
        locationHint: String,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.locationHint = locationHint
        self.notes = notes
    }
}

public struct EmergencyContact: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var relationship: String
    public var contactInfo: String

    public init(
        id: UUID = UUID(),
        name: String,
        relationship: String,
        contactInfo: String
    ) {
        self.id = id
        self.name = name
        self.relationship = relationship
        self.contactInfo = contactInfo
    }
}

public struct LegacyVault: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var owner: String
    public var createdAt: Date
    public var lastUpdatedAt: Date
    public var financialAccounts: [LegacyAccount]
    public var insurancePolicies: [LegacyInsurance]
    public var investments: [LegacyInvestment]
    public var debts: [LegacyDebt]
    public var digitalAssets: [LegacyDigitalAsset]
    public var instructions: String
    public var emergencyContacts: [EmergencyContact]

    public init(
        id: UUID = UUID(),
        owner: String,
        createdAt: Date = Date(),
        lastUpdatedAt: Date = Date(),
        financialAccounts: [LegacyAccount] = [],
        insurancePolicies: [LegacyInsurance] = [],
        investments: [LegacyInvestment] = [],
        debts: [LegacyDebt] = [],
        digitalAssets: [LegacyDigitalAsset] = [],
        instructions: String = "",
        emergencyContacts: [EmergencyContact] = []
    ) {
        self.id = id
        self.owner = owner
        self.createdAt = createdAt
        self.lastUpdatedAt = lastUpdatedAt
        self.financialAccounts = financialAccounts
        self.insurancePolicies = insurancePolicies
        self.investments = investments
        self.debts = debts
        self.digitalAssets = digitalAssets
        self.instructions = instructions
        self.emergencyContacts = emergencyContacts
    }
}

public extension LegacyVault {
    static let empty = LegacyVault(owner: "Kaso")

    static let preview = LegacyVault(
        owner: "Gia đình",
        createdAt: Date(timeIntervalSinceReferenceDate: 1_000),
        lastUpdatedAt: Date(timeIntervalSinceReferenceDate: 2_000),
        financialAccounts: [
            LegacyAccount(
                institutionName: "Ngân hàng mẫu",
                accountType: .bank,
                lastFourDigits: "1234",
                approximateBalance: 20_000_000,
                contactInfo: "Hotline ngân hàng",
                notes: "Không lưu mật khẩu trong vault."
            ),
        ],
        instructions: "Liên hệ ngân hàng trước khi tất toán."
    )
}
