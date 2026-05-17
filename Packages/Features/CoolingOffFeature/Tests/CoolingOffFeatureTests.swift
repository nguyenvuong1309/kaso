import ComposableArchitecture
import CoolingOffDomain
import Foundation
import Testing
@testable import CoolingOffFeature

@MainActor
@Test("loads plans and policy on task")
func loadsPlansAndPolicyOnTask() async throws {
    let referenceDate = try date(2026, 4, 26)
    let plan = PurchasePlan(
        title: "AirPods",
        amount: 6_000_000,
        coolingPeriod: .oneWeek,
        status: .waiting,
        createdAt: referenceDate,
        availableAt: referenceDate.addingTimeInterval(7 * 86_400)
    )
    let store = TestStore(initialState: CoolingOffFeature.State()) {
        CoolingOffFeature()
    } withDependencies: {
        $0.date.now = referenceDate
        $0.purchasePlanRepository.fetchAll = { [plan] }
        $0.purchasePlanRepository.loadPolicy = { .default }
    }

    await store.send(.task) {
        $0.referenceDate = referenceDate
        $0.isLoading = true
    }
    await store.receive(.dataLoaded(plans: [plan], policy: .default)) {
        $0.isLoading = false
        $0.plans = IdentifiedArray(uniqueElements: [plan])
        $0.policy = .default
    }
}

@MainActor
@Test("amount change autosuggests cooling period when not overridden")
func amountAutoSuggestsPeriod() async {
    let store = TestStore(
        initialState: CoolingOffFeature.State(
            policy: .default,
            isEditorPresented: true,
            coolingPeriod: .oneDay
        )
    ) {
        CoolingOffFeature()
    }

    await store.send(.amountTextChanged("6.000.000")) {
        $0.amountText = "6.000.000"
        $0.coolingPeriod = .oneWeek
    }
}

@MainActor
@Test("explicit cooling period change is preserved")
func explicitPeriodPreserved() async {
    let store = TestStore(
        initialState: CoolingOffFeature.State(
            policy: .default,
            isEditorPresented: true,
            amountText: "6.000.000",
            coolingPeriod: .oneDay
        )
    ) {
        CoolingOffFeature()
    }

    await store.send(.coolingPeriodChanged(.twoWeeks)) {
        $0.coolingPeriod = .twoWeeks
        $0.coolingPeriodOverride = true
    }
    await store.send(.amountTextChanged("500.000")) {
        $0.amountText = "500.000"
    }
}

@MainActor
@Test("saving a new plan validates and persists")
func savesNewPlan() async throws {
    let referenceDate = try date(2026, 4, 26)
    let planID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000010"))
    let saved = LockIsolated<[PurchasePlan]>([])
    let store = TestStore(
        initialState: CoolingOffFeature.State(
            policy: .default,
            isEditorPresented: true,
            titleText: "AirPods",
            amountText: "6.000.000",
            category: .electronics,
            coolingPeriod: .oneWeek
        )
    ) {
        CoolingOffFeature()
    } withDependencies: {
        $0.date.now = referenceDate
        $0.uuid = UUIDGenerator { planID }
        $0.purchasePlanRepository.save = { plan in
            saved.withValue { $0.append(plan) }
        }
    }

    let expected = PurchasePlan(
        id: planID,
        title: "AirPods",
        amount: 6_000_000,
        category: .electronics,
        coolingPeriod: .oneWeek,
        status: .waiting,
        createdAt: referenceDate,
        availableAt: referenceDate.addingTimeInterval(7 * 86_400)
    )

    await store.send(.saveButtonTapped) {
        $0.isEditorPresented = false
    }
    await store.receive(.planSaved(expected)) {
        $0.plans = IdentifiedArray(uniqueElements: [expected])
    }

    #expect(saved.value == [expected])
}

@MainActor
@Test("cancelling a waiting plan marks it cancelled and saves")
func cancellingWaitingPlan() async throws {
    let referenceDate = try date(2026, 4, 26)
    let plan = PurchasePlan(
        title: "Jacket",
        amount: 1_200_000,
        coolingPeriod: .threeDays,
        status: .waiting,
        createdAt: referenceDate.addingTimeInterval(-86_400),
        availableAt: referenceDate.addingTimeInterval(2 * 86_400)
    )
    let saved = LockIsolated<[PurchasePlan]>([])
    let store = TestStore(
        initialState: CoolingOffFeature.State(
            plans: IdentifiedArray(uniqueElements: [plan]),
            policy: .default
        )
    ) {
        CoolingOffFeature()
    } withDependencies: {
        $0.date.now = referenceDate
        $0.purchasePlanRepository.save = { plan in
            saved.withValue { $0.append(plan) }
        }
    }

    var expected = plan
    expected.status = .cancelled
    expected.decisionAt = referenceDate

    await store.send(.cancelTapped(plan.id)) {
        $0.plans[id: plan.id] = expected
    }
    await store.receive(.planSaved(expected))

    #expect(saved.value == [expected])
}

private func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
    let calendar = Calendar(identifier: .gregorian)
    return try #require(DateComponents(calendar: calendar, year: year, month: month, day: day).date)
}
