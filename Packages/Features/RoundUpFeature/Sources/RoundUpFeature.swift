import ComposableArchitecture
import Foundation
import RoundUpDomain

@Reducer
public struct RoundUpFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var rule: RoundUpRule
        public var entries: IdentifiedArrayOf<RoundUpEntry>
        public var referenceDate: Date
        public var isLoading: Bool
        public var isSavingRule: Bool
        public var isSimulatorPresented: Bool
        public var simulatorAmountText: String
        public var simulatorContribution: Decimal
        public var errorMessageKey: String?
        public var manualEntryAmountText: String
        public var manualEntryNoteText: String
        public var isManualEntryPresented: Bool

        public init(
            rule: RoundUpRule = RoundUpRule(),
            entries: IdentifiedArrayOf<RoundUpEntry> = [],
            referenceDate: Date = Date(timeIntervalSinceReferenceDate: 0),
            isLoading: Bool = false,
            isSavingRule: Bool = false,
            isSimulatorPresented: Bool = false,
            simulatorAmountText: String = "",
            simulatorContribution: Decimal = 0,
            errorMessageKey: String? = nil,
            manualEntryAmountText: String = "",
            manualEntryNoteText: String = "",
            isManualEntryPresented: Bool = false
        ) {
            self.rule = rule
            self.entries = entries
            self.referenceDate = referenceDate
            self.isLoading = isLoading
            self.isSavingRule = isSavingRule
            self.isSimulatorPresented = isSimulatorPresented
            self.simulatorAmountText = simulatorAmountText
            self.simulatorContribution = simulatorContribution
            self.errorMessageKey = errorMessageKey
            self.manualEntryAmountText = manualEntryAmountText
            self.manualEntryNoteText = manualEntryNoteText
            self.isManualEntryPresented = isManualEntryPresented
        }

        public var summary: RoundUpJarSummary {
            RoundUpJarSummaryBuilder.summary(
                entries: Array(entries),
                referenceDate: referenceDate
            )
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case dataLoaded(rule: RoundUpRule, entries: [RoundUpEntry])
        case loadFailed(String)
        case toggleEnabled(Bool)
        case stepChanged(RoundUpStep)
        case ruleSaved(RoundUpRule)
        case saveRuleFailed(String)
        case simulatorOpened
        case simulatorDismissed
        case simulatorAmountChanged(String)
        case manualEntryOpened
        case manualEntryDismissed
        case manualEntryAmountChanged(String)
        case manualEntryNoteChanged(String)
        case manualEntrySubmitted
        case entryRecorded(RoundUpEntry)
        case entrySaveFailed(String)
        case entryDeleted(UUID)
        case entryDeleteRequested(UUID)
        case entryDeleteFailed(String)
        case clearAllRequested
        case clearAllCompleted
        case clearAllFailed(String)
    }

    @Dependency(\.roundUpRepository) private var repository
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
                        async let rule = repository.loadRule()
                        async let entries = repository.fetchEntries()
                        await send(.dataLoaded(rule: try await rule, entries: try await entries))
                    } catch {
                        await send(.loadFailed("roundUp.error.loadFailed"))
                    }
                }

            case let .dataLoaded(rule, entries):
                state.isLoading = false
                state.rule = rule
                state.entries = IdentifiedArray(uniqueElements: entries.sorted { $0.createdAt > $1.createdAt })
                state.simulatorContribution = simulate(amountText: state.simulatorAmountText, rule: rule)
                return .none

            case let .loadFailed(messageKey):
                state.isLoading = false
                state.errorMessageKey = messageKey
                return .none

            case let .toggleEnabled(isEnabled):
                var newRule = state.rule
                newRule.isEnabled = isEnabled
                state.rule = newRule
                state.isSavingRule = true
                state.simulatorContribution = simulate(
                    amountText: state.simulatorAmountText,
                    rule: newRule
                )
                return saveRuleEffect(newRule)

            case let .stepChanged(step):
                var newRule = state.rule
                newRule.step = step
                state.rule = newRule
                state.isSavingRule = true
                state.simulatorContribution = simulate(
                    amountText: state.simulatorAmountText,
                    rule: newRule
                )
                return saveRuleEffect(newRule)

            case let .ruleSaved(rule):
                state.isSavingRule = false
                state.rule = rule
                return .none

            case let .saveRuleFailed(messageKey):
                state.isSavingRule = false
                state.errorMessageKey = messageKey
                return .none

            case .simulatorOpened:
                state.isSimulatorPresented = true
                state.simulatorContribution = simulate(
                    amountText: state.simulatorAmountText,
                    rule: state.rule
                )
                return .none

            case .simulatorDismissed:
                state.isSimulatorPresented = false
                return .none

            case let .simulatorAmountChanged(text):
                state.simulatorAmountText = text
                state.simulatorContribution = simulate(amountText: text, rule: state.rule)
                return .none

            case .manualEntryOpened:
                state.isManualEntryPresented = true
                state.manualEntryAmountText = ""
                state.manualEntryNoteText = ""
                state.errorMessageKey = nil
                return .none

            case .manualEntryDismissed:
                state.isManualEntryPresented = false
                return .none

            case let .manualEntryAmountChanged(text):
                state.manualEntryAmountText = text
                state.errorMessageKey = nil
                return .none

            case let .manualEntryNoteChanged(text):
                state.manualEntryNoteText = text
                return .none

            case .manualEntrySubmitted:
                guard let amount = RoundUpAmountParser.parse(state.manualEntryAmountText), amount > 0 else {
                    state.errorMessageKey = "roundUp.error.invalidAmount"
                    return .none
                }
                let rule = state.rule.isEnabled
                    ? state.rule
                    : RoundUpRule(
                        isEnabled: true,
                        step: state.rule.step,
                        maxContributionPerTransaction: state.rule.maxContributionPerTransaction,
                        linkedSavingGoalID: state.rule.linkedSavingGoalID
                    )
                let note = state.manualEntryNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard
                    let entry = RoundUpCalculator.entry(
                        amount: amount,
                        rule: rule,
                        note: note.isEmpty ? nil : note,
                        id: uuid(),
                        createdAt: date.now
                    )
                else {
                    state.errorMessageKey = "roundUp.error.noContribution"
                    return .none
                }
                state.isManualEntryPresented = false
                return .run { send in
                    do {
                        try await repository.saveEntry(entry)
                        await send(.entryRecorded(entry))
                    } catch {
                        await send(.entrySaveFailed("roundUp.error.saveFailed"))
                    }
                }

            case let .entryRecorded(entry):
                state.entries.insert(entry, at: 0)
                return .none

            case let .entrySaveFailed(messageKey):
                state.errorMessageKey = messageKey
                return .none

            case let .entryDeleteRequested(id):
                return .run { send in
                    do {
                        try await repository.deleteEntry(id)
                        await send(.entryDeleted(id))
                    } catch {
                        await send(.entryDeleteFailed("roundUp.error.deleteFailed"))
                    }
                }

            case let .entryDeleted(id):
                state.entries.remove(id: id)
                return .none

            case let .entryDeleteFailed(messageKey):
                state.errorMessageKey = messageKey
                return .none

            case .clearAllRequested:
                return .run { send in
                    do {
                        try await repository.clearAll()
                        await send(.clearAllCompleted)
                    } catch {
                        await send(.clearAllFailed("roundUp.error.deleteFailed"))
                    }
                }

            case .clearAllCompleted:
                state.entries.removeAll()
                return .none

            case let .clearAllFailed(messageKey):
                state.errorMessageKey = messageKey
                return .none
            }
        }
    }

    private func saveRuleEffect(_ rule: RoundUpRule) -> Effect<Action> {
        .run { send in
            do {
                try await repository.saveRule(rule)
                await send(.ruleSaved(rule))
            } catch {
                await send(.saveRuleFailed("roundUp.error.saveFailed"))
            }
        }
    }

    private func simulate(amountText: String, rule: RoundUpRule) -> Decimal {
        guard let amount = RoundUpAmountParser.parse(amountText) else {
            return 0
        }
        let activeRule = rule.isEnabled
            ? rule
            : RoundUpRule(
                isEnabled: true,
                step: rule.step,
                maxContributionPerTransaction: rule.maxContributionPerTransaction
            )
        return RoundUpCalculator.contribution(amount: amount, rule: activeRule)
    }
}

public enum RoundUpAmountParser {
    public static func parse(_ text: String) -> Decimal? {
        let cleaned = text
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: " ", with: "")
        guard cleaned.isEmpty == false else {
            return nil
        }
        return Decimal(string: cleaned)
    }
}
