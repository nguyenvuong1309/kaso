import Foundation
import FreelancerDomain
import Testing
@testable import PersistenceKit

@Test("encrypted freelancer profile store round trips profile")
func encryptedFreelancerProfileStoreRoundTripsProfile() async throws {
    let fileURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("kasoenc")
    let keyData = Data(repeating: 1, count: 32)
    let store = EncryptedFreelancerProfileStore(
        fileURL: fileURL,
        keyDataProvider: { keyData }
    )
    let profile = FreelancerProfile(
        monthlyIncomes: [
            MonthlyIncome(month: YearMonth(year: 2026, month: 4), grossAmount: 24_000_000),
        ],
        bufferBalance: 12_000_000,
        bufferTargetMultiplier: 2,
        workType: .freelancer
    )

    try await store.save(profile)
    let loaded = try await store.load()

    #expect(loaded == profile)
    #expect(try Data(contentsOf: fileURL).isEmpty == false)
}
