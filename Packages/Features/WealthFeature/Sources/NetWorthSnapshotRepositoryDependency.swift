import Foundation
import ComposableArchitecture
import WealthDomain

private enum NetWorthSnapshotRepositoryKey: DependencyKey {
    static let liveValue = NetWorthSnapshotRepository.empty
    static let previewValue = NetWorthSnapshotRepository.preview
    static let testValue = NetWorthSnapshotRepository.empty
}

public extension NetWorthSnapshotRepository {
    static let preview = NetWorthSnapshotRepository(
        fetchAll: {
            [
                NetWorthSnapshot(
                    date: Date().addingTimeInterval(-60 * 60 * 24 * 60),
                    totalAssets: 42_000_000,
                    totalLiabilities: 3_000_000
                ),
                NetWorthSnapshot(
                    date: Date().addingTimeInterval(-60 * 60 * 24 * 30),
                    totalAssets: 50_000_000,
                    totalLiabilities: 2_500_000
                ),
            ]
        },
        save: { _ in },
        prune: { _ in }
    )
}

public extension DependencyValues {
    var netWorthSnapshotRepository: NetWorthSnapshotRepository {
        get { self[NetWorthSnapshotRepositoryKey.self] }
        set { self[NetWorthSnapshotRepositoryKey.self] = newValue }
    }
}
