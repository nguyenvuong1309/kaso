import ComposableArchitecture
import InvestmentDomain
import WealthDomain

private enum HoldingRepositoryKey: DependencyKey {
    static let liveValue = HoldingRepository.empty
    static let previewValue = HoldingRepository.preview
    static let testValue = HoldingRepository.empty
}

private enum PriceQuoteRepositoryKey: DependencyKey {
    static let liveValue = PriceQuoteRepository.empty
    static let previewValue = PriceQuoteRepository.preview
    static let testValue = PriceQuoteRepository.empty
}

private enum TargetAllocationRepositoryKey: DependencyKey {
    static let liveValue = TargetAllocationRepository.empty
    static let previewValue = TargetAllocationRepository.preview
    static let testValue = TargetAllocationRepository.empty
}

private enum MarketPriceProviderKey: DependencyKey {
    static let liveValue = MarketPriceProvider.offlineSnapshot
    static let previewValue = MarketPriceProvider.offlineSnapshot
    static let testValue = MarketPriceProvider.empty
}

public struct InvestmentAssetSyncClient: Sendable {
    public var replaceAutoTracked: @Sendable ([Asset]) async throws -> Void

    public init(
        replaceAutoTracked: @escaping @Sendable ([Asset]) async throws -> Void
    ) {
        self.replaceAutoTracked = replaceAutoTracked
    }
}

public extension InvestmentAssetSyncClient {
    static let empty = InvestmentAssetSyncClient(
        replaceAutoTracked: { _ in }
    )
}

private enum InvestmentAssetSyncClientKey: DependencyKey {
    static let liveValue = InvestmentAssetSyncClient.empty
    static let previewValue = InvestmentAssetSyncClient.empty
    static let testValue = InvestmentAssetSyncClient.empty
}

public extension HoldingRepository {
    static let preview = HoldingRepository(
        fetchAll: {
            [
                Holding(
                    symbol: "FPT",
                    name: "FPT Corp",
                    assetClass: .stock,
                    lots: [
                        InvestmentLot(
                            quantity: 100,
                            costBasisPerUnit: 90_000,
                            purchasedAt: .now
                        ),
                    ]
                ),
            ]
        },
        save: { _ in },
        delete: { _ in }
    )
}

public extension PriceQuoteRepository {
    static let preview = PriceQuoteRepository(
        fetchAll: {
            [
                PriceQuote(symbol: "FPT", price: 110_000, asOf: .now),
            ]
        },
        save: { _ in },
        saveMany: { _ in }
    )
}

public extension TargetAllocationRepository {
    static let preview = TargetAllocationRepository(
        load: {
            TargetAllocation(fractions: [.stock: 0.7, .gold: 0.3])
        },
        save: { _ in }
    )
}

public extension DependencyValues {
    var holdingRepository: HoldingRepository {
        get { self[HoldingRepositoryKey.self] }
        set { self[HoldingRepositoryKey.self] = newValue }
    }

    var priceQuoteRepository: PriceQuoteRepository {
        get { self[PriceQuoteRepositoryKey.self] }
        set { self[PriceQuoteRepositoryKey.self] = newValue }
    }

    var targetAllocationRepository: TargetAllocationRepository {
        get { self[TargetAllocationRepositoryKey.self] }
        set { self[TargetAllocationRepositoryKey.self] = newValue }
    }

    var investmentAssetSyncClient: InvestmentAssetSyncClient {
        get { self[InvestmentAssetSyncClientKey.self] }
        set { self[InvestmentAssetSyncClientKey.self] = newValue }
    }

    var marketPriceProvider: MarketPriceProvider {
        get { self[MarketPriceProviderKey.self] }
        set { self[MarketPriceProviderKey.self] = newValue }
    }
}
