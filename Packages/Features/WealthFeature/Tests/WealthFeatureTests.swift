import Foundation
import Testing
import ComposableArchitecture
import WealthDomain
@testable import WealthFeature

@MainActor
@Test("loads wealth data and records current snapshot")
func loadsWealthDataAndRecordsCurrentSnapshot() async throws {
    let referenceDate = try date(2026, 4, 26)
    let asset = Asset(
        name: "Tiết kiệm",
        type: .bankSavings,
        currentValue: 50_000_000,
        lastUpdatedAt: referenceDate
    )
    let liability = Liability(
        name: "Vay mua nhà",
        type: .mortgage,
        principalRemaining: 20_000_000,
        lastUpdatedAt: referenceDate
    )
    let snapshotID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000001001"))
    let snapshotRecorder = SnapshotRecorder()
    let store = TestStore(initialState: WealthFeature.State()) {
        WealthFeature()
    } withDependencies: {
        $0.date.now = referenceDate
        $0.uuid = .constant(snapshotID)
        $0.assetRepository.fetchAll = { [asset] }
        $0.liabilityRepository.fetchAll = { [liability] }
        $0.netWorthSnapshotRepository.fetchAll = { [] }
        $0.netWorthSnapshotRepository.save = { await snapshotRecorder.save($0) }
    }

    await store.send(.task) {
        $0.referenceDate = referenceDate
        $0.isLoading = true
    }
    await store.receive(.wealthDataLoaded([asset], [liability], [])) {
        $0.isLoading = false
        $0.assets = IdentifiedArray(uniqueElements: [asset])
        $0.liabilities = IdentifiedArray(uniqueElements: [liability])
    }
    await store.receive(
        .snapshotRecorded(
            NetWorthSnapshot(
                id: snapshotID,
                date: referenceDate,
                totalAssets: 50_000_000,
                totalLiabilities: 20_000_000
            )
        )
    ) {
        $0.snapshots = [
            NetWorthSnapshot(
                id: snapshotID,
                date: referenceDate,
                totalAssets: 50_000_000,
                totalLiabilities: 20_000_000
            ),
        ]
    }

    #expect(await snapshotRecorder.count() == 1)
}

@MainActor
@Test("saves asset from editor")
func savesAssetFromEditor() async throws {
    let referenceDate = try date(2026, 4, 26)
    let assetID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    let snapshotID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
    let expectedAsset = Asset(
        id: assetID,
        name: "Tiền mặt",
        type: .cash,
        currentValue: 5_000_000,
        lastUpdatedAt: referenceDate
    )
    let store = TestStore(initialState: WealthFeature.State(referenceDate: referenceDate)) {
        WealthFeature()
    } withDependencies: {
        $0.date.now = referenceDate
        $0.uuid = .incrementing
        $0.assetRepository.save = { _ in }
        $0.netWorthSnapshotRepository.save = { _ in }
    }

    await store.send(.assetAddButtonTapped) {
        $0.isAssetEditorPresented = true
        $0.editingAssetID = nil
        $0.assetNameText = ""
        $0.assetValueText = ""
        $0.assetType = .bankSavings
        $0.assetNoteText = ""
        $0.assetEditorErrorMessageKey = nil
    }
    await store.send(.assetNameTextChanged(" Tiền mặt ")) {
        $0.assetNameText = " Tiền mặt "
        $0.assetEditorErrorMessageKey = nil
    }
    await store.send(.assetTypeChanged(.cash)) {
        $0.assetType = .cash
        $0.assetEditorErrorMessageKey = nil
    }
    await store.send(.assetValueTextChanged("5.000.000")) {
        $0.assetValueText = "5.000.000"
        $0.assetEditorErrorMessageKey = nil
    }
    await store.send(.assetSaveButtonTapped) {
        $0.isAssetSaving = true
    }
    await store.receive(.assetSaved(expectedAsset)) {
        $0.isAssetSaving = false
        $0.isAssetEditorPresented = false
        $0.assets = IdentifiedArray(uniqueElements: [expectedAsset])
        $0.assetNameText = ""
        $0.assetValueText = ""
        $0.assetNoteText = ""
    }
    await store.receive(
        .snapshotRecorded(
            NetWorthSnapshot(
                id: snapshotID,
                date: referenceDate,
                totalAssets: 5_000_000,
                totalLiabilities: 0
            )
        )
    ) {
        $0.snapshots = [
            NetWorthSnapshot(
                id: snapshotID,
                date: referenceDate,
                totalAssets: 5_000_000,
                totalLiabilities: 0
            ),
        ]
    }
}

