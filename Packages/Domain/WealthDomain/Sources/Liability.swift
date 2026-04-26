import Foundation

public struct Liability: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var type: LiabilityType
    public var principalRemaining: Decimal
    public var note: String?
    public var isAutoTracked: Bool
    public var lastUpdatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        type: LiabilityType,
        principalRemaining: Decimal,
        note: String? = nil,
        isAutoTracked: Bool = false,
        lastUpdatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.principalRemaining = principalRemaining
        self.note = note
        self.isAutoTracked = isAutoTracked
        self.lastUpdatedAt = lastUpdatedAt
    }
}
