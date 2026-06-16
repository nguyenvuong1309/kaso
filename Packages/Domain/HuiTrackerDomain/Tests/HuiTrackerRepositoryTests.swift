import Foundation
import Testing
@testable import HuiTrackerDomain

struct HuiTrackerRepositoryTests {
    @Test("empty repository fetches no groups")
    func emptyFetchReturnsNothing() async throws {
        let repository = HuiTrackerRepository.empty
        let groups = try await repository.fetchAll()
        #expect(groups.isEmpty)
    }

    @Test("empty repository save and delete are no-ops that do not throw")
    func emptySaveAndDeleteDoNotThrow() async throws {
        let repository = HuiTrackerRepository.empty
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000D1"))
        let group = HuiGroup(
            id: id,
            name: "G",
            organizerName: "O",
            contributionAmount: 1_000_000,
            periodKind: .monthly,
            memberCount: 1,
            startDate: Date(timeIntervalSince1970: 0)
        )
        try await repository.save(group)
        try await repository.delete(id)
    }

    @Test("custom closures are invoked through the repository facade")
    func customClosuresInvoked() async throws {
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000D2"))
        let stored = HuiGroup(
            id: id,
            name: "Stored",
            organizerName: "O",
            contributionAmount: 500_000,
            periodKind: .weekly,
            memberCount: 1,
            startDate: Date(timeIntervalSince1970: 0)
        )
        let recorder = Recorder()
        let repository = HuiTrackerRepository(
            fetchAll: { [stored] },
            save: { await recorder.recordSave($0) },
            delete: { await recorder.recordDelete($0) }
        )

        let fetched = try await repository.fetchAll()
        #expect(fetched == [stored])

        try await repository.save(stored)
        try await repository.delete(id)

        let savedNames = await recorder.savedNames
        let deletedIDs = await recorder.deletedIDs
        #expect(savedNames == ["Stored"])
        #expect(deletedIDs == [id])
    }

    @Test("repository propagates errors thrown by closures")
    func propagatesErrors() async {
        let repository = HuiTrackerRepository(
            fetchAll: { throw SampleError.boom },
            save: { _ in throw SampleError.boom },
            delete: { _ in throw SampleError.boom }
        )

        await #expect(throws: SampleError.self) {
            _ = try await repository.fetchAll()
        }
    }

    @Test("preview repository returns one seeded group with cycles")
    func previewSeedsGroup() async throws {
        let groups = try await HuiTrackerRepository.preview.fetchAll()
        let group = try #require(groups.first)
        #expect(groups.count == 1)
        #expect(group.memberCount == 6)
        #expect(group.cycles.count == 6)
        #expect(group.periodKind == .monthly)
        // Seeded: first cycle paid, second paid+received.
        #expect(group.cycles[0].isPaid)
        #expect(group.cycles[1].isPaid)
        #expect(group.cycles[1].isReceived)
        #expect(group.cycles[1].receivedAmount == 12_000_000)
    }

    private enum SampleError: Error {
        case boom
    }

    private actor Recorder {
        private(set) var savedNames: [String] = []
        private(set) var deletedIDs: [UUID] = []

        func recordSave(_ group: HuiGroup) {
            savedNames.append(group.name)
        }

        func recordDelete(_ id: UUID) {
            deletedIDs.append(id)
        }
    }
}
