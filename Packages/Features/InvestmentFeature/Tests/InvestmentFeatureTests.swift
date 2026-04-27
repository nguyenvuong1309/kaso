import Foundation
import Testing
import ComposableArchitecture
import InvestmentDomain
import WealthDomain
@testable import InvestmentFeature

@MainActor
@Test("loads portfolio and syncs auto tracked investment asset")
func loadsPortfolioAndSyncsInvestmentAsset() async throws {
    let referenceDate = try date(2026, 4, 26)
    let holding = Holding(
        symbol: "FPT",
        name: "FPT Corp",
        assetClass: .stock,
        lots: [
            InvestmentLot(quantity: 100, costBasisPerUnit: 90_000, purchasedAt: referenceDate),
        ],
        createdAt: referenceDate
    )
    let quote = PriceQuote(symbol: "FPT", price: 110_000, asOf: referenceDate)
    let target = TargetAllocation(fractions: [.stock: 1.0])
    let recorder = AssetRecorder()
    let store = TestStore(initialState: InvestmentFeature.State()) {
        InvestmentFeature()
    } withDependencies: {
        $0.date.now = referenceDate
        $0.holdingRepository.fetchAll = { [holding] }
        $0.priceQuoteRepository.fetchAll = { [quote] }
        $0.targetAllocationRepository.load = { target }
        $0.investmentAssetSyncClient.replaceAutoTracked = { await recorder.save($0) }
    }

    await store.send(.task) {
        $0.referenceDate = referenceDate
        $0.isLoading = true
    }
    await store.receive(.investmentDataLoaded([holding], [quote], target)) {
        $0.isLoading = false
        $0.holdings = IdentifiedArray(uniqueElements: [holding])
        $0.quotes = [quote]
        $0.targetAllocation = target
    }
    await store.receive(.investmentAssetSynced)

    let syncedAssets = await recorder.assets()
    #expect(syncedAssets.count == 1)
    #expect(syncedAssets.first?.type == .investment)
    #expect(syncedAssets.first?.currentValue == 11_000_000)
    #expect(syncedAssets.first?.isAutoTracked == true)
}

@MainActor
@Test("saves holding and quote from editor")
func savesHoldingAndQuoteFromEditor() async throws {
    let referenceDate = try date(2026, 4, 26)
    let holdingID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    let lotID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
    let expectedHolding = Holding(
        id: holdingID,
        symbol: "FPT",
        name: "FPT Corp",
        assetClass: .stock,
        lots: [
            InvestmentLot(
                id: lotID,
                quantity: 100,
                costBasisPerUnit: 90_000,
                purchasedAt: referenceDate
            ),
        ],
        createdAt: referenceDate
    )
    let expectedQuote = PriceQuote(symbol: "FPT", price: 110_000, asOf: referenceDate)
    let store = TestStore(initialState: InvestmentFeature.State(referenceDate: referenceDate)) {
        InvestmentFeature()
    } withDependencies: {
        $0.date.now = referenceDate
        $0.uuid = .incrementing
        $0.holdingRepository.save = { _ in }
        $0.priceQuoteRepository.save = { _ in }
        $0.investmentAssetSyncClient.replaceAutoTracked = { _ in }
    }

    await store.send(.holdingAddButtonTapped) {
        $0.isHoldingEditorPresented = true
        $0.purchaseDate = referenceDate
        $0.assetClass = .stock
        $0.holdingEditorErrorMessageKey = nil
    }
    await store.send(.symbolTextChanged(" fpt ")) {
        $0.symbolText = " fpt "
        $0.holdingEditorErrorMessageKey = nil
    }
    await store.send(.nameTextChanged("FPT Corp")) {
        $0.nameText = "FPT Corp"
        $0.holdingEditorErrorMessageKey = nil
    }
    await store.send(.quantityTextChanged("100")) {
        $0.quantityText = "100"
        $0.holdingEditorErrorMessageKey = nil
    }
    await store.send(.costBasisTextChanged("90.000")) {
        $0.costBasisText = "90.000"
        $0.holdingEditorErrorMessageKey = nil
    }
    await store.send(.currentPriceTextChanged("110.000")) {
        $0.currentPriceText = "110.000"
        $0.holdingEditorErrorMessageKey = nil
    }
    await store.send(.holdingSaveButtonTapped) {
        $0.isHoldingSaving = true
    }
    await store.receive(.holdingSaved(expectedHolding, expectedQuote)) {
        $0.isHoldingSaving = false
        $0.isHoldingEditorPresented = false
        $0.holdings = IdentifiedArray(uniqueElements: [expectedHolding])
        $0.quotes = [expectedQuote]
        $0.symbolText = ""
        $0.nameText = ""
        $0.quantityText = ""
        $0.costBasisText = ""
        $0.currentPriceText = ""
        $0.noteText = ""
    }
    await store.receive(.investmentAssetSynced)
}

@MainActor
@Test("saves target allocation from percent fields")
func savesTargetAllocationFromPercentFields() async {
    let target = TargetAllocation(fractions: [.stock: 0.7, .gold: 0.3])
    let store = TestStore(
        initialState: InvestmentFeature.State(
            isTargetEditorPresented: true,
            targetPercentTexts: [.stock: "70", .gold: "30"]
        )
    ) {
        InvestmentFeature()
    } withDependencies: {
        $0.targetAllocationRepository.save = { _ in }
    }

    await store.send(.targetSaveButtonTapped) {
        $0.isTargetSaving = true
    }
    await store.receive(.targetSaved(target)) {
        $0.isTargetSaving = false
        $0.isTargetEditorPresented = false
        $0.targetAllocation = target
        $0.targetEditorErrorMessageKey = nil
    }
}

@MainActor
@Test("rejects invalid target allocation total")
func rejectsInvalidTargetAllocationTotal() async {
    let store = TestStore(
        initialState: InvestmentFeature.State(
            isTargetEditorPresented: true,
            targetPercentTexts: [.stock: "60", .gold: "20"]
        )
    ) {
        InvestmentFeature()
    }

    await store.send(.targetSaveButtonTapped) {
        $0.targetEditorErrorMessageKey = "investment.target.error.sumMustEqual100"
    }
}

private func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
    let calendar = Calendar(identifier: .gregorian)
    return try #require(DateComponents(calendar: calendar, year: year, month: month, day: day).date)
}

private actor AssetRecorder {
    private var storedAssets: [Asset] = []

    func save(_ assets: [Asset]) {
        storedAssets = assets
    }

    func assets() -> [Asset] {
        storedAssets
    }
}
