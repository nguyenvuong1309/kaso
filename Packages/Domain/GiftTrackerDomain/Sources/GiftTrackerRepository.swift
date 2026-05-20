import Foundation

public struct GiftTrackerRepository: Sendable {
    public var fetchAll: @Sendable () async throws -> [GiftRecord]
    public var save: @Sendable (GiftRecord) async throws -> Void
    public var delete: @Sendable (UUID) async throws -> Void

    public init(
        fetchAll: @escaping @Sendable () async throws -> [GiftRecord],
        save: @escaping @Sendable (GiftRecord) async throws -> Void,
        delete: @escaping @Sendable (UUID) async throws -> Void
    ) {
        self.fetchAll = fetchAll
        self.save = save
        self.delete = delete
    }
}

public extension GiftTrackerRepository {
    static let empty = GiftTrackerRepository(
        fetchAll: { [] },
        save: { _ in },
        delete: { _ in }
    )

    static let preview = GiftTrackerRepository(
        fetchAll: {
            let calendar = Calendar.current
            let now = Date()
            let twoMonthsAgo = calendar.date(byAdding: .month, value: -2, to: now) ?? now
            let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: now) ?? now
            return [
                GiftRecord(
                    personName: "Nguyễn Văn Hùng",
                    eventKind: .wedding,
                    direction: .given,
                    amount: 1_000_000,
                    eventDate: twoMonthsAgo,
                    note: "Đám cưới tại Long An"
                ),
                GiftRecord(
                    personName: "Trần Thị Mai",
                    eventKind: .tet,
                    direction: .received,
                    amount: 500_000,
                    eventDate: sixMonthsAgo
                ),
                GiftRecord(
                    personName: "Nguyễn Văn Hùng",
                    eventKind: .tet,
                    direction: .received,
                    amount: 500_000,
                    eventDate: sixMonthsAgo
                ),
            ]
        },
        save: { _ in },
        delete: { _ in }
    )
}
