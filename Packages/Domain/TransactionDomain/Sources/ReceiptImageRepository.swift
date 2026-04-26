import Foundation

public struct ReceiptImageRepository: Sendable {
    public var save: @Sendable (Data) async throws -> String

    public init(
        save: @escaping @Sendable (Data) async throws -> String
    ) {
        self.save = save
    }
}

public extension ReceiptImageRepository {
    static let empty = ReceiptImageRepository(
        save: { _ in "" }
    )
}
