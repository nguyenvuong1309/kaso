import ComposableArchitecture
import Foundation
import TransactionDomain
import WellnessDomain

@Reducer
public struct HoursOfLifeFeature: Sendable {
    public static let recentTransactionsLimit: Int = 10

    @ObservableState
    public struct State: Equatable {
        public var configuration: HoursOfLifeConfiguration?
        public var recentExpenses: [Transaction]
        public var calculatorAmountText: String
        public var isLoading: Bool
        public var isSettingsPresented: Bool
        public var isSavingSettings: Bool
        public var monthlyNetIncomeText: String
        public var monthlyWorkHoursText: String
        public var settingsErrorMessageKey: String?
        public var errorMessageKey: String?

        public init(
            configuration: HoursOfLifeConfiguration? = nil,
            recentExpenses: [Transaction] = [],
            calculatorAmountText: String = "",
            isLoading: Bool = false,
            isSettingsPresented: Bool = false,
            isSavingSettings: Bool = false,
            monthlyNetIncomeText: String = "",
            monthlyWorkHoursText: String = "",
            settingsErrorMessageKey: String? = nil,
            errorMessageKey: String? = nil
        ) {
            self.configuration = configuration
            self.recentExpenses = recentExpenses
            self.calculatorAmountText = calculatorAmountText
            self.isLoading = isLoading
            self.isSettingsPresented = isSettingsPresented
            self.isSavingSettings = isSavingSettings
            self.monthlyNetIncomeText = monthlyNetIncomeText
            self.monthlyWorkHoursText = monthlyWorkHoursText
            self.settingsErrorMessageKey = settingsErrorMessageKey
            self.errorMessageKey = errorMessageKey
        }

        public var calculatorConversion: HoursOfLifeConversion? {
            guard
                let configuration,
                let amount = HoursOfLifeFeatureFormatters.parseDecimal(calculatorAmountText)
            else {
                return nil
            }
            return HoursOfLifeConverter.convert(amount: amount, configuration: configuration)
        }

        public var conversionRows: [HoursOfLifeRecentRow] {
            guard let configuration else {
                return []
            }
            return recentExpenses.compactMap { transaction in
                guard
                    let conversion = HoursOfLifeConverter.convert(
                        transaction: transaction,
                        configuration: configuration
                    )
                else {
                    return nil
                }
                return HoursOfLifeRecentRow(transaction: transaction, conversion: conversion)
            }
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case configurationLoaded(HoursOfLifeConfiguration?)
        case onboardingFallbackLoaded(Decimal?)
        case transactionsLoaded([Transaction])
        case loadFailed(String)
        case calculatorAmountChanged(String)
        case settingsButtonTapped
        case settingsDismissed
        case incomeTextChanged(String)
        case workHoursTextChanged(String)
        case saveSettingsButtonTapped
        case settingsSaved(HoursOfLifeConfiguration)
        case saveSettingsFailed(String)
    }

    @Dependency(\.hoursOfLifeConfigurationRepository) private var repository
    @Dependency(\.hoursOfLifeContextClient) private var contextClient

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                state.errorMessageKey = nil
                return .merge(
                    .run { send in
                        do {
                            let configuration = try await repository.load()
                            await send(.configurationLoaded(configuration))
                            if configuration == nil {
                                let income = try await contextClient.defaultMonthlyIncome()
                                await send(.onboardingFallbackLoaded(income))
                            }
                        } catch {
                            await send(.loadFailed("hoursOfLife.error.loadFailed"))
                        }
                    },
                    .run { send in
                        do {
                            let transactions = try await contextClient.recentTransactions()
                            await send(.transactionsLoaded(transactions))
                        } catch {
                            await send(.loadFailed("hoursOfLife.error.loadFailed"))
                        }
                    }
                )

            case let .configurationLoaded(configuration):
                state.isLoading = false
                state.configuration = configuration
                if let configuration {
                    state.monthlyNetIncomeText = HoursOfLifeFeatureFormatters
                        .amountText(configuration.monthlyNetIncome)
                    state.monthlyWorkHoursText = HoursOfLifeFeatureFormatters
                        .hoursText(configuration.averageMonthlyWorkHours)
                }
                return .none

