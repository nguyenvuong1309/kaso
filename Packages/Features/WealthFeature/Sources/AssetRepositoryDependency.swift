import ComposableArchitecture
import WealthDomain

private enum AssetRepositoryKey: DependencyKey {
    static let liveValue = AssetRepository.empty
    static let previewValue = AssetRepository.preview
    static let testValue = AssetRepository.empty
}

public extension AssetRepository {
    static let preview = AssetRepository(
        fetchAll: {
            [
                Asset(
                    name: "Tiết kiệm",
                    type: .bankSavings,
                    currentValue: 50_000_000
                ),
                Asset(
                    name: "Tiền mặt",
                    type: .cash,
                    currentValue: 5_000_000
                ),
            ]
        },
        save: { _ in },
        delete: { _ in }
    )
}

public extension DependencyValues {
    var assetRepository: AssetRepository {
        get { self[AssetRepositoryKey.self] }
        set { self[AssetRepositoryKey.self] = newValue }
    }
}