@MainActor
@Test("rejects invalid asset editor input")
func rejectsInvalidAssetEditorInput() async {
    let store = TestStore(
        initialState: WealthFeature.State(
            isAssetEditorPresented: true,
            assetNameText: "",
            assetValueText: "-1"
        )
    ) {
        WealthFeature()
    } withDependencies: {
        $0.date.now = Date(timeIntervalSinceReferenceDate: 0)
        $0.uuid = .constant(UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)))
    }

    await store.send(.assetSaveButtonTapped) {
        $0.assetEditorErrorMessageKey = "wealth.asset.error.nameRequired"
    }
}

@MainActor
@Test("saves liability from editor")
func savesLiabilityFromEditor() async throws {
    let referenceDate = try date(2026, 4, 26)
    let liabilityID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    let snapshotID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
    let expectedLiability = Liability(
        id: liabilityID,
        name: "Thẻ tín dụng",
        type: .creditCard,
        principalRemaining: 2_000_000,
        lastUpdatedAt: referenceDate
    )
    let store = TestStore(initialState: WealthFeature.State(referenceDate: referenceDate)) {
        WealthFeature()
    } withDependencies: {
        $0.date.now = referenceDate
        $0.uuid = .incrementing
        $0.liabilityRepository.save = { _ in }
        $0.netWorthSnapshotRepository.save = { _ in }
    }

    await store.send(.liabilityAddButtonTapped) {
        $0.isLiabilityEditorPresented = true
        $0.editingLiabilityID = nil
        $0.liabilityNameText = ""
        $0.liabilityValueText = ""
        $0.liabilityType = .personalLoan
        $0.liabilityNoteText = ""
        $0.liabilityEditorErrorMessageKey = nil
    }
    await store.send(.liabilityNameTextChanged("Thẻ tín dụng")) {
        $0.liabilityNameText = "Thẻ tín dụng"
        $0.liabilityEditorErrorMessageKey = nil
    }
    await store.send(.liabilityTypeChanged(.creditCard)) {
        $0.liabilityType = .creditCard
        $0.liabilityEditorErrorMessageKey = nil
    }
    await store.send(.liabilityValueTextChanged("2.000.000")) {
        $0.liabilityValueText = "2.000.000"
        $0.liabilityEditorErrorMessageKey = nil
    }
    await store.send(.liabilitySaveButtonTapped) {
        $0.isLiabilitySaving = true
    }
    await store.receive(.liabilitySaved(expectedLiability)) {
        $0.isLiabilitySaving = false
        $0.isLiabilityEditorPresented = false
        $0.liabilities = IdentifiedArray(uniqueElements: [expectedLiability])
        $0.liabilityNameText = ""
        $0.liabilityValueText = ""
        $0.liabilityNoteText = ""
    }
    await store.receive(
        .snapshotRecorded(
            NetWorthSnapshot(
                id: snapshotID,
                date: referenceDate,
                totalAssets: 0,
                totalLiabilities: 2_000_000
            )
        )
    ) {
        $0.snapshots = [
            NetWorthSnapshot(
                id: snapshotID,
                date: referenceDate,
                totalAssets: 0,
                totalLiabilities: 2_000_000
            ),
        ]
    }
}

private func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
    let calendar = Calendar(identifier: .gregorian)
    return try #require(DateComponents(calendar: calendar, year: year, month: month, day: day).date)
}

private actor SnapshotRecorder {
    private var snapshots: [NetWorthSnapshot] = []

    func save(_ snapshot: NetWorthSnapshot) {
        snapshots.append(snapshot)
    }

    func count() -> Int {
        snapshots.count
    }
}
