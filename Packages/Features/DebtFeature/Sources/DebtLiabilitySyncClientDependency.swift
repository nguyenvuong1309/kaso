import ComposableArchitecture
import WealthDomain

public struct DebtLiabilitySyncClient: Sendable {
    public var replaceAutoTracked: @Sendable ([Liability]) async throws -> Void

    public init(
        replaceAutoTracked: @escaping @Sendable ([Liability]) async throws -> Void
    ) {
        self.replaceAutoTracked = replaceAutoTracked
    }
}

public extension DebtLiabilitySyncClient {
    static let empty = DebtLiabilitySyncClient(
        replaceAutoTracked: { _ in }
    )
}

private enum DebtLiabilitySyncClientKey: DependencyKey {
    static let liveValue = DebtLiabilitySyncClient.empty
    static let previewValue = DebtLiabilitySyncClient.empty
    static let testValue = DebtLiabilitySyncClient.empty
}

public extension DependencyValues {
    var debtLiabilitySyncClient: DebtLiabilitySyncClient {
        get { self[DebtLiabilitySyncClientKey.self] }
        set { self[DebtLiabilitySyncClientKey.self] = newValue }
    }
}
