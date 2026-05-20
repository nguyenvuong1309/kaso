import Foundation

public struct SpendingMapRepository: Sendable {
    public var fetchAll: @Sendable () async throws -> [SpendingMapEntry]
    public var save: @Sendable (SpendingMapEntry) async throws -> Void
    public var delete: @Sendable (UUID) async throws -> Void

    public init(
        fetchAll: @escaping @Sendable () async throws -> [SpendingMapEntry],
        save: @escaping @Sendable (SpendingMapEntry) async throws -> Void,
        delete: @escaping @Sendable (UUID) async throws -> Void
    ) {
        self.fetchAll = fetchAll
        self.save = save
        self.delete = delete
    }
}

public extension SpendingMapRepository {
    static let empty = SpendingMapRepository(
        fetchAll: { [] },
        save: { _ in },
        delete: { _ in }
    )

    static let preview = SpendingMapRepository(
        fetchAll: {
            let now = Date()
            let calendar = Calendar.current
            func at(_ days: Int) -> Date {
                calendar.date(byAdding: .day, value: -days, to: now) ?? now
            }
            return [
                // District 1 cluster
                SpendingMapEntry(
                    label: "Cà phê Bến Thành",
                    amount: 65_000,
                    categoryID: "food",
                    latitude: 10.7720,
                    longitude: 106.6981,
                    occurredAt: at(2),
                    note: nil
                ),
                SpendingMapEntry(
                    label: "Bữa trưa Lê Lợi",
                    amount: 150_000,
                    categoryID: "food",
                    latitude: 10.7724,
                    longitude: 106.6990,
                    occurredAt: at(5)
                ),
                SpendingMapEntry(
                    label: "Mua áo Diamond Plaza",
                    amount: 850_000,
                    categoryID: "shopping",
                    latitude: 10.7800,
                    longitude: 106.7012,
                    occurredAt: at(10)
                ),
                // Thảo Điền cluster
                SpendingMapEntry(
                    label: "Tiệc tối Thảo Điền",
                    amount: 1_200_000,
                    categoryID: "entertainment",
                    latitude: 10.8045,
                    longitude: 106.7423,
                    occurredAt: at(15)
                ),
            ]
        },
        save: { _ in },
        delete: { _ in }
    )
}
