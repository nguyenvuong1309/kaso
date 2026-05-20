import Foundation

public enum HuiPeriodKind: String, CaseIterable, Codable, Equatable, Sendable, Identifiable {
    case weekly
    case biweekly
    case monthly

    public var id: String { rawValue }

    public var nameKey: String { "hui.period.\(rawValue)" }

    /// Approximate number of days between two consecutive cycles.
    public var approximateDays: Int {
        switch self {
        case .weekly: 7
        case .biweekly: 14
        case .monthly: 30
        }
    }

    public var calendarComponent: Calendar.Component {
        switch self {
        case .weekly, .biweekly: .day
        case .monthly: .month
        }
    }

    public var calendarValue: Int {
        switch self {
        case .weekly: 7
        case .biweekly: 14
        case .monthly: 1
        }
    }
}

/// One contribution period of a hụi/họ group. The app is a personal ledger only —
/// it never holds money and does not broker between members.
public struct HuiCycle: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var index: Int
    public var dueDate: Date
    public var isPaid: Bool
    public var isReceived: Bool
    public var receivedAmount: Decimal?
    public var note: String?

    public init(
        id: UUID = UUID(),
        index: Int,
        dueDate: Date,
        isPaid: Bool = false,
        isReceived: Bool = false,
        receivedAmount: Decimal? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.index = index
        self.dueDate = dueDate
        self.isPaid = isPaid
        self.isReceived = isReceived
        self.receivedAmount = receivedAmount
        self.note = note
    }
}

public struct HuiGroup: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var organizerName: String
    public var contributionAmount: Decimal
    public var periodKind: HuiPeriodKind
    public var memberCount: Int
    public var startDate: Date
    public var note: String?
    public var cycles: [HuiCycle]
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        organizerName: String,
        contributionAmount: Decimal,
        periodKind: HuiPeriodKind,
        memberCount: Int,
        startDate: Date,
        note: String? = nil,
        cycles: [HuiCycle] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.organizerName = organizerName
        self.contributionAmount = contributionAmount
        self.periodKind = periodKind
        self.memberCount = memberCount
        self.startDate = startDate
        self.note = note
        self.cycles = cycles
        self.createdAt = createdAt
    }
}

public enum HuiCycleScheduleBuilder {
    /// Generates one cycle per member, spaced by the group's period.
    public static func build(
        memberCount: Int,
        startDate: Date,
        periodKind: HuiPeriodKind,
        calendar: Calendar = .current
    ) -> [HuiCycle] {
        guard memberCount > 0 else { return [] }
        return (0 ..< memberCount).map { offset in
            let dueDate = calendar.date(
                byAdding: periodKind.calendarComponent,
                value: periodKind.calendarValue * offset,
                to: startDate
            ) ?? startDate
            return HuiCycle(index: offset + 1, dueDate: dueDate)
        }
    }
}
