import ComposableArchitecture
import Foundation
import GiftTrackerDomain
import Testing
@testable import GiftTrackerFeature

@MainActor
struct GiftTrackerFeatureTests {
    @Test("task loads records and builds summaries")
    func taskLoadsRecords() async {
        let record = GiftRecord(
            personName: "Hùng",
            eventKind: .wedding,
            direction: .given,
            amount: 1_000_000,
            eventDate: Date()
        )

        let store = TestStore(initialState: GiftTrackerFeature.State()) {
            GiftTrackerFeature()
        } withDependencies: {
            $0.giftTrackerRepository = GiftTrackerRepository(
                fetchAll: { [record] },
                save: { _ in },
                delete: { _ in }
            )
            $0.date.now = Date()
        }

        await store.send(.task) {
            $0.isLoading = true
        }
        await store.receive(.recordsLoaded([record])) {
            $0.isLoading = false
            $0.records = IdentifiedArray(uniqueElements: [record])
            $0.personSummaries = GiftPersonSummaryBuilder.build(from: [record])
            $0.yearlySummary = GiftYearlySummaryBuilder.build(from: [record])
        }
    }

    @Test("addButtonTapped opens editor with blank draft")
    func addButtonTappedOpenEditor() async {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let store = TestStore(initialState: GiftTrackerFeature.State()) {
            GiftTrackerFeature()
        } withDependencies: {
            $0.giftTrackerRepository = .empty
            $0.date.now = now
        }

        await store.send(.addButtonTapped) {
            $0.isEditorPresented = true
            $0.editingRecord = nil
            $0.draftPersonName = ""
            $0.draftEventKind = .tet
            $0.draftDirection = .given
            $0.draftAmountText = ""
            $0.draftEventDate = now
            $0.draftNote = ""
            $0.editorErrorMessageKey = nil
        }
    }

    @Test("saveButtonTapped fails validation when name is empty")
    func saveWithEmptyNameShowsError() async {
        let store = TestStore(initialState: GiftTrackerFeature.State(isEditorPresented: true)) {
            GiftTrackerFeature()
        } withDependencies: {
            $0.giftTrackerRepository = .empty
            $0.date.now = Date()
        }

        await store.send(.saveButtonTapped) {
            $0.editorErrorMessageKey = "gift.error.nameRequired"
        }
    }

    @Test("saveButtonTapped fails validation when amount is invalid")
    func saveWithInvalidAmountShowsError() async {
        var initial = GiftTrackerFeature.State(isEditorPresented: true)
        initial.draftPersonName = "Hùng"
        initial.draftAmountText = "abc"

        let store = TestStore(initialState: initial) {
            GiftTrackerFeature()
        } withDependencies: {
            $0.giftTrackerRepository = .empty
            $0.date.now = Date()
        }

        await store.send(.saveButtonTapped) {
            $0.editorErrorMessageKey = "gift.error.invalidAmount"
        }
    }

    @Test("deleteButtonTapped removes record")
    func deleteRecord() async {
        let record = GiftRecord(
            personName: "Mai",
            eventKind: .tet,
            direction: .received,
            amount: 200_000,
            eventDate: Date()
        )

        let store = TestStore(
            initialState: GiftTrackerFeature.State(
                records: IdentifiedArray(uniqueElements: [record])
            )
        ) {
            GiftTrackerFeature()
        } withDependencies: {
            $0.giftTrackerRepository = GiftTrackerRepository(
                fetchAll: { [] },
                save: { _ in },
                delete: { _ in }
            )
            $0.date.now = Date()
        }

        await store.send(.deleteButtonTapped(record.id))
        await store.receive(.recordDeleted(record.id)) {
            $0.records = []
            $0.personSummaries = []
            $0.yearlySummary = GiftYearlySummaryBuilder.build(from: [])
        }
    }
}
