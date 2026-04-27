import Foundation

public struct PhantomExpense: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var amount: Decimal
    public var category: PhantomExpenseCategory
    public var avoidedAt: Date
    public var note: String?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        amount: Decimal,
        category: PhantomExpenseCategory = .other,
        avoidedAt: Date = Date(),
        note: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.avoidedAt = avoidedAt
        self.note = note
        self.createdAt = createdAt
    }
}
