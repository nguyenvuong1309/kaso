import Foundation

public enum SpendingMapBuilder {
    /// Approximate cluster radius in degrees. ~0.003° latitude is roughly 330 m,
    /// which keeps neighbourhood-scale hotspots together without merging
    /// districts. Longitude clustering uses the same delta — at Vietnam latitudes
    /// (~10–22°N) this is between ~280 m and ~330 m.
    public static let clusterRadiusDegrees: Double = 0.003

    public static func build(
        entries: [SpendingMapEntry],
        period: SpendingMapPeriod,
        referenceDate: Date,
        calendar: Calendar = .current
    ) -> SpendingMapSummary {
        let cutoff = period.startDate(referenceDate: referenceDate, calendar: calendar)
        let filtered = entries.filter { entry in
            guard let cutoff else { return true }
            return entry.occurredAt >= cutoff
        }

        guard filtered.isEmpty == false else {
            return SpendingMapSummary(
                hotspots: [],
                totalAmount: 0,
                entryCount: 0,
                period: period,
                generatedAt: referenceDate
            )
        }

        var buckets: [[SpendingMapEntry]] = []
        for entry in filtered {
            if let index = buckets.firstIndex(where: { bucket in
                guard let representative = bucket.first else { return false }
                let dLat = abs(representative.latitude - entry.latitude)
                let dLng = abs(representative.longitude - entry.longitude)
                return dLat <= clusterRadiusDegrees && dLng <= clusterRadiusDegrees
            }) {
                buckets[index].append(entry)
            } else {
                buckets.append([entry])
            }
        }

        let totalAmount = filtered.reduce(Decimal(0)) { $0 + $1.amount }
        let maxBucketTotal = buckets
            .map { $0.reduce(Decimal(0)) { acc, entry in acc + entry.amount } }
            .max() ?? 0
        let maxBucketDouble = NSDecimalNumber(decimal: maxBucketTotal).doubleValue

        let hotspots: [SpendingMapHotspot] = buckets
            .map { bucket -> SpendingMapHotspot in
                let bucketTotal = bucket.reduce(Decimal(0)) { $0 + $1.amount }
                let centroid = centroidOf(bucket)
                let topCategoryID = topCategoryID(in: bucket)
                let intensity: Double
                if maxBucketDouble > 0 {
                    let bucketDouble = NSDecimalNumber(decimal: bucketTotal).doubleValue
                    intensity = max(0.0, min(1.0, bucketDouble / maxBucketDouble))
                } else {
                    intensity = 0
                }
                return SpendingMapHotspot(
                    latitude: centroid.latitude,
                    longitude: centroid.longitude,
                    totalAmount: bucketTotal,
                    entryCount: bucket.count,
                    topCategoryID: topCategoryID,
                    entries: bucket.sorted { $0.occurredAt > $1.occurredAt },
                    intensity: intensity
                )
            }
            .sorted { $0.totalAmount > $1.totalAmount }

        return SpendingMapSummary(
            hotspots: hotspots,
            totalAmount: totalAmount,
            entryCount: filtered.count,
            period: period,
            generatedAt: referenceDate
        )
    }

    private static func centroidOf(_ entries: [SpendingMapEntry]) -> (latitude: Double, longitude: Double) {
        guard entries.isEmpty == false else { return (0, 0) }
        let lat = entries.reduce(0.0) { $0 + $1.latitude } / Double(entries.count)
        let lng = entries.reduce(0.0) { $0 + $1.longitude } / Double(entries.count)
        return (lat, lng)
    }

    private static func topCategoryID(in entries: [SpendingMapEntry]) -> String? {
        var totals: [String: Decimal] = [:]
        for entry in entries {
            guard let category = entry.categoryID else { continue }
            totals[category, default: 0] += entry.amount
        }
        return totals.max(by: { $0.value < $1.value })?.key
    }
}
