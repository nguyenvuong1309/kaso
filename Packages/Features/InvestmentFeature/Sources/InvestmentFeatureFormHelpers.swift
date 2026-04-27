import Foundation
import InvestmentDomain

func resetHoldingEditor(
    _ state: inout InvestmentFeature.State,
    purchaseDate: Date
) {
    state.editingHoldingID = nil
    state.symbolText = ""
    state.nameText = ""
    state.assetClass = .stock
    state.quantityText = ""
    state.costBasisText = ""
    state.currentPriceText = ""
    state.purchaseDate = purchaseDate
    state.noteText = ""
    state.holdingEditorErrorMessageKey = nil
}

func clearHoldingEditor(_ state: inout InvestmentFeature.State) {
    state.editingHoldingID = nil
    state.symbolText = ""
    state.nameText = ""
    state.quantityText = ""
    state.costBasisText = ""
    state.currentPriceText = ""
    state.noteText = ""
    state.holdingEditorErrorMessageKey = nil
}

func populateHoldingEditor(
    _ state: inout InvestmentFeature.State,
    holding: Holding
) {
    let lot = holding.lots.first
    let quote = state.quoteMap[holding.symbol.uppercased()]
    state.editingHoldingID = holding.id
    state.symbolText = holding.symbol
    state.nameText = holding.name
    state.assetClass = holding.assetClass
    state.quantityText = lot.map { InvestmentFeatureFormatters.decimalText($0.quantity) } ?? ""
    state.costBasisText = lot.map { InvestmentFeatureFormatters.decimalText($0.costBasisPerUnit) } ?? ""
    state.currentPriceText = quote.map { InvestmentFeatureFormatters.decimalText($0.price) } ?? ""
    state.purchaseDate = lot?.purchasedAt ?? state.referenceDate
    state.noteText = holding.note ?? ""
    state.holdingEditorErrorMessageKey = nil
}

func populateTargetEditor(_ state: inout InvestmentFeature.State) {
    state.targetPercentTexts = AssetClass.allCases.reduce(into: [AssetClass: String]()) { partial, assetClass in
        if let fraction = state.targetAllocation.fractions[assetClass] {
            partial[assetClass] = InvestmentFeatureFormatters.percentText(fraction)
        } else {
            partial[assetClass] = ""
        }
    }
    state.targetEditorErrorMessageKey = nil
}
