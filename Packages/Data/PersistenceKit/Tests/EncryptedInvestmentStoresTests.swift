import Foundation
import InvestmentDomain
import PersistenceKit
import Testing

@Test("saves fetches and deletes holdings encrypted")
func savesFetchesAndDeletesHoldingsEncrypted() async throws {
    let directoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let fileURL = directoryURL.appendingPathComponent("holdings.kasoenc")
    defer {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    let holding = Holding(
        symbol: "FPT",
        name: "FPT Corp",
        assetClass: .stock,
        lots: [
            InvestmentLot(
                quantity: 100,
                costBasisPerUnit: 90_000,
                purchasedAt: Date(timeIntervalSinceReferenceDate: 100)
            ),
        ],
        createdAt: Date(timeIntervalSinceReferenceDate: 50)
    )
    let store = EncryptedHoldingStore(
        fileURL: fileURL,
        keyDataProvider: { Data(repeating: 47, count: 32) }
    )

    try await store.save(holding)

    let loadedHoldings = try await store.fetchAll()
    let rawData = try Data(contentsOf: fileURL)
    let plainData = try JSONEncoder().encode([holding])

    #expect(loadedHoldings == [holding])
    #expect(rawData != plainData)

    try await store.delete(holding.id)
    #expect(try await store.fetchAll() == [])
}

@Test("saves and replaces price quotes encrypted")
func savesAndReplacesPriceQuotesEncrypted() async throws {
    let directoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let fileURL = directoryURL.appendingPathComponent("quotes.kasoenc")
    defer {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    let oldQuote = PriceQuote(
        symbol: "FPT",
        price: 90_000,
        asOf: Date(timeIntervalSinceReferenceDate: 100)
    )
    let newQuote = PriceQuote(
        symbol: "FPT",
        price: 110_000,
        asOf: Date(timeIntervalSinceReferenceDate: 200)
    )
    let store = EncryptedPriceQuoteStore(
        fileURL: fileURL,
        keyDataProvider: { Data(repeating: 53, count: 32) }
    )

    try await store.save(oldQuote)
    try await store.save(newQuote)

    let loadedQuotes = try await store.fetchAll()
    let rawData = try Data(contentsOf: fileURL)
    let plainData = try JSONEncoder().encode([newQuote])

    #expect(loadedQuotes == [newQuote])
    #expect(rawData != plainData)
}

@Test("saves and loads target allocation encrypted")
func savesAndLoadsTargetAllocationEncrypted() async throws {
    let directoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let fileURL = directoryURL.appendingPathComponent("target.kasoenc")
    defer {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    let target = TargetAllocation(fractions: [.stock: 0.7, .gold: 0.3])
    let store = EncryptedTargetAllocationStore(
        fileURL: fileURL,
        keyDataProvider: { Data(repeating: 59, count: 32) }
    )

    try await store.save(target)

    let loadedTarget = try await store.load()
    let rawData = try Data(contentsOf: fileURL)
    let plainData = try JSONEncoder().encode(target)

    #expect(loadedTarget == target)
    #expect(rawData != plainData)
}
