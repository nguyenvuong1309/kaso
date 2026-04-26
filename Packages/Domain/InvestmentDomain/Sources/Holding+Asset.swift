import Foundation
import WealthDomain

public extension PortfolioMetrics {
    func toAggregatedAsset(
        id: UUID,
        name: String,
        lastUpdatedAt: Date = Date()
    ) -> Asset {
        Asset(
            id: id,
            name: name,
            type: .investment,
            currentValue: max(marketValue, 0),
            note: nil,
            isAutoTracked: true,
            lastUpdatedAt: lastUpdatedAt
        )
    }
}
