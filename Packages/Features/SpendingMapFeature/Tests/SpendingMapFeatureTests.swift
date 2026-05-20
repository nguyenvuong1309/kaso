import ComposableArchitecture
import Foundation
import SpendingMapDomain
import Testing
@testable import SpendingMapFeature

@MainActor
struct SpendingMapFeatureTests {
    private let reference = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("task loads entries and refreshes summary")
    func taskLoadsEntriesAndRefreshesSummary() async {
        let entry = SpendingMapEntry(
            label: "Bún bò",
            amount: 50_000,
            latitude: 10.77,
            longitude: 106.69,
            occurredAt: reference.addingTimeInterval(-60 * 60 * 24)
        )
        let store = TestStore(initialState: SpendingMapFeature.State()) {
            SpendingMapFeature()
        } withDependencies: {
            $0.spendingMapRepository = SpendingMapRepository(
                fetchAll: { [entry] },
                save: { _ in },
                delete: { _ in }
            )
            $0.date.now = reference
            $0.uuid = UUIDGenerator.incrementing
        }

        await store.send(.task) {
            $0.isLoading = true
            $0.errorMessageKey = nil
        }
        await store.receive(.entriesLoaded([entry])) {
            $0.isLoading = false
            $0.entries = IdentifiedArray(uniqueElements: [entry])
            $0.summary = SpendingMapBuilder.build(
                entries: [entry],
                period: .last30Days,
                referenceDate: reference
            )
        }
    }

    @Test("addButtonTapped resets draft and opens editor")
    func addButtonOpensEditor() async {
        let store = TestStore(initialState: SpendingMapFeature.State()) {
            SpendingMapFeature()
        } withDependencies: {
            $0.spendingMapRepository = .empty
            $0.date.now = reference
            $0.uuid = UUIDGenerator.incrementing
        }

        await store.send(.addButtonTapped) {
            $0.isEditorPresented = true
            $0.editingEntry = nil
            $0.draftLabel = ""
            $0.draftAmountText = ""
            $0.draftCategoryID = ""
            $0.draftLatitude = SpendingMapFeature.defaultLatitude
            $0.draftLongitude = SpendingMapFeature.defaultLongitude
            $0.draftOccurredAt = reference
            $0.draftNote = ""
            $0.editorErrorMessageKey = nil
        }
    }

    @Test("saveButtonTapped requires label")
    func saveRequiresLabel() async {
        let store = TestStore(initialState: SpendingMapFeature.State(isEditorPresented: true)) {
            SpendingMapFeature()
        } withDependencies: {
            $0.spendingMapRepository = .empty
            $0.date.now = reference
            $0.uuid = UUIDGenerator.incrementing
        }

        await store.send(.saveButtonTapped) {
            $0.editorErrorMessageKey = "spendingMap.error.labelRequired"
        }
    }

    @Test("saveButtonTapped requires positive amount")
    func saveRequiresAmount() async {
        var initial = SpendingMapFeature.State(isEditorPresented: true)
        initial.draftLabel = "Cà phê"
        let store = TestStore(initialState: initial) {
            SpendingMapFeature()
        } withDependencies: {
            $0.spendingMapRepository = .empty
            $0.date.now = reference
            $0.uuid = UUIDGenerator.incrementing
        }

        await store.send(.saveButtonTapped) {
            $0.editorErrorMessageKey = "spendingMap.error.invalidAmount"
        }
    }

    @Test("periodChanged refreshes the summary")
    func periodChangedRefreshesSummary() async {
        let recent = SpendingMapEntry(
            label: "Cà phê",
            amount: 100_000,
            latitude: 10.77,
            longitude: 106.69,
            occurredAt: reference.addingTimeInterval(-60 * 60 * 24)
        )
        let older = SpendingMapEntry(
            label: "Khách sạn Đà Lạt",
            amount: 1_500_000,
            latitude: 11.94,
            longitude: 108.45,
            occurredAt: reference.addingTimeInterval(-60 * 60 * 24 * 60)
        )
        var initial = SpendingMapFeature.State()
        initial.entries = IdentifiedArray(uniqueElements: [recent, older])

        let store = TestStore(initialState: initial) {
            SpendingMapFeature()
        } withDependencies: {
            $0.spendingMapRepository = .empty
            $0.date.now = reference
            $0.uuid = UUIDGenerator.incrementing
        }

        await store.send(.periodChanged(.allTime)) {
            $0.period = .allTime
            $0.summary = SpendingMapBuilder.build(
                entries: [recent, older],
                period: .allTime,
                referenceDate: reference
            )
        }
    }
}
