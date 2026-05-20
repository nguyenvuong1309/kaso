import ComposableArchitecture
import Foundation
import MoneyTherapistDomain
import Testing
@testable import MoneyTherapistFeature

@MainActor
struct MoneyTherapistFeatureTests {
    @Test("task loads reflections")
    func taskLoadsReflections() async {
        let reflection = TherapistReflection(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000A001")!,
            topic: .guilt,
            note: "Just venting",
            recordedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let store = TestStore(initialState: MoneyTherapistFeature.State()) {
            MoneyTherapistFeature()
        } withDependencies: {
            $0.therapistRepository = TherapistRepository(
                fetchAll: { [reflection] },
                save: { _ in },
                delete: { _ in }
            )
        }

        await store.send(.task) {
            $0.isLoading = true
            $0.errorMessageKey = nil
        }
        await store.receive(\.reflectionsLoaded) {
            $0.isLoading = false
            $0.reflections = [reflection]
        }
    }

    @Test("selecting topic opens reflection sheet")
    func selectingTopicOpensSheet() async {
        let store = TestStore(initialState: MoneyTherapistFeature.State()) {
            MoneyTherapistFeature()
        }
        await store.send(.topicSelected(.stressTrigger)) {
            $0.activeTopic = .stressTrigger
            $0.noteText = ""
        }
        #expect(store.state.activePrompt?.topic == .stressTrigger)
    }

    @Test("saving reflection persists and resets sheet")
    func savingPersists() async {
        let saved = LockIsolated<[TherapistReflection]>([])
        let fixedID = UUID(uuidString: "00000000-0000-0000-0000-00000000B001")!
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

        let store = TestStore(
            initialState: MoneyTherapistFeature.State(
                activeTopic: .guilt,
                noteText: "felt rough"
            )
        ) {
            MoneyTherapistFeature()
        } withDependencies: {
            $0.therapistRepository = TherapistRepository(
                fetchAll: { saved.value },
                save: { reflection in saved.withValue { $0.append(reflection) } },
                delete: { _ in }
            )
            $0.date = .constant(fixedDate)
            $0.uuid = .constant(fixedID)
        }

        await store.send(.saveButtonTapped) {
            $0.activeTopic = nil
            $0.noteText = ""
        }

        let expected = TherapistReflection(
            id: fixedID,
            topic: .guilt,
            note: "felt rough",
            recordedAt: fixedDate
        )
        await store.receive(\.reflectionSaved) {
            $0.reflections = [expected]
        }
        #expect(saved.value == [expected])
    }
}
