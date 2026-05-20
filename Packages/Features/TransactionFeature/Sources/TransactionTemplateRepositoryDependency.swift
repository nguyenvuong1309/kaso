import ComposableArchitecture
import Foundation
import TransactionDomain

private enum TransactionTemplateRepositoryKey: DependencyKey {
    static let liveValue = TransactionTemplateRepository.empty
    static let previewValue = TransactionTemplateRepository.preview
    static let testValue = TransactionTemplateRepository.empty
}

public extension DependencyValues {
    var transactionTemplateRepository: TransactionTemplateRepository {
        get { self[TransactionTemplateRepositoryKey.self] }
        set { self[TransactionTemplateRepositoryKey.self] = newValue }
    }
}
