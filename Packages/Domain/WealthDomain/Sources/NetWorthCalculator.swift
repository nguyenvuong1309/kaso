import Foundation

public enum NetWorthCalculator {
    public static func snapshot(
        assets: [Asset],
        liabilities: [Liability],
        on date: Date = Date()
    ) -> NetWorthSnapshot {
        let totalAssets = assets.reduce(Decimal(0)) { total, asset in
            total + max(asset.currentValue, 0)
        }
        let totalLiabilities = liabilities.reduce(Decimal(0)) { total, liability in
            total + max(liability.principalRemaining, 0)
        }

        return NetWorthSnapshot(
            date: date,
            totalAssets: totalAssets,
            totalLiabilities: totalLiabilities
        )
    }

    public static func monthlyHistory(
        recordedSnapshots: [NetWorthSnapshot],
        through referenceDate: Date,
        monthCount: Int = 6,
        calendar: Calendar = .current
    ) -> [NetWorthSnapshot] {
        guard monthCount > 0 else {
            return []
        }

        let groupedByMonth = Dictionary(grouping: recordedSnapshots) { snapshot -> Date in
            calendar.dateInterval(of: .month, for: snapshot.date)?.start
                ?? snapshot.date
        }

        let monthBuckets = (0 ..< monthCount).reversed().compactMap { offset -> Date? in
            calendar.date(byAdding: .month, value: -offset, to: referenceDate).flatMap {
                calendar.dateInterval(of: .month, for: $0)?.start
            }
        }

        var lastSnapshot: NetWorthSnapshot?
        return monthBuckets.map { bucket -> NetWorthSnapshot in
            if let snapshotsInMonth = groupedByMonth[bucket],
               let latest = snapshotsInMonth.max(by: { $0.date < $1.date }) {
                lastSnapshot = latest
                return NetWorthSnapshot(
                    id: latest.id,
                    date: bucket,
                    totalAssets: latest.totalAssets,
                    totalLiabilities: latest.totalLiabilities
                )
            }

            return NetWorthSnapshot(
                date: bucket,
                totalAssets: lastSnapshot?.totalAssets ?? 0,
                totalLiabilities: lastSnapshot?.totalLiabilities ?? 0
            )
        }
    }
}
