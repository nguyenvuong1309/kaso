import Foundation
import Testing
@testable import BNPLDomain

// MARK: - BNPLRepository.empty

@Test("empty repository fetchAll returns no obligations")
func emptyRepositoryFetchAll() async throws {
    let result = try await BNPLRepository.empty.fetchAll()
    #expect(result.isEmpty)
}

@Test("empty repository save and delete are no-ops that do not throw")
func emptyRepositoryMutationsNoOp() async throws {
    let calendar = Calendar(identifier: .gregorian)
    var components = DateComponents()
    components.year = 2026
    components.month = 6
    components.day = 1
    let date = try #require(calendar.date(from: components))
    let obligation = BNPLObligation(
        provider: .generic,
        purchaseName: "Noop",
        totalAmount: 1_000_000,
        purchaseDate: date,
        installmentCount: 1
    )
    try await BNPLRepository.empty.save(obligation)
    try await BNPLRepository.empty.delete(obligation.id)
}

// MARK: - BNPLRepository custom closures

@Test("repository routes through injected closures")
func repositoryInjectedClosures() async throws {
    let calendar = Calendar(identifier: .gregorian)
    var components = DateComponents()
    components.year = 2026
    components.month = 6
    components.day = 1
    let date = try #require(calendar.date(from: components))
    let stored = BNPLObligation(
        provider: .atome,
        purchaseName: "Stored",
        totalAmount: 2_000_000,
        purchaseDate: date,
        installmentCount: 2
    )
    let repository = BNPLRepository(
        fetchAll: { [stored] },
        save: { _ in },
        delete: { _ in }
    )
    let fetched = try await repository.fetchAll()
    #expect(fetched == [stored])
}

// MARK: - BNPLRepository.preview

@Test("preview repository returns two seeded obligations with installments")
func previewRepositoryFetchAll() async throws {
    let result = try await BNPLRepository.preview.fetchAll()
    #expect(result.count == 2)
    let names = result.map(\.purchaseName)
    #expect(names.contains("iPhone 15"))
    #expect(names.contains("Tủ lạnh"))
    #expect(result.allSatisfy { $0.installments.isEmpty == false })
    let iphone = try #require(result.first { $0.purchaseName == "iPhone 15" })
    #expect(iphone.provider == .shopeePayLater)
    #expect(iphone.installments.count == 6)
}

// MARK: - BNPLContextClient

@Test("empty context client reports zero monthly income")
func emptyContextClientIncome() async throws {
    let income = try await BNPLContextClient.empty.monthlyIncome()
    #expect(income == 0)
}

@Test("preview context client reports seeded monthly income")
func previewContextClientIncome() async throws {
    let income = try await BNPLContextClient.preview.monthlyIncome()
    #expect(income == 20_000_000)
}

@Test("context client routes through injected closure")
func contextClientInjectedClosure() async throws {
    let client = BNPLContextClient(monthlyIncome: { 7_500_000 })
    let income = try await client.monthlyIncome()
    #expect(income == 7_500_000)
}
