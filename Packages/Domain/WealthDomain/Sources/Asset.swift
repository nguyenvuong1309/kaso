import Foundation

public struct Asset: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var type: AssetType
    public var currentValue: Decimal
    public var acquiredAt: Date?
    public var note: String?
    public var isAutoTracked: Bool
    public var lastUpdatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        type: AssetType,
        currentValue: Decimal,
        acquiredAt: Date? = nil,
        note: String? = nil,
        isAutoTracked: Bool = false,
        lastUpdatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.currentValue = currentValue
        self.acquiredAt = acquiredAt
        self.note = note
        self.isAutoTracked = isAutoTracked
        self.lastUpdatedAt = lastUpdatedAt
    }
}

public extension Asset {
    static func sample(
        id: UUID = UUID(),
        name: String = "Tài khoản tiết kiệm",
        type: AssetType = .bankSavings,
        currentValue: Decimal = 50_000_000
    ) -> Asset {
        Asset(
            id: id,
            name: name,
            type: type,
            currentValue: currentValue
        )
    }
}
