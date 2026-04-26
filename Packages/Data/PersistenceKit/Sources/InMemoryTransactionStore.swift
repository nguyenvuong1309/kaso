import Foundation
import TransactionDomain

public actor InMemoryTransactionStore {
    private var transactions: [Transaction]

    public init(seed: [Transaction] = []) {
        transactions = seed
    }

    public func fetchAll() -> [Transaction] {
        transactions.sorted { $0.occurredAt > $1.occurredAt }
    }

    public func save(_ transaction: Transaction) {
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions[index] = transaction
        } else {
            transactions.append(transaction)
        }
    }

    public nonisolated func repository() -> TransactionRepository {
        TransactionRepository(
            fetchAll: {
                await self.fetchAll()
            },
            save: { transaction in
                await self.save(transaction)
            }
        )
    }
}

@available(iOS 17.0, macOS 14.0, *)
public enum KasoPersistenceSchema {
    public static let version = "2026.04.0"
}
