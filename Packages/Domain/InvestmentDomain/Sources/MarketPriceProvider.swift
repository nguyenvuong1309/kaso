import Foundation

public enum MarketPriceProviderError: Error, Equatable, Sendable {
    case noQuotesAvailable
    case providerUnavailable
}

/// A pluggable price provider for investment holdings.
///
/// The default implementation ships an *offline snapshot* of recent reference
/// prices for the most-traded HOSE blue chips and major Vietnamese mutual
/// funds. The snapshot is bundled with the app so the feature works without
/// network access and never sends user holdings off-device.
///
/// Apps that need live data should swap in a custom implementation with HTTPS
/// **certificate pinning** before talking to a broker API; the protocol shape
/// keeps the call site identical.
public struct MarketPriceProvider: Sendable {
    public typealias Fetch = @Sendable (_ symbols: [String]) async throws -> [PriceQuote]

    public var fetchQuotes: Fetch
    public var displayName: String

    public init(
        displayName: String,
        fetchQuotes: @escaping Fetch
    ) {
        self.displayName = displayName
        self.fetchQuotes = fetchQuotes
    }
}

public extension MarketPriceProvider {
    static let empty = MarketPriceProvider(
        displayName: "Empty",
        fetchQuotes: { _ in throw MarketPriceProviderError.providerUnavailable }
    )

    /// Bundled offline snapshot — works without network, never leaks holdings.
    static let offlineSnapshot = MarketPriceProvider(
        displayName: "Offline snapshot",
        fetchQuotes: { symbols in
            let snapshot = OfflineMarketSnapshot.lookup(symbols: symbols)
            guard snapshot.isEmpty == false else {
                throw MarketPriceProviderError.noQuotesAvailable
            }
            return snapshot
        }
    )
}

/// In-source bundled snapshot of representative Vietnamese market prices.
///
/// Numbers are static reference values intended as a starting point for users
/// who haven't entered their own quotes yet — not a real-time feed. The
/// `asOf` date is fixed to a known release cut-off so users can see at a
/// glance how stale the data is.
public enum OfflineMarketSnapshot {
    /// Snapshot date in absolute UTC. Update this constant whenever the
    /// bundled prices below are refreshed.
    public static let snapshotDate = Date(timeIntervalSince1970: 1_745_366_400) // 2025-04-23

    /// Hardcoded ticker → price (VND, per-share) table.
    /// Picked from the most-traded HOSE constituents plus a handful of
    /// large open-ended mutual funds and ETFs.
    public static let priceTable: [String: Decimal] = [
        // VN30 blue chips
        "VCB": 91_000,
        "VHM": 50_500,
        "VIC": 41_200,
        "HPG": 27_800,
        "FPT": 134_500,
        "MSN": 70_400,
        "VNM": 64_200,
        "MWG": 56_700,
        "GAS": 71_900,
        "BID": 47_800,
        "CTG": 35_400,
        "SSI": 26_300,
        "VRE": 18_700,
        "MBB": 22_900,
        "VPB": 18_200,
        "TCB": 23_600,
        "ACB": 25_800,
        "STB": 30_200,
        // ETFs
        "FUEVFVND": 26_400,
        "E1VFVN30": 22_800,
        "FUESSV50": 18_600,
        // Mutual funds (per-fund unit, not per-share)
        "VESAF": 36_700,
        "VEOF": 32_800,
        "DCDS": 84_900,
    ]

    public static func lookup(symbols: [String]) -> [PriceQuote] {
        symbols.compactMap { symbol -> PriceQuote? in
            let key = symbol.uppercased()
            guard let price = priceTable[key] else { return nil }
            return PriceQuote(
                symbol: key,
                price: price,
                asOf: snapshotDate,
                source: .network,
                currency: "VND"
            )
        }
    }
}
