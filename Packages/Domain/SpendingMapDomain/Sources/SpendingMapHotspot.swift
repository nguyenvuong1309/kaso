import Foundation

public struct SpendingMapHotspot: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let latitude: Double
    public let longitude: Double
    public let totalAmount: Decimal
    public let entryCount: Int
    public let topCategoryID: String?
    public let entries: [SpendingMapEntry]
    public let intensity: Double // 0 ... 1 relative to the strongest hotspot

    public init(
        id: UUID = UUID(),
        latitude: Double,
        longitude: Double,
        totalAmount: Decimal,
        entryCount: Int,
        topCategoryID: String?,
        entries: [SpendingMapEntry],
        intensity: Double
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.totalAmount = totalAmount
        self.entryCount = entryCount
        self.topCategoryID = topCategoryID
        self.entries = entries
        self.intensity = intensity
    }
}

public struct SpendingMapSummary: Equatable, Sendable {
    public let hotspots: [SpendingMapHotspot]
    public let totalAmount: Decimal
    public let entryCount: Int
    public let period: SpendingMapPeriod
    public let generatedAt: Date

    public init(
        hotspots: [SpendingMapHotspot],
        totalAmount: Decimal,
        entryCount: Int,
        period: SpendingMapPeriod,
        generatedAt: Date
    ) {
        self.hotspots = hotspots
        self.totalAmount = totalAmount
        self.entryCount = entryCount
        self.period = period
        self.generatedAt = generatedAt
    }

    public static let empty = SpendingMapSummary(
        hotspots: [],
        totalAmount: 0,
        entryCount: 0,
        period: .last30Days,
        generatedAt: Date(timeIntervalSinceReferenceDate: 0)
    )
}
