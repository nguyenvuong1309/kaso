import ComposableArchitecture
import Foundation
import HuiTrackerDomain
import Testing
@testable import HuiTrackerFeature

@MainActor
struct HuiTrackerFeatureTests {
    private func makeGroup() -> HuiGroup {
        HuiGroup(
            name: "Hụi tháng",
            organizerName: "Cô Bảy",
            contributionAmount: 2_000_000,
            periodKind: .monthly,
            memberCount: 3,
            startDate: Date(timeIntervalSince1970: 0),
            cycles: HuiCycleScheduleBuilder.build(
                memberCount: 3,
                startDate: Date(timeIntervalSince1970: 0),
                periodKind: .monthly
            )
        )
    }

    @Test("task loads groups and builds overall summary")
    func taskLoadsGroups() async {
        let group = makeGroup()
        let store = TestStore(initialState: HuiTrackerFeature.State()) {
            HuiTrackerFeature()
        } withDependencies: {
            $0.huiTrackerRepository = HuiTrackerRepository(
                fetchAll: { [group] },
                save: { _ in },
                delete: { _ in }
            )
            $0.date.now = Date()
        }

        await store.send(.task) {
            $0.isLoading = true
        }
        await store.receive(.groupsLoaded([group])) {
            $0.isLoading = false
            $0.groups = IdentifiedArray(uniqueElements: [group])
            $0.overallSummary = HuiSummaryBuilder.overall(from: [group])
        }
    }

    @Test("addButtonTapped opens editor with blank draft")
    func addButtonOpensEditor() async {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let store = TestStore(initialState: HuiTrackerFeature.State()) {
            HuiTrackerFeature()
        } withDependencies: {
            $0.huiTrackerRepository = .empty
            $0.date.now = now
        }

        await store.send(.addButtonTapped) {
            $0.isEditorPresented = true
            $0.draftName = ""
            $0.draftPeriodKind = .monthly
            $0.draftStartDate = now
        }
    }

    @Test("saveButtonTapped validates name")
    func saveValidatesName() async {
        let store = TestStore(initialState: HuiTrackerFeature.State(isEditorPresented: true)) {
            HuiTrackerFeature()
        } withDependencies: {
            $0.huiTrackerRepository = .empty
            $0.date.now = Date()
        }

        await store.send(.saveButtonTapped) {
            $0.editorErrorMessageKey = "hui.error.nameRequired"
        }
    }

    @Test("cyclePaidToggled marks cycle paid and persists")
    func cyclePaidToggled() async {
        let group = makeGroup()
        let cycleID = group.cycles[0].id
        let store = TestStore(
            initialState: HuiTrackerFeature.State(
                groups: IdentifiedArray(uniqueElements: [group])
            )
        ) {
            HuiTrackerFeature()
        } withDependencies: {
            $0.huiTrackerRepository = .empty
            $0.date.now = Date()
        }

        await store.send(.cyclePaidToggled(groupID: group.id, cycleID: cycleID)) {
            $0.groups[id: group.id]?.cycles[0].isPaid = true
        }
        await store.receive(\.cyclePersisted) {
            $0.overallSummary = HuiSummaryBuilder.overall(from: Array($0.groups))
        }
    }

    @Test("deleteButtonTapped removes group")
    func deleteRemovesGroup() async {
        let group = makeGroup()
        let store = TestStore(
            initialState: HuiTrackerFeature.State(
                groups: IdentifiedArray(uniqueElements: [group])
            )
        ) {
            HuiTrackerFeature()
        } withDependencies: {
            $0.huiTrackerRepository = .empty
            $0.date.now = Date()
        }

        await store.send(.deleteButtonTapped(group.id))
        await store.receive(.groupDeleted(group.id)) {
            $0.groups = []
            $0.overallSummary = HuiSummaryBuilder.overall(from: [])
        }
    }
}
