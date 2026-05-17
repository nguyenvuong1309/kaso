import ComposableArchitecture
import Foundation
import RoundUpDomain

private enum RoundUpRepositoryKey: DependencyKey {
    static let liveValue = RoundUpRepository.empty
    static let previewValue = RoundUpRepository.preview
    static let testValue = RoundUpRepository.empty
}

public extension RoundUpRepository {
    static let preview = RoundUpRepository(
        loadRule: {
            RoundUpRule(isEnabled: true, step: .tenThousand)
        },
        saveRule: { _ in },
        fetchEntries: {
            [
                RoundUpEntry(
                    originalAmount: 85_000,
                    roundedAmount: 90_000,
                    contribution: 5_000,
                    step: .tenThousand,
                    createdAt: .now
                ),
                RoundUpEntry(
                    originalAmount: 32_500,
                    roundedAmount: 35_000,
                    contribution: 2_500,
                    step: .fiveThousand,
                    createdAt: .now.addingTimeInterval(-3600 * 24)
                ),
            ]
        },
        saveEntry: { _ in },
        deleteEntry: { _ in },
        clearAll: {}
    )
}

public extension DependencyValues {
    var roundUpRepository: RoundUpRepository {
        get { self[RoundUpRepositoryKey.self] }
        set { self[RoundUpRepositoryKey.self] = newValue }
    }
}
