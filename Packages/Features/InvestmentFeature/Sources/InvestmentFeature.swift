import Foundation
import ComposableArchitecture
import InvestmentDomain

@Reducer
public struct InvestmentFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var holdings: IdentifiedArrayOf<Holding>
        public var quotes: [PriceQuote]
        public var targetAllocation: TargetAllocation
        public var referenceDate: Date
        public var isLoading: Bool
        public var isRefreshingPrices: Bool
        public var isHoldingEditorPresented: Bool
        public var isTargetEditorPresented: Bool
        public var isHoldingSaving: Bool
        public var isTargetSaving: Bool
        public var editingHoldingID: UUID?
        public var symbolText: String
        public var nameText: String
        public var assetClass: AssetClass
        public var quantityText: String
        public var costBasisText: String
        public var currentPriceText: String
        public var purchaseDate: Date
        public var noteText: String
        public var targetPercentTexts: [AssetClass: String]
        public var errorMessageKey: String?
        public var holdingEditorErrorMessageKey: String?
        public var targetEditorErrorMessageKey: String?

        public init(
            holdings: IdentifiedArrayOf<Holding> = [],
            quotes: [PriceQuote] = [],
            targetAllocation: TargetAllocation = .empty,
            referenceDate: Date = Date(timeIntervalSinceReferenceDate: 0),
            isLoading: Bool = false,
            isRefreshingPrices: Bool = false,
            isHoldingEditorPresented: Bool = false,
            isTargetEditorPresented: Bool = false,
            isHoldingSaving: Bool = false,
            isTargetSaving: Bool = false,
            editingHoldingID: UUID? = nil,
            symbolText: String = "",
            nameText: String = "",
            assetClass: AssetClass = .stock,
            quantityText: String = "",
            costBasisText: String = "",
            currentPriceText: String = "",
            purchaseDate: Date = Date(timeIntervalSinceReferenceDate: 0),
            noteText: String = "",
            targetPercentTexts: [AssetClass: String] = [:],
            errorMessageKey: String? = nil,
            holdingEditorErrorMessageKey: String? = nil,
            targetEditorErrorMessageKey: String? = nil
        ) {
            self.holdings = holdings
            self.quotes = quotes
            self.targetAllocation = targetAllocation
            self.referenceDate = referenceDate
            self.isLoading = isLoading
            self.isRefreshingPrices = isRefreshingPrices
            self.isHoldingEditorPresented = isHoldingEditorPresented
            self.isTargetEditorPresented = isTargetEditorPresented
            self.isHoldingSaving = isHoldingSaving
            self.isTargetSaving = isTargetSaving
            self.editingHoldingID = editingHoldingID
            self.symbolText = symbolText
            self.nameText = nameText
            self.assetClass = assetClass
            self.quantityText = quantityText
            self.costBasisText = costBasisText
            self.currentPriceText = currentPriceText
            self.purchaseDate = purchaseDate
            self.noteText = noteText
            self.targetPercentTexts = targetPercentTexts
            self.errorMessageKey = errorMessageKey
            self.holdingEditorErrorMessageKey = holdingEditorErrorMessageKey
            self.targetEditorErrorMessageKey = targetEditorErrorMessageKey
        }

        public var metrics: PortfolioMetrics {
            PortfolioMetricsCalculator.calculate(
                holdings: Array(holdings),
                quotes: quotes
            )
        }

        public var allocationBreakdown: AllocationBreakdown {
            AllocationBreakdownBuilder.make(metrics: metrics)
        }

        public var rebalanceSuggestion: RebalanceSuggestion {
            RebalanceEngine.suggest(
                breakdown: allocationBreakdown,
                target: targetAllocation
            )
        }

        public var quoteMap: [String: PriceQuote] {
            quotes.reduce(into: [String: PriceQuote]()) { partial, quote in
                partial[quote.symbol.uppercased()] = quote
            }
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case investmentDataLoaded([Holding], [PriceQuote], TargetAllocation)
        case loadFailed(String)
        case investmentAssetSynced
        case investmentAssetSyncFailed(String)
        case holdingAddButtonTapped
        case holdingEditButtonTapped(Holding)
        case holdingEditorDismissed
        case symbolTextChanged(String)
        case nameTextChanged(String)
        case assetClassChanged(AssetClass)
        case quantityTextChanged(String)
        case costBasisTextChanged(String)
        case currentPriceTextChanged(String)
        case purchaseDateChanged(Date)
        case noteTextChanged(String)
        case holdingSaveButtonTapped
        case holdingSaved(Holding, PriceQuote?)
        case holdingSaveFailed(String)
        case holdingDeleteButtonTapped(Holding)
        case holdingDeleted(UUID)
        case holdingDeleteFailed(String)
        case targetEditButtonTapped
        case targetEditorDismissed
        case targetPercentTextChanged(AssetClass, String)
        case targetSaveButtonTapped
        case targetSaved(TargetAllocation)
        case targetSaveFailed(String)
        case refreshPricesButtonTapped
        case priceRefreshSucceeded([PriceQuote])
        case priceRefreshFailed(String)
    }

    @Dependency(\.holdingRepository) private var holdingRepository
    @Dependency(\.priceQuoteRepository) private var priceQuoteRepository
    @Dependency(\.targetAllocationRepository) private var targetAllocationRepository
    @Dependency(\.investmentAssetSyncClient) private var assetSyncClient
    @Dependency(\.marketPriceProvider) private var marketPriceProvider
    @Dependency(\.date) private var date
    @Dependency(\.uuid) private var uuid

    private static let portfolioAssetID = UUID(uuidString: "00000000-0000-0000-0000-000000000102") ?? UUID()

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
                        let holdings = try await holdingRepository.fetchAll()
                        let quotes = try await priceQuoteRepository.fetchAll()
                        let target = try await targetAllocationRepository.load()
                        await send(.investmentDataLoaded(holdings, quotes, target))
                    } catch {
                        await send(.loadFailed("investment.error.loadFailed"))
                    }
                }

            case let .investmentDataLoaded(holdings, quotes, target):
                state.isLoading = false
                state.holdings = IdentifiedArray(uniqueElements: Self.sortedHoldings(holdings))
                state.quotes = Self.sortedQuotes(quotes)
                state.targetAllocation = target
                return syncInvestmentAssetEffect(metrics: state.metrics)

            case let .loadFailed(messageKey):
                state.isLoading = false
                state.errorMessageKey = messageKey
                return .none

            case .investmentAssetSynced:
                return .none

            case let .investmentAssetSyncFailed(messageKey):
                state.errorMessageKey = messageKey
                return .none

            case .holdingAddButtonTapped:
                resetHoldingEditor(&state, purchaseDate: date.now)
                state.isHoldingEditorPresented = true
                return .none

            case let .holdingEditButtonTapped(holding):
                populateHoldingEditor(&state, holding: holding)
                state.isHoldingEditorPresented = true
                return .none

            case .holdingEditorDismissed:
                state.isHoldingEditorPresented = false
                return .none

            case let .symbolTextChanged(text):
                state.symbolText = text
                state.holdingEditorErrorMessageKey = nil
                return .none

            case let .nameTextChanged(text):
                state.nameText = text
                state.holdingEditorErrorMessageKey = nil
                return .none

            case let .assetClassChanged(assetClass):
                state.assetClass = assetClass
                state.holdingEditorErrorMessageKey = nil
                return .none

            case let .quantityTextChanged(text):
                state.quantityText = text
                state.holdingEditorErrorMessageKey = nil
                return .none

            case let .costBasisTextChanged(text):
                state.costBasisText = text
                state.holdingEditorErrorMessageKey = nil
                return .none

            case let .currentPriceTextChanged(text):
                state.currentPriceText = text
                state.holdingEditorErrorMessageKey = nil
                return .none

            case let .purchaseDateChanged(purchaseDate):
                state.purchaseDate = purchaseDate
                state.holdingEditorErrorMessageKey = nil
                return .none

            case let .noteTextChanged(text):
                state.noteText = text
                state.holdingEditorErrorMessageKey = nil
                return .none

            case .holdingSaveButtonTapped:
                return saveHoldingEffect(&state)

            case let .holdingSaved(holding, quote):
                state.isHoldingSaving = false
                state.isHoldingEditorPresented = false
                state.holdings.remove(id: holding.id)
                state.holdings.append(holding)
                state.holdings = IdentifiedArray(uniqueElements: Self.sortedHoldings(Array(state.holdings)))
                if let quote {
                    state.quotes.removeAll { $0.symbol.caseInsensitiveCompare(quote.symbol) == .orderedSame }
                    state.quotes.append(quote)
                    state.quotes = Self.sortedQuotes(state.quotes)
                }
                clearHoldingEditor(&state)
                return syncInvestmentAssetEffect(metrics: state.metrics)

            case let .holdingSaveFailed(messageKey):
                state.isHoldingSaving = false
                state.holdingEditorErrorMessageKey = messageKey
                return .none

            case let .holdingDeleteButtonTapped(holding):
                return .run { send in
                    do {
                        try await holdingRepository.delete(holding.id)
                        await send(.holdingDeleted(holding.id))
                    } catch {
                        await send(.holdingDeleteFailed("investment.error.deleteFailed"))
                    }
                }

            case let .holdingDeleted(id):
                state.holdings.remove(id: id)
                return syncInvestmentAssetEffect(metrics: state.metrics)

            case let .holdingDeleteFailed(messageKey):
                state.errorMessageKey = messageKey
                return .none

            case .targetEditButtonTapped:
                populateTargetEditor(&state)
                state.isTargetEditorPresented = true
                return .none

            case .targetEditorDismissed:
                state.isTargetEditorPresented = false
                return .none

            case let .targetPercentTextChanged(assetClass, text):
                state.targetPercentTexts[assetClass] = text
                state.targetEditorErrorMessageKey = nil
                return .none

            case .targetSaveButtonTapped:
                return saveTargetAllocationEffect(&state)

            case let .targetSaved(target):
                state.isTargetSaving = false
                state.isTargetEditorPresented = false
                state.targetAllocation = target
                state.targetEditorErrorMessageKey = nil
                return .none

            case let .targetSaveFailed(messageKey):
                state.isTargetSaving = false
                state.targetEditorErrorMessageKey = messageKey
                return .none

            case .refreshPricesButtonTapped:
                guard state.isRefreshingPrices == false else { return .none }
                let symbols = state.holdings.map(\.symbol)
                guard symbols.isEmpty == false else {
                    state.errorMessageKey = "investment.error.noHoldingsToRefresh"
                    return .none
                }
                state.isRefreshingPrices = true
                state.errorMessageKey = nil
                return .run { send in
                    do {
                        let quotes = try await marketPriceProvider.fetchQuotes(symbols)
                        try await priceQuoteRepository.saveMany(quotes)
                        await send(.priceRefreshSucceeded(quotes))
                    } catch {
                        await send(.priceRefreshFailed("investment.error.priceRefreshFailed"))
                    }
                }

            case let .priceRefreshSucceeded(quotes):
                state.isRefreshingPrices = false
                var merged = state.quotes.reduce(into: [String: PriceQuote]()) { partial, quote in
                    partial[quote.symbol.uppercased()] = quote
                }
                for quote in quotes {
                    merged[quote.symbol.uppercased()] = quote
                }
                state.quotes = Self.sortedQuotes(Array(merged.values))
                return syncInvestmentAssetEffect(metrics: state.metrics)

            case let .priceRefreshFailed(messageKey):
                state.isRefreshingPrices = false
                state.errorMessageKey = messageKey
                return .none
            }
        }
    }

    private func saveHoldingEffect(_ state: inout State) -> Effect<Action> {
        guard let quantity = InvestmentFeatureFormatters.parseDecimal(state.quantityText) else {
            state.holdingEditorErrorMessageKey = "investment.error.invalidQuantity"
            return .none
        }
        guard let costBasis = InvestmentFeatureFormatters.parseDecimal(state.costBasisText) else {
            state.holdingEditorErrorMessageKey = "investment.error.invalidCostBasis"
            return .none
        }

        let quote = makeQuote(from: state)
        if quote.isInvalid {
            state.holdingEditorErrorMessageKey = "investment.error.invalidCurrentPrice"
            return .none
        }

        let existingHolding = state.editingHoldingID.flatMap { state.holdings[id: $0] }
        let holdingID = existingHolding?.id ?? uuid()
        let lotID = existingHolding?.lots.first?.id ?? uuid()
        let draft = HoldingDraft(
            symbol: state.symbolText,
            name: state.nameText,
            assetClass: state.assetClass,
            lots: [
                LotDraft(
                    id: lotID,
                    quantity: quantity,
                    costBasisPerUnit: costBasis,
                    purchasedAt: state.purchaseDate
                ),
            ],
            note: state.noteText
        )

        do {
            let holding: Holding
            if let existingHolding {
                holding = try draft.updating(existing: existingHolding)
            } else {
                holding = try draft.validated(id: holdingID, createdAt: date.now)
            }
            let priceQuote = quote.value(for: holding.symbol, asOf: date.now)
            state.isHoldingSaving = true
            return .run { send in
                do {
                    try await holdingRepository.save(holding)
                    if let priceQuote {
                        try await priceQuoteRepository.save(priceQuote)
                    }
                    await send(.holdingSaved(holding, priceQuote))
                } catch {
                    await send(.holdingSaveFailed("investment.error.saveFailed"))
                }
            }
        } catch let error as HoldingValidationError {
            state.holdingEditorErrorMessageKey = error.messageKey
            return .none
        } catch {
            state.holdingEditorErrorMessageKey = "investment.error.saveFailed"
            return .none
        }
    }

    private func saveTargetAllocationEffect(_ state: inout State) -> Effect<Action> {
        var fractions: [AssetClass: Double] = [:]
        for assetClass in AssetClass.allCases {
            let text = state.targetPercentTexts[assetClass] ?? ""
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.isEmpty == false else {
                continue
            }
            guard let fraction = InvestmentFeatureFormatters.parsePercentFraction(trimmed) else {
                state.targetEditorErrorMessageKey = "investment.target.error.invalidPercent"
                return .none
            }
            fractions[assetClass] = fraction
        }

        do {
            let target = try TargetAllocation(fractions: fractions).validated()
            state.isTargetSaving = true
            return .run { send in
                do {
                    try await targetAllocationRepository.save(target)
                    await send(.targetSaved(target))
                } catch {
                    await send(.targetSaveFailed("investment.target.error.saveFailed"))
                }
            }
        } catch let error as TargetAllocationValidationError {
            state.targetEditorErrorMessageKey = error.messageKey
            return .none
        } catch {
            state.targetEditorErrorMessageKey = "investment.target.error.saveFailed"
            return .none
        }
    }

    private func syncInvestmentAssetEffect(metrics: PortfolioMetrics) -> Effect<Action> {
        let asset = metrics.marketValue > 0
            ? metrics.toAggregatedAsset(
                id: Self.portfolioAssetID,
                name: "Danh mục đầu tư",
                lastUpdatedAt: date.now
            )
            : nil
        return .run { send in
            do {
                try await assetSyncClient.replaceAutoTracked(asset.map { [$0] } ?? [])
                await send(.investmentAssetSynced)
            } catch {
                await send(.investmentAssetSyncFailed("investment.error.assetSyncFailed"))
            }
        }
    }

    private static func sortedHoldings(_ holdings: [Holding]) -> [Holding] {
        holdings.sorted {
            if $0.assetClass == $1.assetClass {
                $0.symbol.localizedCaseInsensitiveCompare($1.symbol) == .orderedAscending
            } else {
                $0.assetClass.rawValue < $1.assetClass.rawValue
            }
        }
    }

    private static func sortedQuotes(_ quotes: [PriceQuote]) -> [PriceQuote] {
        quotes.sorted { $0.symbol.localizedCaseInsensitiveCompare($1.symbol) == .orderedAscending }
    }

    private func makeQuote(from state: State) -> QuoteDraftResult {
        let trimmed = state.currentPriceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            return .empty
        }
        guard let price = InvestmentFeatureFormatters.parseDecimal(trimmed), price >= 0 else {
            return .invalid
        }
        return .valid(price)
    }
}

private enum QuoteDraftResult {
    case empty
    case valid(Decimal)
    case invalid

    var isInvalid: Bool {
        if case .invalid = self {
            return true
        }
        return false
    }

    func value(for symbol: String, asOf date: Date) -> PriceQuote? {
        if case let .valid(price) = self {
            return PriceQuote(symbol: symbol, price: price, asOf: date)
        }
        return nil
    }
}
