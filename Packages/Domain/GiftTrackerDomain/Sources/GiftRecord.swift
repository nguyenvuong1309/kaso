import Foundation

public enum GiftEventKind: String, CaseIterable, Codable, Equatable, Sendable, Identifiable {
    case tet
    case wedding
    case newHome
    case babyShower
    case funeral
    case birthday
    case other

    public var id: String { rawValue }

    public var symbolName: String {
        switch self {
        case .tet: "envelope.fill"
        case .wedding: "heart.fill"
        case .newHome: "house.fill"
        case .babyShower: "figure.and.child.holdinghands"
        case .funeral: "leaf.fill"
        case .birthday: "birthday.cake.fill"
        case .other: "gift.fill"
        }
    }

    public var nameKey: String { "gift.eventKind.\(rawValue)" }
}

public enum GiftDirection: String, CaseIterable, Codable, Equatable, Sendable {
    case given
    case received

    public var nameKey: String { "gift.direction.\(rawValue)" }
}

public struct GiftRecord: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var personName: String
    public var eventKind: GiftEventKind
    public var direction: GiftDirection
    public var amount: Decimal
    public var eventDate: Date
    public var note: String?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        personName: String,
        eventKind: GiftEventKind,
        direction: GiftDirection,
        amount: Decimal,
        eventDate: Date,
        note: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.personName = personName
        self.eventKind = eventKind
        self.direction = direction
        self.amount = amount
        self.eventDate = eventDate
        self.note = note
        self.createdAt = createdAt
    }
}
