import ComposableArchitecture
import Foundation
import TransactionDomain

private enum ReceiptImageRepositoryKey: DependencyKey {
    static let liveValue = ReceiptImageRepository.empty
    static let previewValue = ReceiptImageRepository.preview
    static let testValue = ReceiptImageRepository.empty
}

public extension ReceiptImageRepository {
    static let preview = ReceiptImageRepository(
        save: { _ in "preview-receipt" }
    )
}

public extension DependencyValues {
    var receiptImageRepository: ReceiptImageRepository {
        get { self[ReceiptImageRepositoryKey.self] }
        set { self[ReceiptImageRepositoryKey.self] = newValue }
    }
}