            case let .onboardingFallbackLoaded(income):
                guard state.configuration == nil, let income, income > 0 else {
                    return .none
                }
                let fallback = HoursOfLifeConfiguration(
                    monthlyNetIncome: income,
                    averageMonthlyWorkHours: HoursOfLifeFeatureFormatters.standardMonthlyWorkHours
                )
                state.configuration = fallback
                state.monthlyNetIncomeText = HoursOfLifeFeatureFormatters
                    .amountText(fallback.monthlyNetIncome)
                state.monthlyWorkHoursText = HoursOfLifeFeatureFormatters
                    .hoursText(fallback.averageMonthlyWorkHours)
                return .none

            case let .transactionsLoaded(transactions):
                state.recentExpenses = sortedRecentExpenses(transactions)
                return .none

            case let .loadFailed(messageKey):
                state.isLoading = false
                state.errorMessageKey = messageKey
                return .none

            case let .calculatorAmountChanged(text):
                state.calculatorAmountText = text
                return .none

            case .settingsButtonTapped:
                state.isSettingsPresented = true
                state.settingsErrorMessageKey = nil
                if let configuration = state.configuration {
                    state.monthlyNetIncomeText = HoursOfLifeFeatureFormatters
                        .amountText(configuration.monthlyNetIncome)
                    state.monthlyWorkHoursText = HoursOfLifeFeatureFormatters
                        .hoursText(configuration.averageMonthlyWorkHours)
                }
                return .none

            case .settingsDismissed:
                state.isSettingsPresented = false
                state.settingsErrorMessageKey = nil
                return .none

            case let .incomeTextChanged(text):
                state.monthlyNetIncomeText = text
                state.settingsErrorMessageKey = nil
                return .none

            case let .workHoursTextChanged(text):
                state.monthlyWorkHoursText = text
                state.settingsErrorMessageKey = nil
                return .none

            case .saveSettingsButtonTapped:
                return saveSettingsEffect(&state)

            case let .settingsSaved(configuration):
                state.isSavingSettings = false
                state.isSettingsPresented = false
                state.configuration = configuration
                state.monthlyNetIncomeText = HoursOfLifeFeatureFormatters
                    .amountText(configuration.monthlyNetIncome)
                state.monthlyWorkHoursText = HoursOfLifeFeatureFormatters
                    .hoursText(configuration.averageMonthlyWorkHours)
                state.settingsErrorMessageKey = nil
                return .none

            case let .saveSettingsFailed(messageKey):
                state.isSavingSettings = false
                state.settingsErrorMessageKey = messageKey
                return .none
            }
        }
    }

    private func saveSettingsEffect(_ state: inout State) -> Effect<Action> {
        guard
            let income = HoursOfLifeFeatureFormatters.parseDecimal(state.monthlyNetIncomeText)
        else {
            state.settingsErrorMessageKey = "hoursOfLife.error.invalidIncome"
            return .none
        }
        guard
            let workHours = HoursOfLifeFeatureFormatters.parseDecimal(state.monthlyWorkHoursText)
        else {
            state.settingsErrorMessageKey = "hoursOfLife.error.invalidWorkHours"
            return .none
        }

        let draft = HoursOfLifeConfigurationDraft(
            monthlyNetIncome: income,
            averageMonthlyWorkHours: workHours
        )

        do {
            let configuration = try draft.validated()
            state.isSavingSettings = true
            return .run { send in
                do {
                    try await repository.save(configuration)
                    await send(.settingsSaved(configuration))
                } catch {
                    await send(.saveSettingsFailed("hoursOfLife.error.saveFailed"))
                }
            }
        } catch let error as HoursOfLifeConfigurationValidationError {
            state.settingsErrorMessageKey = error.messageKey
            return .none
        } catch {
            state.settingsErrorMessageKey = "hoursOfLife.error.saveFailed"
            return .none
        }
    }

    private func sortedRecentExpenses(_ transactions: [Transaction]) -> [Transaction] {
        transactions
            .filter { $0.kind == .expense && $0.amount > 0 }
            .sorted { $0.occurredAt > $1.occurredAt }
            .prefix(Self.recentTransactionsLimit)
            .map { $0 }
    }
}

public struct HoursOfLifeRecentRow: Identifiable, Equatable, Sendable {
    public let transaction: Transaction
    public let conversion: HoursOfLifeConversion

    public var id: UUID {
        transaction.id
    }

    public init(transaction: Transaction, conversion: HoursOfLifeConversion) {
        self.transaction = transaction
        self.conversion = conversion
    }
}
