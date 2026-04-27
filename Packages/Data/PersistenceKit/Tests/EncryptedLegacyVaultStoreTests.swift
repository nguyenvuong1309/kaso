import Foundation
import LegacyDomain
import Testing
@testable import PersistenceKit

@Test("encrypted legacy vault store round trips vault")
func encryptedLegacyVaultStoreRoundTripsVault() async throws {
    let fileURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("kasoenc")
    let keyData = Data(repeating: 2, count: 32)
    let store = EncryptedLegacyVaultStore(
        fileURL: fileURL,
        keyDataProvider: { keyData }
    )

    try await store.save(.preview)
    let loaded = try await store.load()

    #expect(loaded == LegacyVault.preview)
    #expect(try Data(contentsOf: fileURL).isEmpty == false)
}
