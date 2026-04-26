import ComposableArchitecture
import WealthDomain

private enum LiabilityRepositoryKey: DependencyKey {
    static let liveValue = LiabilityRepository.empty
    static let previewValue = LiabilityRepository.preview
    static let testValue = LiabilityRepository.empty
}

public extension LiabilityRepository {
    static let preview = LiabilityRepository(
        fetchAll: {
            [
                Liability(
                    name: "Thẻ tín dụng",
                    type: .creditCard,
                    principalRemaining: 2_000_000
                ),
            ]
        },
        save: { _ in },
        delete: { _ in }
    )
}

public extension DependencyValues {
    var liabilityRepository: LiabilityRepository {
        get { self[LiabilityRepositoryKey.self] }
        set { self[LiabilityRepositoryKey.self] = newValue }
    }
}
