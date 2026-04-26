import Foundation
import ComposableArchitecture
import WealthDomain

@Reducer
public struct WealthFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var assets: IdentifiedArrayOf<Asset>
        public var liabilities: IdentifiedArrayOf<Liability>
        public var snapshots: [NetWorthSnapshot]
        public var referenceDate: Date
        public var isLoading: Bool
        public var isAssetEditorPresented: Bool
        public var isLiabilityEditorPresented: Bool
        public var isAssetSaving: Bool
        public var isLiabilitySaving: Bool
        public var editingAssetID: UUID?
        public var editingLiabilityID: UUID?
        public var assetNameText: String
        public var assetValueText: String
        public var assetType: AssetType
        public var assetNoteText: String
        public var liabilityNameText: String
        public var liabilityValueText: String
        public var liabilityType: LiabilityType
        public var liabilityNoteText: String
        public var errorMessageKey: String?
        public var assetEditorErrorMessageKey: String?
        public var liabilityEditorErrorMessageKey: String?

        public init(
            assets: IdentifiedArrayOf<Asset> = [],
            liabilities: IdentifiedArrayOf<Liability> = [],
            snapshots: [NetWorthSnapshot] = [],
            referenceDate: Date = Date(timeIntervalSinceReferenceDate: 0),
            isLoading: Bool = false,
            isAssetEditorPresented: Bool = false,
            isLiabilityEditorPresented: Bool = false,
            isAssetSaving: Bool = false,
            isLiabilitySaving: Bool = false,
            editingAssetID: UUID? = nil,
            editingLiabilityID: UUID? = nil,
            assetNameText: String = "",
            assetValueText: String = "",
            assetType: AssetType = .bankSavings,
            assetNoteText: String = "",
            liabilityNameText: String = "",
            liabilityValueText: String = "",
            liabilityType: LiabilityType = .personalLoan,
            liabilityNoteText: String = "",
            errorMessageKey: String? = nil,
            assetEditorErrorMessageKey: String? = nil,
            liabilityEditorErrorMessageKey: String? = nil
        ) {
            self.assets = assets
            self.liabilities = liabilities
            self.snapshots = snapshots
            self.referenceDate = referenceDate
            self.isLoading = isLoading
            self.isAssetEditorPresented = isAssetEditorPresented
            self.isLiabilityEditorPresented = isLiabilityEditorPresented
            self.isAssetSaving = isAssetSaving
            self.isLiabilitySaving = isLiabilitySaving
            self.editingAssetID = editingAssetID
            self.editingLiabilityID = editingLiabilityID
            self.assetNameText = assetNameText
            self.assetValueText = assetValueText
            self.assetType = assetType
            self.assetNoteText = assetNoteText
            self.liabilityNameText = liabilityNameText
            self.liabilityValueText = liabilityValueText
            self.liabilityType = liabilityType
            self.liabilityNoteText = liabilityNoteText
            self.errorMessageKey = errorMessageKey
            self.assetEditorErrorMessageKey = assetEditorErrorMessageKey
            self.liabilityEditorErrorMessageKey = liabilityEditorErrorMessageKey
        }

        public var currentSnapshot: NetWorthSnapshot {
            NetWorthCalculator.snapshot(
                assets: Array(assets),
                liabilities: Array(liabilities),
                on: referenceDate
            )
        }

        public var growth: NetWorthGrowth {
            currentSnapshot.growth(comparedTo: previousMonthlySnapshot)
        }

        public var breakdown: NetWorthBreakdown {
            NetWorthBreakdownBuilder.make(
                assets: Array(assets),
                liabilities: Array(liabilities)
            )
        }

        public var monthlyHistory: [NetWorthSnapshot] {
            NetWorthCalculator.monthlyHistory(
                recordedSnapshots: snapshots + [currentSnapshot],
                through: referenceDate
            )
        }

        private var previousMonthlySnapshot: NetWorthSnapshot? {
            snapshots
                .filter { Calendar.current.isDate($0.date, equalTo: referenceDate, toGranularity: .month) == false }
                .max { $0.date < $1.date }
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case wealthDataLoaded([Asset], [Liability], [NetWorthSnapshot])
        case loadFailed(String)
        case snapshotRecorded(NetWorthSnapshot)
        case snapshotRecordFailed(String)
        case assetAddButtonTapped
        case assetEditButtonTapped(Asset)
        case assetEditorDismissed
        case assetNameTextChanged(String)
        case assetValueTextChanged(String)
        case assetTypeChanged(AssetType)
        case assetNoteTextChanged(String)
        case assetSaveButtonTapped
        case assetSaved(Asset)
        case assetSaveFailed(String)
        case assetDeleteButtonTapped(Asset)
        case assetDeleted(UUID)
        case assetDeleteFailed(String)
        case liabilityAddButtonTapped
        case liabilityEditButtonTapped(Liability)
        case liabilityEditorDismissed
        case liabilityNameTextChanged(String)
        case liabilityValueTextChanged(String)
        case liabilityTypeChanged(LiabilityType)
        case liabilityNoteTextChanged(String)
        case liabilitySaveButtonTapped
        case liabilitySaved(Liability)
        case liabilitySaveFailed(String)
        case liabilityDeleteButtonTapped(Liability)
        case liabilityDeleted(UUID)
        case liabilityDeleteFailed(String)
    }

    @Dependency(\.assetRepository) private var assetRepository
    @Dependency(\.liabilityRepository) private var liabilityRepository
    @Dependency(\.netWorthSnapshotRepository) private var snapshotRepository
    @Dependency(\.date) private var date
    @Dependency(\.uuid) private var uuid

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.referenceDate = date.now
                state.isLoading = true
                state.errorMessageKey = nil
                return .run { send in
                    do {
                        let assets = try await assetRepository.fetchAll()
                        let liabilities = try await liabilityRepository.fetchAll()
                        let snapshots = try await snapshotRepository.fetchAll()
                        await send(.wealthDataLoaded(assets, liabilities, snapshots))
                    } catch {
                        await send(.loadFailed("wealth.error.loadFailed"))
                    }
                }

            case let .wealthDataLoaded(assets, liabilities, snapshots):
                state.isLoading = false
                state.assets = IdentifiedArray(uniqueElements: assets)
                state.liabilities = IdentifiedArray(uniqueElements: liabilities)
                state.snapshots = snapshots
                return recordSnapshotEffect(state.currentSnapshot)

            case let .loadFailed(messageKey):
                state.isLoading = false
                state.errorMessageKey = messageKey
                return .none

            case let .snapshotRecorded(snapshot):
                state.snapshots.removeAll { $0.id == snapshot.id }
                state.snapshots.append(snapshot)
                state.snapshots.sort { $0.date < $1.date }
                return .none

            case let .snapshotRecordFailed(messageKey):
                state.errorMessageKey = messageKey
                return .none

            case .assetAddButtonTapped:
                resetAssetEditor(&state)
                state.isAssetEditorPresented = true
                return .none

            case let .assetEditButtonTapped(asset):
                state.editingAssetID = asset.id
                state.assetNameText = asset.name
                state.assetValueText = Self.editingAmount(asset.currentValue)
                state.assetType = asset.type
                state.assetNoteText = asset.note ?? ""
                state.assetEditorErrorMessageKey = nil
                state.isAssetEditorPresented = true
                return .none

            case .assetEditorDismissed:
                state.isAssetEditorPresented = false
                return .none

            case let .assetNameTextChanged(text):
                state.assetNameText = text
                state.assetEditorErrorMessageKey = nil
                return .none

            case let .assetValueTextChanged(text):
                state.assetValueText = text
                state.assetEditorErrorMessageKey = nil
                return .none

            case let .assetTypeChanged(type):
                state.assetType = type
                state.assetEditorErrorMessageKey = nil
                return .none

            case let .assetNoteTextChanged(text):
                state.assetNoteText = text
                state.assetEditorErrorMessageKey = nil
                return .none

            case .assetSaveButtonTapped:
                return saveAssetEffect(&state)

            case let .assetSaved(asset):
                state.isAssetSaving = false
                state.isAssetEditorPresented = false
                state.assets.remove(id: asset.id)
                state.assets.append(asset)
                state.assets.sort { $0.name < $1.name }
                clearAssetForm(&state)
                return recordSnapshotEffect(state.currentSnapshot)

            case let .assetSaveFailed(messageKey):
                state.isAssetSaving = false
                state.assetEditorErrorMessageKey = messageKey
                return .none

            case let .assetDeleteButtonTapped(asset):
                return .run { send in
                    do {
                        try await assetRepository.delete(asset.id)
                        await send(.assetDeleted(asset.id))
                    } catch {
                        await send(.assetDeleteFailed("wealth.asset.error.deleteFailed"))
                    }
                }

            case let .assetDeleted(id):
                state.assets.remove(id: id)
                return recordSnapshotEffect(state.currentSnapshot)

            case let .assetDeleteFailed(messageKey):
                state.errorMessageKey = messageKey
                return .none

            case .liabilityAddButtonTapped:
                resetLiabilityEditor(&state)
                state.isLiabilityEditorPresented = true
                return .none

            case let .liabilityEditButtonTapped(liability):
                state.editingLiabilityID = liability.id
                state.liabilityNameText = liability.name
                state.liabilityValueText = Self.editingAmount(liability.principalRemaining)
                state.liabilityType = liability.type
                state.liabilityNoteText = liability.note ?? ""
                state.liabilityEditorErrorMessageKey = nil
                state.isLiabilityEditorPresented = true
                return .none

            case .liabilityEditorDismissed:
                state.isLiabilityEditorPresented = false
                return .none

            case let .liabilityNameTextChanged(text):
                state.liabilityNameText = text
                state.liabilityEditorErrorMessageKey = nil
                return .none

            case let .liabilityValueTextChanged(text):
                state.liabilityValueText = text
                state.liabilityEditorErrorMessageKey = nil
                return .none

            case let .liabilityTypeChanged(type):
                state.liabilityType = type
                state.liabilityEditorErrorMessageKey = nil
                return .none

            case let .liabilityNoteTextChanged(text):
                state.liabilityNoteText = text
                state.liabilityEditorErrorMessageKey = nil
                return .none

            case .liabilitySaveButtonTapped:
                return saveLiabilityEffect(&state)

            case let .liabilitySaved(liability):
                state.isLiabilitySaving = false
                state.isLiabilityEditorPresented = false
                state.liabilities.remove(id: liability.id)
                state.liabilities.append(liability)
                state.liabilities.sort { $0.name < $1.name }
                clearLiabilityForm(&state)
                return recordSnapshotEffect(state.currentSnapshot)

            case let .liabilitySaveFailed(messageKey):
                state.isLiabilitySaving = false
                state.liabilityEditorErrorMessageKey = messageKey
                return .none

            case let .liabilityDeleteButtonTapped(liability):
                return .run { send in
                    do {
                        try await liabilityRepository.delete(liability.id)
                        await send(.liabilityDeleted(liability.id))
                    } catch {
                        await send(.liabilityDeleteFailed("wealth.liability.error.deleteFailed"))
                    }
                }

            case let .liabilityDeleted(id):
                state.liabilities.remove(id: id)
                return recordSnapshotEffect(state.currentSnapshot)

            case let .liabilityDeleteFailed(messageKey):
                state.errorMessageKey = messageKey
                return .none
            }
        }
    }

    private func saveAssetEffect(_ state: inout State) -> Effect<Action> {
        guard let currentValue = Self.parseAmount(state.assetValueText) else {
            state.assetEditorErrorMessageKey = "wealth.asset.error.invalidValue"
            return .none
        }

        let draft = AssetDraft(
            name: state.assetNameText,
            type: state.assetType,
            currentValue: currentValue,
            note: state.assetNoteText
        )

        do {
            let asset: Asset
            if let id = state.editingAssetID, let existing = state.assets[id: id] {
                asset = try draft.updating(existing: existing, lastUpdatedAt: date.now)
            } else {
                asset = try draft.validated(id: uuid(), lastUpdatedAt: date.now)
            }
            state.isAssetSaving = true
            return .run { send in
                do {
                    try await assetRepository.save(asset)
                    await send(.assetSaved(asset))
                } catch {
                    await send(.assetSaveFailed("wealth.asset.error.saveFailed"))
                }
            }
        } catch let error as AssetValidationError {
            state.assetEditorErrorMessageKey = error.messageKey
            return .none
        } catch {
            state.assetEditorErrorMessageKey = "wealth.asset.error.saveFailed"
            return .none
        }
    }

    private func saveLiabilityEffect(_ state: inout State) -> Effect<Action> {
        guard let principal = Self.parseAmount(state.liabilityValueText) else {
            state.liabilityEditorErrorMessageKey = "wealth.liability.error.invalidValue"
            return .none
        }

        let draft = LiabilityDraft(
            name: state.liabilityNameText,
            type: state.liabilityType,
            principalRemaining: principal,
            note: state.liabilityNoteText
        )

        do {
            let liability: Liability
            if let id = state.editingLiabilityID, let existing = state.liabilities[id: id] {
                liability = try draft.updating(existing: existing, lastUpdatedAt: date.now)
            } else {
                liability = try draft.validated(id: uuid(), lastUpdatedAt: date.now)
            }
            state.isLiabilitySaving = true
            return .run { send in
                do {
                    try await liabilityRepository.save(liability)
                    await send(.liabilitySaved(liability))
                } catch {
                    await send(.liabilitySaveFailed("wealth.liability.error.saveFailed"))
                }
            }
        } catch let error as LiabilityValidationError {
            state.liabilityEditorErrorMessageKey = error.messageKey
            return .none
        } catch {
            state.liabilityEditorErrorMessageKey = "wealth.liability.error.saveFailed"
            return .none
        }
    }

    private func recordSnapshotEffect(_ snapshot: NetWorthSnapshot) -> Effect<Action> {
        let snapshot = NetWorthSnapshot(
            id: uuid(),
            date: snapshot.date,
            totalAssets: snapshot.totalAssets,
            totalLiabilities: snapshot.totalLiabilities
        )
        return .run { send in
            do {
                try await snapshotRepository.save(snapshot)
                await send(.snapshotRecorded(snapshot))
            } catch {
                await send(.snapshotRecordFailed("wealth.snapshot.error.saveFailed"))
            }
        }
    }

    private static func parseAmount(_ text: String) -> Decimal? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
        guard normalized.isEmpty == false else {
            return nil
        }
        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }

    private static func editingAmount(_ amount: Decimal) -> String {
        NSDecimalNumber(decimal: amount).stringValue
    }
}
