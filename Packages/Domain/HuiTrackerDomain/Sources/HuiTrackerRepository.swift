import Foundation

public struct HuiTrackerRepository: Sendable {
    public var fetchAll: @Sendable () async throws -> [HuiGroup]
    public var save: @Sendable (HuiGroup) async throws -> Void
    public var delete: @Sendable (UUID) async throws -> Void

    public init(
        fetchAll: @escaping @Sendable () async throws -> [HuiGroup],
        save: @escaping @Sendable (HuiGroup) async throws -> Void,
        delete: @escaping @Sendable (UUID) async throws -> Void
    ) {
        self.fetchAll = fetchAll
        self.save = save
        self.delete = delete
    }
}

public extension HuiTrackerRepository {
    static let empty = HuiTrackerRepository(
        fetchAll: { [] },
        save: { _ in },
        delete: { _ in }
    )

    static let preview = HuiTrackerRepository(
        fetchAll: {
            let calendar = Calendar.current
            let now = Date()
            let start = calendar.date(byAdding: .month, value: -2, to: now) ?? now
            var cycles = HuiCycleScheduleBuilder.build(
                memberCount: 6,
                startDate: start,
                periodKind: .monthly
            )
            if cycles.indices.contains(0) { cycles[0].isPaid = true }
            if cycles.indices.contains(1) {
                cycles[1].isPaid = true
                cycles[1].isReceived = true
                cycles[1].receivedAmount = 12_000_000
            }
            return [
                HuiGroup(
                    name: "Hụi chợ Bà Chiểu",
                    organizerName: "Cô Bảy",
                    contributionAmount: 2_000_000,
                    periodKind: .monthly,
                    memberCount: 6,
                    startDate: start,
                    note: "Dây hụi tháng",
                    cycles: cycles
                ),
            ]
        },
        save: { _ in },
        delete: { _ in }
    )
}
