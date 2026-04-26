import Foundation
import PersistenceKit
import Testing

@Test("saves receipt image data encrypted")
func savesReceiptImageDataEncrypted() async throws {
    let directoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    let imageData = Data([1, 2, 3, 4, 5])
    let identifier = "receipt-1"
    let store = EncryptedReceiptImageStore(
        directoryURL: directoryURL,
        keyDataProvider: { Data(repeating: 11, count: 32) },
        identifierProvider: { identifier }
    )

    let savedIdentifier = try await store.save(imageData)
    let rawData = try Data(
        contentsOf: directoryURL.appendingPathComponent("\(identifier).kasoenc")
    )

    #expect(savedIdentifier == identifier)
    #expect(rawData != imageData)
}
