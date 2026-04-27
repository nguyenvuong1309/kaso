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
}
