import ComposableArchitecture
import Foundation
import RoundUpDomain
import Testing
@testable import RoundUpFeature

@MainActor
@Test("loads rule and entries on task")
func loadsRuleAndEntriesOnTask() async throws {
    let referenceDate = try date(2026, 4, 26)
    let entry = RoundUpEntry(
        originalAmount: 85_000,
        roundedAmount: 90_000,
        contribution: 5_000,
        step: .tenThousand,
        createdAt: referenceDate
    )
    let store = TestStore(initialState: RoundUpFeature.State()) {
        RoundUpFeature()
    } withDependencies: {
        $0.date.now = referenceDate
        $0.roundUpRepository.loadRule = { RoundUpRule(isEnabled: true, step: .tenThousand) }
        $0.roundUpRepository.fetchEntries = { [entry] }
    }

    await store.send(.task) {
        $0.referenceDate = referenceDate
        $0.isLoading = true
    }
    await store.receive(
        .dataLoaded(
            rule: RoundUpRule(isEnabled: true, step: .tenThousand),
            entries: [entry]
        )
    ) {
        $0.isLoading = false
        $0.rule = RoundUpRule(isEnabled: true, step: .tenThousand)
        $0.entries = IdentifiedArray(uniqueElements: [entry])
    }
}

@MainActor
@Test("toggling enabled saves the new rule")
func togglingEnabledSavesRule() async {
    let saved = LockIsolated<[RoundUpRule]>([])
    let store = TestStore(
        initialState: RoundUpFeature.State(rule: RoundUpRule(isEnabled: false, step: .tenThousand))
    ) {
        RoundUpFeature()
    } withDependencies: {
        $0.roundUpRepository.saveRule = { rule in
            saved.withValue { $0.append(rule) }
        }
    }

    await store.send(.toggleEnabled(true)) {
        $0.rule.isEnabled = true
        $0.isSavingRule = true
    }
    await store.receive(.ruleSaved(RoundUpRule(isEnabled: true, step: .tenThousand))) {
        $0.isSavingRule = false
    }

    #expect(saved.value == [RoundUpRule(isEnabled: true, step: .tenThousand)])
}

@MainActor
@Test("simulator amount changes recompute contribution")
func simulatorAmountChangesRecomputeContribution() async {
    let store = TestStore(
        initialState: RoundUpFeature.State(rule: RoundUpRule(isEnabled: true, step: .tenThousand))
    ) {
        RoundUpFeature()
    }

    await store.send(.simulatorAmountChanged("85.000")) {
        $0.simulatorAmountText = "85.000"
        $0.simulatorContribution = 5_000
    }
    await store.send(.simulatorAmountChanged("100.000")) {
        $0.simulatorAmountText = "100.000"
        $0.simulatorContribution = 10_000
    }
}

@MainActor
@Test("submitting manual entry persists and prepends to history")
func submitsManualEntry() async throws {
    let referenceDate = try date(2026, 4, 26)
    let entryID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
    let expected = RoundUpEntry(
        id: entryID,
        originalAmount: 85_000,
        roundedAmount: 90_000,
        contribution: 5_000,
        step: .tenThousand,
        note: "Phở",
        createdAt: referenceDate
    )
    let saved = LockIsolated<[RoundUpEntry]>([])
    let store = TestStore(
        initialState: RoundUpFeature.State(
            rule: RoundUpRule(isEnabled: true, step: .tenThousand),
            manualEntryAmountText: "85.000",
            manualEntryNoteText: "Phở",
            isManualEntryPresented: true
        )
    ) {
        RoundUpFeature()
    } withDependencies: {
        $0.date.now = referenceDate
        $0.uuid = UUIDGenerator { entryID }
        $0.roundUpRepository.saveEntry = { entry in
            saved.withValue { $0.append(entry) }
        }
    }

    await store.send(.manualEntrySubmitted) {
        $0.isManualEntryPresented = false
    }
    await store.receive(.entryRecorded(expected)) {
        $0.entries = IdentifiedArray(uniqueElements: [expected])
    }

    #expect(saved.value == [expected])
}

@MainActor
@Test("invalid manual amount surfaces error key")
func invalidManualAmountSurfacesError() async {
    let store = TestStore(
        initialState: RoundUpFeature.State(
            rule: RoundUpRule(isEnabled: true, step: .tenThousand),
            manualEntryAmountText: "abc",
            isManualEntryPresented: true
        )
    ) {
        RoundUpFeature()
    }

    await store.send(.manualEntrySubmitted) {
        $0.errorMessageKey = "roundUp.error.invalidAmount"
    }
}

private func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
    let calendar = Calendar(identifier: .gregorian)
    return try #require(DateComponents(calendar: calendar, year: year, month: month, day: day).date)
}
