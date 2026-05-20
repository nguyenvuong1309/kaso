import BillSplitterDomain
import ComposableArchitecture
import Foundation
import Testing
@testable import BillSplitterFeature

@MainActor
struct BillSplitterFeatureTests {
    @Test("adding a participant assigns them as default payer when none")
    func firstParticipantBecomesPayer() async {
        let store = TestStore(initialState: BillSplitterFeature.State()) {
            BillSplitterFeature()
        } withDependencies: {
            $0.uuid = .incrementing
        }

        await store.send(.newParticipantNameChanged("Alice")) {
            $0.newParticipantName = "Alice"
        }
        await store.send(.addParticipantTapped) {
            let id = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
            $0.split.participants = [BillParticipant(id: id, name: "Alice")]
            $0.split.payerID = id
            $0.newParticipantName = ""
        }
    }

    @Test("adding invalid amount surfaces error")
    func invalidAmountError() async {
        let store = TestStore(initialState: BillSplitterFeature.State()) {
            BillSplitterFeature()
        }

        await store.send(.newItemLabelChanged("Phở")) { $0.newItemLabel = "Phở" }
        await store.send(.newItemAmountChanged("abc")) { $0.newItemAmountText = "abc" }
        await store.send(.addItemTapped) {
            $0.errorMessageKey = "billSplitter.error.invalidAmount"
        }
    }
}
