import ComposableArchitecture
import Testing
@testable import WellnessFeature

@MainActor
@Test("section change updates selected section")
func sectionChangeUpdatesSelectedSection() async {
    let store = TestStore(initialState: WellnessFeature.State()) {
        WellnessFeature()
    }

    await store.send(.sectionChanged(.phantomExpense)) {
        $0.section = .phantomExpense
    }

    await store.send(.sectionChanged(.hoursOfLife)) {
        $0.section = .hoursOfLife
    }

    await store.send(.sectionChanged(.roundUp)) {
        $0.section = .roundUp
    }

    await store.send(.sectionChanged(.guiltFreeBudget)) {
        $0.section = .guiltFreeBudget
    }

    await store.send(.sectionChanged(.coolingOff)) {
        $0.section = .coolingOff
    }

    await store.send(.sectionChanged(.moodJournal)) {
        $0.section = .moodJournal
    }

    await store.send(.sectionChanged(.regretScore)) {
        $0.section = .regretScore
    }

    await store.send(.sectionChanged(.whatIf)) {
        $0.section = .whatIf
    }

    await store.send(.sectionChanged(.spendingCalendar)) {
        $0.section = .spendingCalendar
    }

    await store.send(.sectionChanged(.gamification)) {
        $0.section = .gamification
    }
}
