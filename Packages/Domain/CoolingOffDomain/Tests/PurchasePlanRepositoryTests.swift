import Foundation
import Testing
@testable import CoolingOffDomain

@Test("repository empty fetchAll returns no plans")
func repositoryEmptyFetchAll() async throws {
    let plans = try await PurchasePlanRepository.empty.fetchAll()
    #expect(plans.isEmpty)
}

@Test("repository empty save is a no-op")
func repositoryEmptySave() async throws {
    let plan = PurchasePlan(title: "X", amount: 1, availableAt: Date(timeIntervalSince1970: 0))
    try await PurchasePlanRepository.empty.save(plan)
}

@Test("repository empty delete is a no-op")
func repositoryEmptyDelete() async throws {
    let id = try #require(UUID(uuidString: "66666666-6666-6666-6666-666666666666"))
    try await PurchasePlanRepository.empty.delete(id)
}

@Test("repository empty loadPolicy returns the default policy")
func repositoryEmptyLoadPolicy() async throws {
    let policy = try await PurchasePlanRepository.empty.loadPolicy()
    #expect(policy == .default)
}

@Test("repository empty savePolicy is a no-op")
func repositoryEmptySavePolicy() async throws {
    try await PurchasePlanRepository.empty.savePolicy(.default)
}

@Test("repository closures are wired to the provided implementations")
func repositoryCustomClosures() async throws {
    let id = try #require(UUID(uuidString: "77777777-7777-7777-7777-777777777777"))
    let sample = PurchasePlan(
        id: id,
        title: "Sample",
        amount: 1_000_000,
        availableAt: Date(timeIntervalSince1970: 100)
    )
    let store = PlanStore()
    let repository = PurchasePlanRepository(
        fetchAll: { await store.all() },
        save: { await store.add($0) },
        delete: { await store.remove($0) },
        loadPolicy: { CoolingOffPolicy(thresholds: [], defaultPeriod: .twoWeeks) },
        savePolicy: { await store.setPolicy($0) }
    )

    try await repository.save(sample)
    let afterSave = try await repository.fetchAll()
    #expect(afterSave.map(\.id) == [id])

    let policy = try await repository.loadPolicy()
    #expect(policy.defaultPeriod == .twoWeeks)

    try await repository.savePolicy(.default)
    let savedPolicy = await store.savedPolicy
    #expect(savedPolicy == .default)

    try await repository.delete(id)
    let afterDelete = try await repository.fetchAll()
    #expect(afterDelete.isEmpty)
}

private actor PlanStore {
    private var plans: [PurchasePlan] = []
    private(set) var savedPolicy: CoolingOffPolicy?

    func all() -> [PurchasePlan] { plans }
    func add(_ plan: PurchasePlan) { plans.append(plan) }
    func remove(_ id: UUID) { plans.removeAll { $0.id == id } }
    func setPolicy(_ policy: CoolingOffPolicy) { savedPolicy = policy }
}
