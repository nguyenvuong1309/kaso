import WealthDomain

func resetAssetEditor(_ state: inout WealthFeature.State) {
    state.editingAssetID = nil
    state.assetNameText = ""
    state.assetValueText = ""
    state.assetType = .bankSavings
    state.assetNoteText = ""
    state.assetEditorErrorMessageKey = nil
}

func clearAssetForm(_ state: inout WealthFeature.State) {
    state.editingAssetID = nil
    state.assetNameText = ""
    state.assetValueText = ""
    state.assetNoteText = ""
    state.assetEditorErrorMessageKey = nil
}

func resetLiabilityEditor(_ state: inout WealthFeature.State) {
    state.editingLiabilityID = nil
    state.liabilityNameText = ""
    state.liabilityValueText = ""
    state.liabilityType = .personalLoan
    state.liabilityNoteText = ""
    state.liabilityEditorErrorMessageKey = nil
}

func clearLiabilityForm(_ state: inout WealthFeature.State) {
    state.editingLiabilityID = nil
    state.liabilityNameText = ""
    state.liabilityValueText = ""
    state.liabilityNoteText = ""
    state.liabilityEditorErrorMessageKey = nil
}

extension AssetValidationError {
    var messageKey: String {
        switch self {
        case .nameRequired:
            "wealth.asset.error.nameRequired"
        case .currentValueCannotBeNegative:
            "wealth.asset.error.invalidValue"
        }
    }
}

extension LiabilityValidationError {
    var messageKey: String {
        switch self {
        case .nameRequired:
            "wealth.liability.error.nameRequired"
        case .principalCannotBeNegative:
            "wealth.liability.error.invalidValue"
        }
    }
}
