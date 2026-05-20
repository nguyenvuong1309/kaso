import Foundation

public struct SpendingMapEntry: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public var label: String
    public var amount: Decimal
    public var categoryID: String?
    public var latitude: Double
    public var longitude: Double
    public var occurredAt: Date
    public var note: String?

    public init(
        id: UUID = UUID(),
        label: String,
        amount: Decimal,
        categoryID: String? = nil,
        latitude: Double,
        longitude: Double,
        occurredAt: Date,
        note: String? = nil
    ) {
        self.id = id
        self.label = label
        self.amount = amount
        self.categoryID = categoryID
        self.latitude = latitude
        self.longitude = longitude
        self.occurredAt = occurredAt
        self.note = note
    }
}
