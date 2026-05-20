import Foundation

public struct BNPLRepository: Sendable {
    public var fetchAll: @Sendable () async throws -> [BNPLObligation]
    public var save: @Sendable (BNPLObligation) async throws -> Void
    public var delete: @Sendable (UUID) async throws -> Void

    public init(
        fetchAll: @escaping @Sendable () async throws -> [BNPLObligation],
        save: @escaping @Sendable (BNPLObligation) async throws -> Void,
        delete: @escaping @Sendable (UUID) async throws -> Void
    ) {
        self.fetchAll = fetchAll
        self.save = save
        self.delete = delete
    }
}

public extension BNPLRepository {
    static let empty = BNPLRepository(
        fetchAll: { [] },
        save: { _ in },
        delete: { _ in }
    )

    static let preview = BNPLRepository(
        fetchAll: {
            let calendar = Calendar.current
            let now = Date()
            let installmentsA = BNPLInstallmentBuilder.generateMonthly(
                totalAmount: 6_000_000,
                installmentCount: 6,
                startDate: now,
                calendar: calendar
            )
            let installmentsB = BNPLInstallmentBuilder.generateMonthly(
                totalAmount: 3_000_000,
                installmentCount: 3,
                startDate: calendar.date(byAdding: .month, value: -1, to: now) ?? now,
                calendar: calendar
            )
            return [
                BNPLObligation(
                    provider: .shopeePayLater,
                    purchaseName: "iPhone 15",
                    totalAmount: 6_000_000,
                    purchaseDate: now,
                    installmentCount: 6,
                    installments: installmentsA
                ),
                BNPLObligation(
                    provider: .atome,
                    purchaseName: "Tủ lạnh",
                    totalAmount: 3_000_000,
                    purchaseDate: calendar.date(byAdding: .month, value: -1, to: now) ?? now,
                    installmentCount: 3,
                    installments: installmentsB
                ),
            ]
        },
        save: { _ in },
        delete: { _ in }
    )
}

public struct BNPLContextClient: Sendable {
    public var monthlyIncome: @Sendable () async throws -> Decimal

    public init(monthlyIncome: @escaping @Sendable () async throws -> Decimal) {
        self.monthlyIncome = monthlyIncome
    }
}

public extension BNPLContextClient {
    static let empty = BNPLContextClient(monthlyIncome: { 0 })
    static let preview = BNPLContextClient(monthlyIncome: { 20_000_000 })
}
