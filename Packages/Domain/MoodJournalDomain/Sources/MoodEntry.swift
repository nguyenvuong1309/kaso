import Foundation

public struct MoodEntry: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var mood: Mood
    public var spendingTotalSnapshot: Decimal
    public var transactionIDs: [UUID]
    public var note: String?
    public var recordedAt: Date

    public init(
        id: UUID = UUID(),
        mood: Mood,
        spendingTotalSnapshot: Decimal = 0,
        transactionIDs: [UUID] = [],
        note: String? = nil,
        recordedAt: Date = Date()
    ) {
        self.id = id
        self.mood = mood
        self.spendingTotalSnapshot = spendingTotalSnapshot
        self.transactionIDs = transactionIDs
        self.note = note
        self.recordedAt = recordedAt
    }
}
