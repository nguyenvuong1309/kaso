import Foundation
import ComposableArchitecture
import BudgetDomain
import GoalDomain
import InsightDomain
import SubscriptionDomain
import TransactionDomain
import WellnessDomain

public enum TransactionHistoryScope: String, CaseIterable, Equatable, Identifiable, Sendable {
    case all
    case day
    case week
    case month

    public var id: String {
        rawValue
    }

    public var nameKey: String {
        "transactions.history.scope.\(rawValue)"
    }

    func contains(
        _ date: Date,
        referenceDate: Date,
        calendar: Calendar = .current
    ) -> Bool {
        switch self {
        case .all:
            true
        case .day:
            calendar.isDate(date, inSameDayAs: referenceDate)
        case .week:
            calendar.isDate(date, equalTo: referenceDate, toGranularity: .weekOfYear)
        case .month:
            calendar.isDate(date, equalTo: referenceDate, toGranularity: .month)
        }
    }
}

public enum CustomCategoryOption: String, CaseIterable, Equatable, Identifiable, Sendable {
    case coffee
    case groceries
    case gift
    case pet
    case travel

    public var id: String {
        rawValue
    }

    public var symbolName: String {
        switch self {
        case .coffee:
            "cup.and.saucer"
        case .groceries:
            "cart"
        case .gift:
            "gift"
        case .pet:
            "pawprint"
        case .travel:
            "airplane"
        }
    }

    public var nameKey: String {
        "transactions.category.option.\(rawValue)"
    }

    public var colorName: String {
        switch self {
        case .coffee:
            "brown"
        case .groceries:
            "green"
        case .gift:
            "pink"
        case .pet:
            "orange"
        case .travel:
            "blue"
        }
    }
}

public struct TransactionCSVExport: Equatable, Sendable {
    public let fileName: String
    public let csvText: String
    public let transactionCount: Int

    public init(
        fileName: String,
        csvText: String,
        transactionCount: Int
    ) {
        self.fileName = fileName
        self.csvText = csvText
        self.transactionCount = transactionCount
    }
}

public struct BankStatementImportSummary: Equatable, Sendable {
    public let importedCount: Int
    public let skippedLineCount: Int
    public let totalLineCount: Int

    public init(
        importedCount: Int,
        skippedLineCount: Int,
        totalLineCount: Int
    ) {
        self.importedCount = importedCount
        self.skippedLineCount = skippedLineCount
        self.totalLineCount = totalLineCount
    }
}

public struct SavingGoalSpendingImpact: Identifiable, Equatable, Sendable {
    public let id: String
    public var goal: SavingGoal
    public var budget: Budget
    public var overageAmount: Decimal
    public var delayedDayCount: Int

    public init(
        goal: SavingGoal,
        budget: Budget,
        overageAmount: Decimal,
        delayedDayCount: Int
    ) {
        id = "\(goal.id.uuidString)-\(budget.category.id)"
        self.goal = goal
        self.budget = budget
        self.overageAmount = overageAmount
        self.delayedDayCount = delayedDayCount
    }
}

@Reducer
public struct TransactionFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var transactions: IdentifiedArrayOf<Transaction>
        public var summary: MonthlyTransactionSummary
        public var categorySpendings: [MonthlyCategorySpending]
        public var budgets: [Budget]
        public var savingGoals: IdentifiedArrayOf<SavingGoal>
        public var customCategories: [TransactionCategory]
        public var historyReferenceDate: Date
        public var historyScope: TransactionHistoryScope
        public var searchText: String
        public var selectedCategoryID: String?
        public var isLoading: Bool
        public var isSaving: Bool
        public var isBudgetSaving: Bool
        public var isSavingGoalSaving: Bool
        public var isCategorySaving: Bool
        public var isReceiptImageSaving: Bool
        public var isReceiptOCRProcessing: Bool
        public var isBankStatementImporterPresented: Bool
        public var isBankStatementImporting: Bool
        public var isVoiceInputRecording: Bool
        public var subscriptionRenewalReminderCount: Int
        public var isAddSheetPresented: Bool
        public var isBudgetEditorPresented: Bool
        public var isSavingGoalEditorPresented: Bool
        public var isCategoryEditorPresented: Bool
        public var amountText: String
        public var budgetLimitText: String
        public var savingGoalNameText: String
        public var savingGoalTargetAmountText: String
        public var savingGoalCurrentAmountText: String
        public var savingGoalDeadline: Date
        public var retirementAnnualReturnPercentText: String
        public var retirementTargetMultiplierText: String
        public var categoryNameText: String
        public var categoryOption: CustomCategoryOption
        public var editingBudgetCategory: TransactionCategory?
        public var editingSavingGoalID: UUID?
        public var draftKind: TransactionKind
        public var draftCategory: TransactionCategory
        public var draftOccurredAt: Date
        public var draftNote: String
        public var draftReceiptImageIdentifier: String?
        public var receiptOCRResult: ReceiptOCRResult?
        public var bankStatementImportSummary: BankStatementImportSummary?
        public var bankStatementImportErrorMessageKey: String?
        public var voiceInputTranscript: String?
        public var voiceInputErrorMessageKey: String?
        public var subscriptionRenewalReminderErrorMessageKey: String?
        public var budgetEditorErrorMessageKey: String?
        public var savingGoalEditorErrorMessageKey: String?
        public var categoryEditorErrorMessageKey: String?
        public var errorMessageKey: String?
        public var formErrorMessageKey: String?

        public init(
            transactions: IdentifiedArrayOf<Transaction> = [],
            summary: MonthlyTransactionSummary = .empty,
            categorySpendings: [MonthlyCategorySpending] = [],
            budgets: [Budget] = [],
            savingGoals: IdentifiedArrayOf<SavingGoal> = [],
            customCategories: [TransactionCategory] = [],
            historyReferenceDate: Date = Date(timeIntervalSinceReferenceDate: 0),
            historyScope: TransactionHistoryScope = .all,
            searchText: String = "",
            selectedCategoryID: String? = nil,
            isLoading: Bool = false,
            isSaving: Bool = false,
            isBudgetSaving: Bool = false,
            isSavingGoalSaving: Bool = false,
            isCategorySaving: Bool = false,
            isReceiptImageSaving: Bool = false,
            isReceiptOCRProcessing: Bool = false,
            isBankStatementImporterPresented: Bool = false,
            isBankStatementImporting: Bool = false,
            isVoiceInputRecording: Bool = false,
            subscriptionRenewalReminderCount: Int = 0,
            isAddSheetPresented: Bool = false,
            isBudgetEditorPresented: Bool = false,
            isSavingGoalEditorPresented: Bool = false,
            isCategoryEditorPresented: Bool = false,
            amountText: String = "",
            budgetLimitText: String = "",
            savingGoalNameText: String = "",
            savingGoalTargetAmountText: String = "",
            savingGoalCurrentAmountText: String = "",
            savingGoalDeadline: Date = Date(timeIntervalSinceReferenceDate: 0),
            retirementAnnualReturnPercentText: String = "5",
            retirementTargetMultiplierText: String = "25",
            categoryNameText: String = "",
            categoryOption: CustomCategoryOption = .coffee,
            editingBudgetCategory: TransactionCategory? = nil,
            editingSavingGoalID: UUID? = nil,
            draftKind: TransactionKind = .expense,
            draftCategory: TransactionCategory = .food,
            draftOccurredAt: Date = Date(timeIntervalSinceReferenceDate: 0),
            draftNote: String = "",
            draftReceiptImageIdentifier: String? = nil,
            receiptOCRResult: ReceiptOCRResult? = nil,
            bankStatementImportSummary: BankStatementImportSummary? = nil,
            bankStatementImportErrorMessageKey: String? = nil,
            voiceInputTranscript: String? = nil,
            voiceInputErrorMessageKey: String? = nil,
            subscriptionRenewalReminderErrorMessageKey: String? = nil,
            budgetEditorErrorMessageKey: String? = nil,
            savingGoalEditorErrorMessageKey: String? = nil,
            categoryEditorErrorMessageKey: String? = nil,
            errorMessageKey: String? = nil,
            formErrorMessageKey: String? = nil
        ) {
            self.transactions = transactions
            self.summary = summary
            self.categorySpendings = categorySpendings
            self.budgets = budgets
            self.savingGoals = savingGoals
            self.customCategories = customCategories
            self.historyReferenceDate = historyReferenceDate
            self.historyScope = historyScope
            self.searchText = searchText
            self.selectedCategoryID = selectedCategoryID
            self.isLoading = isLoading
            self.isSaving = isSaving
            self.isBudgetSaving = isBudgetSaving
            self.isSavingGoalSaving = isSavingGoalSaving
            self.isCategorySaving = isCategorySaving
            self.isReceiptImageSaving = isReceiptImageSaving
            self.isReceiptOCRProcessing = isReceiptOCRProcessing
            self.isBankStatementImporterPresented = isBankStatementImporterPresented
            self.isBankStatementImporting = isBankStatementImporting
            self.isVoiceInputRecording = isVoiceInputRecording
            self.subscriptionRenewalReminderCount = subscriptionRenewalReminderCount
            self.isAddSheetPresented = isAddSheetPresented
            self.isBudgetEditorPresented = isBudgetEditorPresented
            self.isSavingGoalEditorPresented = isSavingGoalEditorPresented
            self.isCategoryEditorPresented = isCategoryEditorPresented
            self.amountText = amountText
            self.budgetLimitText = budgetLimitText
            self.savingGoalNameText = savingGoalNameText
            self.savingGoalTargetAmountText = savingGoalTargetAmountText
            self.savingGoalCurrentAmountText = savingGoalCurrentAmountText
            self.savingGoalDeadline = savingGoalDeadline
            self.retirementAnnualReturnPercentText = retirementAnnualReturnPercentText
            self.retirementTargetMultiplierText = retirementTargetMultiplierText
            self.categoryNameText = categoryNameText
            self.categoryOption = categoryOption
            self.editingBudgetCategory = editingBudgetCategory
            self.editingSavingGoalID = editingSavingGoalID
            self.draftKind = draftKind
            self.draftCategory = draftCategory
            self.draftOccurredAt = draftOccurredAt
            self.draftNote = draftNote
            self.draftReceiptImageIdentifier = draftReceiptImageIdentifier
            self.receiptOCRResult = receiptOCRResult
            self.bankStatementImportSummary = bankStatementImportSummary
            self.bankStatementImportErrorMessageKey = bankStatementImportErrorMessageKey
            self.voiceInputTranscript = voiceInputTranscript
            self.voiceInputErrorMessageKey = voiceInputErrorMessageKey
            self.subscriptionRenewalReminderErrorMessageKey = subscriptionRenewalReminderErrorMessageKey
            self.budgetEditorErrorMessageKey = budgetEditorErrorMessageKey
            self.savingGoalEditorErrorMessageKey = savingGoalEditorErrorMessageKey
            self.categoryEditorErrorMessageKey = categoryEditorErrorMessageKey
            self.errorMessageKey = errorMessageKey
            self.formErrorMessageKey = formErrorMessageKey
        }

        public var filterCategories: [TransactionCategory] {
            Self.uniqueCategories(
                TransactionCategory.defaultExpenseCategories
                    + TransactionCategory.defaultIncomeCategories
                    + customCategories
            )
        }

        public func categories(for kind: TransactionKind) -> [TransactionCategory] {
            switch kind {
            case .income:
                TransactionCategory.defaultIncomeCategories
            case .expense:
                Self.uniqueCategories(
                    TransactionCategory.defaultExpenseCategories + customCategories
                )
            }
        }

        public var draftCategories: [TransactionCategory] {
            categories(for: draftKind)
        }

        public var filteredTransactions: [Transaction] {
            let normalizedQuery = searchText.normalizedForTransactionSearch

            return transactions.filter { transaction in
                let matchesCategory = selectedCategoryID == nil
                    || transaction.category.id == selectedCategoryID
                let matchesScope = historyScope.contains(
                    transaction.occurredAt,
                    referenceDate: historyReferenceDate
                )
                let matchesSearch = normalizedQuery.isEmpty
                    || transaction.matchesSearch(normalizedQuery)

                return matchesCategory && matchesScope && matchesSearch
            }
        }

        public var subscriptionDetectionResult: SubscriptionDetectionResult {
            SubscriptionDetector().detect(
                from: Array(transactions),
                referenceDate: historyReferenceDate
            )
        }

        public var spendingAnomalies: [SpendingAnomaly] {
            SpendingAnomalyDetector.detect(
                transactions: Array(transactions),
                currentDate: historyReferenceDate
            )
        }

        public var spendingReductionSuggestions: [SpendingReductionSuggestion] {
            SpendingReductionSuggestionEngine.suggestions(
                transactions: Array(transactions),
                referenceDate: historyReferenceDate
            )
        }

        public var monthlyBalanceForecast: MonthlyBalanceForecast {
            MonthlyBalanceForecaster.forecast(
                transactions: Array(transactions),
                referenceDate: historyReferenceDate
            )
        }

        public var timeSpendingAnalysis: TimeSpendingAnalysis {
            TimeSpendingAnalyzer.analyze(
                transactions: Array(transactions),
                referenceDate: historyReferenceDate
            )
        }

        public var noSpendSummary: NoSpendSummary {
            NoSpendDayTracker.monthSummary(
                from: Array(transactions),
                containing: historyReferenceDate
            )
        }

        public var csvExport: TransactionCSVExport {
            TransactionCSVExport(
                fileName: "kaso-transactions-\(Self.exportDateString(historyReferenceDate)).csv",
                csvText: TransactionCSVExporter.export(Array(transactions)),
                transactionCount: transactions.count
            )
        }

        public var editingSavingGoal: SavingGoal? {
            guard let editingSavingGoalID else {
                return nil
            }

            return savingGoals[id: editingSavingGoalID]
        }

        public var savingGoalSpendingImpacts: [SavingGoalSpendingImpact] {
            guard let goal = savingGoals.first(where: {
                let status = $0.status(on: historyReferenceDate)
                return status == .notStarted || status == .inProgress
            }) else {
                return []
            }

            return budgets
                .filter { $0.status == .exceeded }
                .compactMap { budget -> SavingGoalSpendingImpact? in
                    let overageAmount = budget.spent - budget.monthlyLimit
                    let delayedDayCount = SavingGoalDelayEstimator.delayedDayCount(
                        overageAmount: overageAmount,
                        goal: goal,
                        asOf: historyReferenceDate
                    )
                    guard delayedDayCount > 0 else {
                        return nil
                    }

                    return SavingGoalSpendingImpact(
                        goal: goal,
                        budget: budget,
                        overageAmount: overageAmount,
                        delayedDayCount: delayedDayCount
                    )
                }
                .sorted { $0.overageAmount > $1.overageAmount }
        }

        public var emergencyFundGoal: SavingGoal? {
            savingGoals.first { $0.name.isEmergencyFundGoalName }
        }

        public var emergencyFundRecommendation: EmergencyFundRecommendation? {
            EmergencyFundPlanner.recommendation(
                monthlyExpense: Self.averageMonthlyExpense(
                    transactions: Array(transactions),
                    referenceDate: historyReferenceDate
                ),
                currentAmount: emergencyFundGoal?.currentAmount ?? 0
            )
        }

        public var retirementSimulation: RetirementSimulation? {
            guard
                let annualReturnPercent = Decimal.inputValue(retirementAnnualReturnPercentText),
                let targetMultiplier = Int(retirementTargetMultiplierText),
                targetMultiplier > 0
            else {
                return nil
            }

            return RetirementSimulator.simulate(
                monthlyIncome: Self.averageMonthlyIncome(
                    transactions: Array(transactions),
                    referenceDate: historyReferenceDate
                ),
                monthlyExpense: Self.averageMonthlyExpense(
                    transactions: Array(transactions),
                    referenceDate: historyReferenceDate
                ),
                currentSavings: savingGoals.reduce(0) { $0 + $1.currentAmount },
                annualReturnRate: annualReturnPercent / 100,
                targetAnnualExpenseMultiplier: targetMultiplier
            )
        }

        public var spendingComparisonReport: SpendingComparisonReport {
            SpendingComparisonReporter.report(
                transactions: Array(transactions),
                referenceDate: historyReferenceDate
            )
        }

        private static func uniqueCategories(
            _ categories: [TransactionCategory]
        ) -> [TransactionCategory] {
            var seenCategoryIDs: Set<String> = []
            return categories.filter { category in
                seenCategoryIDs.insert(category.id).inserted
            }
        }

        private static func exportDateString(_ date: Date) -> String {
            let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
            let year = components.year ?? 0
            let month = components.month ?? 0
            let day = components.day ?? 0
            return String(format: "%04d-%02d-%02d", year, month, day)
        }

        private static func averageMonthlyExpense(
            transactions: [Transaction],
            referenceDate: Date,
            calendar: Calendar = .current,
            monthCount: Int = 3
        ) -> Decimal {
            averageMonthlyAmount(
                transactions: transactions,
                referenceDate: referenceDate,
                kind: .expense,
                calendar: calendar,
                monthCount: monthCount
            )
        }

        private static func averageMonthlyIncome(
            transactions: [Transaction],
            referenceDate: Date,
            calendar: Calendar = .current,
            monthCount: Int = 3
        ) -> Decimal {
            averageMonthlyAmount(
                transactions: transactions,
                referenceDate: referenceDate,
                kind: .income,
                calendar: calendar,
                monthCount: monthCount
            )
        }

        private static func averageMonthlyAmount(
            transactions: [Transaction],
            referenceDate: Date,
            kind: TransactionKind,
            calendar: Calendar,
            monthCount: Int
        ) -> Decimal {
            guard
                monthCount > 0,
                let currentMonth = calendar.dateInterval(of: .month, for: referenceDate),
                let startDate = calendar.date(
                    byAdding: .month,
                    value: -(monthCount - 1),
                    to: currentMonth.start
                )
            else {
                return 0
            }

            let monthlyTotals = transactions.reduce(into: [:]) { result, transaction in
                guard
                    transaction.kind == kind,
                    transaction.occurredAt >= startDate,
                    transaction.occurredAt <= referenceDate,
                    let month = calendar.dateInterval(of: .month, for: transaction.occurredAt)
                else {
                    return
                }

                result[month.start, default: 0] += transaction.amount
            } as [Date: Decimal]

            guard monthlyTotals.isEmpty == false else {
                return 0
            }

            return monthlyTotals.values.reduce(0, +) / Decimal(monthlyTotals.count)
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case transactionsLoaded([Transaction])
        case loadFailed(String)
        case addButtonTapped
        case addSheetDismissed
        case amountTextChanged(String)
        case kindChanged(TransactionKind)
        case categoryChanged(TransactionCategory)
        case occurredAtChanged(Date)
        case noteChanged(String)
        case saveButtonTapped
        case saveDraft(TransactionDraft)
        case transactionSaved(Transaction)
        case saveFailed(String)
        case budgetsUpdated([Budget])
        case budgetsLoaded([Budget])
        case budgetEditButtonTapped(Budget)
        case budgetEditorDismissed
        case budgetLimitTextChanged(String)
        case budgetSaveButtonTapped
        case budgetsSaved([Budget])
        case budgetSaveFailed(String)
        case savingGoalsLoaded([SavingGoal])
        case savingGoalsLoadFailed(String)
        case savingGoalAddButtonTapped
        case savingGoalEditButtonTapped(SavingGoal)
        case savingGoalEditorDismissed
        case savingGoalNameTextChanged(String)
        case savingGoalTargetAmountTextChanged(String)
        case savingGoalCurrentAmountTextChanged(String)
        case savingGoalDeadlineChanged(Date)
        case savingGoalSaveButtonTapped
        case savingGoalSaved(SavingGoal)
        case savingGoalSaveFailed(String)
        case savingGoalDeleteButtonTapped(SavingGoal)
        case savingGoalDeleted(UUID)
        case savingGoalDeleteFailed(String)
        case emergencyFundGoalButtonTapped
        case retirementAnnualReturnPercentTextChanged(String)
        case retirementTargetMultiplierTextChanged(String)
        case customCategoriesLoaded([TransactionCategory])
        case categoryAddButtonTapped
        case categoryEditorDismissed
        case categoryNameTextChanged(String)
        case categoryOptionChanged(CustomCategoryOption)
        case categorySaveButtonTapped
        case customCategoriesSaved([TransactionCategory], TransactionCategory)
        case categorySaveFailed(String)
        case searchTextChanged(String)
        case historyScopeChanged(TransactionHistoryScope)
        case categoryFilterChanged(String?)
        case receiptImageDataSelected(Data)
        case receiptImageSaved(String)
        case receiptImageSaveFailed(String)
        case receiptOCRRecognized(ReceiptOCRResult)
        case receiptOCRFailed(String)
        case receiptImageRemoved
        case bankStatementImportButtonTapped
        case bankStatementImporterDismissed
        case bankStatementPDFDataSelected(Data)
        case bankStatementImported([Transaction], BankStatementImportSummary)
        case bankStatementImportFailed(String)
        case subscriptionRenewalRemindersScheduled(Int)
        case subscriptionRenewalReminderSchedulingFailed(String)
        case voiceInputButtonTapped
        case voiceInputTranscriptRecognized(String)
        case voiceInputFailed(String)
    }

    @Dependency(\.bankStatementPDFClient) private var bankStatementPDFClient
    @Dependency(\.budgetRepository) private var budgetRepository
    @Dependency(\.date.now) private var now
    @Dependency(\.receiptImageRepository) private var receiptImageRepository
    @Dependency(\.receiptOCRClient) private var receiptOCRClient
    @Dependency(\.savingGoalRepository) private var savingGoalRepository
    @Dependency(\.subscriptionNotificationClient) private var subscriptionNotificationClient
    @Dependency(\.transactionCategoryRepository) private var categoryRepository
    @Dependency(\.transactionRepository) private var repository
    @Dependency(\.uuid) private var uuid
    @Dependency(\.voiceInputClient) private var voiceInputClient

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.historyReferenceDate = now
                state.isLoading = true
                state.errorMessageKey = nil

                return .run { send in
                    do {
                        let transactions = try await repository.fetchAll()
                        await send(.transactionsLoaded(transactions))
                    } catch {
                        await send(.loadFailed("transactions.error.loadFailed"))
                    }

                    do {
                        let budgets = try await budgetRepository.fetchAll()
                        if budgets.isEmpty == false {
                            await send(.budgetsLoaded(budgets))
                        }
                    } catch {
                        await send(.budgetSaveFailed("transactions.budget.error.loadFailed"))
                    }

                    do {
                        let goals = try await savingGoalRepository.fetchAll()
                        if goals.isEmpty == false {
                            await send(.savingGoalsLoaded(goals))
                        }
                    } catch {
                        await send(.savingGoalsLoadFailed("transactions.goal.error.loadFailed"))
                    }

                    do {
                        let categories = try await categoryRepository.fetchCustomCategories()
                        if categories.isEmpty == false {
                            await send(.customCategoriesLoaded(categories))
                        }
                    } catch {
                        await send(.categorySaveFailed("transactions.category.error.loadFailed"))
                    }
                }

            case let .transactionsLoaded(transactions):
                state.isLoading = false
                state.transactions = IdentifiedArray(
                    uniqueElements: transactions.sorted { $0.occurredAt > $1.occurredAt }
                )
                updateDashboard(&state)
                return scheduleSubscriptionRenewalReminders(for: state)

            case let .loadFailed(messageKey):
                state.isLoading = false
                state.errorMessageKey = messageKey
                return .none

            case .addButtonTapped:
                resetForm(&state, occurredAt: now)
                state.isAddSheetPresented = true
                return .none

            case .addSheetDismissed:
                state.isAddSheetPresented = false
                state.formErrorMessageKey = nil
                return .none

            case let .amountTextChanged(amountText):
                state.amountText = TransactionAmountFormatter.formatForEditing(amountText)
                state.formErrorMessageKey = nil
                return .none

            case let .kindChanged(kind):
                state.draftKind = kind
                state.draftCategory = state.categories(for: kind).first
                    ?? TransactionCategory.defaultCategory(for: kind)
                state.formErrorMessageKey = nil
                return .none

            case let .categoryChanged(category):
                guard state.categories(for: state.draftKind).contains(category) else {
                    return .none
                }

                state.draftCategory = category
                state.formErrorMessageKey = nil
                return .none

            case let .occurredAtChanged(date):
                state.draftOccurredAt = date
                return .none

            case let .noteChanged(note):
                state.draftNote = note
                return .none

            case .saveButtonTapped:
                guard let amount = TransactionAmountParser.parse(state.amountText) else {
                    state.formErrorMessageKey = "transactions.add.error.invalidAmount"
                    return .none
                }

                let note = state.draftNote
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let draft = TransactionDraft(
                    amount: amount,
                    kind: state.draftKind,
                    category: state.draftCategory,
                    occurredAt: state.draftOccurredAt,
                    note: note.isEmpty ? nil : note,
                    receiptImageIdentifier: state.draftReceiptImageIdentifier
                )
                return save(draft, state: &state)

            case let .saveDraft(draft):
                return save(draft, state: &state)

            case let .transactionSaved(transaction):
                state.isSaving = false
                state.isAddSheetPresented = false
                insert(transaction, into: &state)
                resetForm(&state, occurredAt: now)
                updateDashboard(&state)
                return scheduleSubscriptionRenewalReminders(for: state)

            case let .saveFailed(messageKey):
                state.isSaving = false
                state.errorMessageKey = messageKey
                state.formErrorMessageKey = messageKey
                return .none

            case let .budgetsUpdated(budgets):
                state.budgets = budgets.applyingMonthlySpending(
                    from: Array(state.transactions),
                    containing: now
                )
                return .none

            case let .budgetsLoaded(budgets):
                state.budgets = budgets.applyingMonthlySpending(
                    from: Array(state.transactions),
                    containing: now
                )
                return .none

            case let .budgetEditButtonTapped(budget):
                state.editingBudgetCategory = budget.category
                state.budgetLimitText = TransactionAmountFormatter.formatForEditing(
                    budget.monthlyLimit.description
                )
                state.budgetEditorErrorMessageKey = nil
                state.isBudgetEditorPresented = true
                return .none

            case .budgetEditorDismissed:
                resetBudgetEditor(&state)
                return .none

            case let .budgetLimitTextChanged(text):
                state.budgetLimitText = TransactionAmountFormatter.formatForEditing(text)
                state.budgetEditorErrorMessageKey = nil
                return .none

            case .budgetSaveButtonTapped:
                guard let category = state.editingBudgetCategory else {
                    return .none
                }

                guard let monthlyLimit = TransactionAmountParser.parse(state.budgetLimitText),
                      monthlyLimit > 0
                else {
                    state.budgetEditorErrorMessageKey = "transactions.budget.edit.error.invalidLimit"
                    return .none
                }

                let budgets = updatingBudgets(
                    state.budgets,
                    category: category,
                    monthlyLimit: monthlyLimit
                )
                let budgetsToSave = budgets.map {
                    Budget(category: $0.category, monthlyLimit: $0.monthlyLimit)
                }

                state.isBudgetSaving = true
                state.budgetEditorErrorMessageKey = nil

                return .run { send in
                    do {
                        try await budgetRepository.saveAll(budgetsToSave)
                        await send(.budgetsSaved(budgetsToSave))
                    } catch {
                        await send(.budgetSaveFailed("transactions.budget.error.saveFailed"))
                    }
                }

            case let .budgetsSaved(budgets):
                state.isBudgetSaving = false
                state.budgets = budgets.applyingMonthlySpending(
                    from: Array(state.transactions),
                    containing: now
                )
                resetBudgetEditor(&state)
                return .none

            case let .budgetSaveFailed(messageKey):
                state.isBudgetSaving = false
                state.budgetEditorErrorMessageKey = messageKey
                return .none

            case let .savingGoalsLoaded(goals):
                state.savingGoals = IdentifiedArray(uniqueElements: goals.sorted { $0.deadline < $1.deadline })
                return .none

            case let .savingGoalsLoadFailed(messageKey):
                state.errorMessageKey = messageKey
                return .none

            case .savingGoalAddButtonTapped:
                resetSavingGoalEditor(&state, deadline: defaultSavingGoalDeadline(from: now))
                state.isSavingGoalEditorPresented = true
                return .none

            case let .savingGoalEditButtonTapped(goal):
                state.editingSavingGoalID = goal.id
                state.savingGoalNameText = goal.name
                state.savingGoalTargetAmountText = TransactionAmountFormatter.formatForEditing(
                    goal.targetAmount.description
                )
                state.savingGoalCurrentAmountText = TransactionAmountFormatter.formatForEditing(
                    goal.currentAmount.description
                )
                state.savingGoalDeadline = goal.deadline
                state.savingGoalEditorErrorMessageKey = nil
                state.isSavingGoalEditorPresented = true
                return .none

            case .savingGoalEditorDismissed:
                resetSavingGoalEditor(&state, deadline: defaultSavingGoalDeadline(from: now))
                return .none

            case let .savingGoalNameTextChanged(text):
                state.savingGoalNameText = text
                state.savingGoalEditorErrorMessageKey = nil
                return .none

            case let .savingGoalTargetAmountTextChanged(text):
                state.savingGoalTargetAmountText = TransactionAmountFormatter.formatForEditing(text)
                state.savingGoalEditorErrorMessageKey = nil
                return .none

            case let .savingGoalCurrentAmountTextChanged(text):
                state.savingGoalCurrentAmountText = TransactionAmountFormatter.formatForEditing(text)
                state.savingGoalEditorErrorMessageKey = nil
                return .none

            case let .savingGoalDeadlineChanged(date):
                state.savingGoalDeadline = date
                state.savingGoalEditorErrorMessageKey = nil
                return .none

            case .savingGoalSaveButtonTapped:
                return saveSavingGoal(state: &state)

            case let .savingGoalSaved(goal):
                state.isSavingGoalSaving = false
                upsert(goal, into: &state)
                resetSavingGoalEditor(&state, deadline: defaultSavingGoalDeadline(from: now))
                return .none

            case let .savingGoalSaveFailed(messageKey):
                state.isSavingGoalSaving = false
                state.savingGoalEditorErrorMessageKey = messageKey
                return .none

            case let .savingGoalDeleteButtonTapped(goal):
                state.isSavingGoalSaving = true
                state.savingGoalEditorErrorMessageKey = nil
                return .run { send in
                    do {
                        try await savingGoalRepository.delete(goal.id)
                        await send(.savingGoalDeleted(goal.id))
                    } catch {
                        await send(.savingGoalDeleteFailed("transactions.goal.error.deleteFailed"))
                    }
                }

            case let .savingGoalDeleted(id):
                state.isSavingGoalSaving = false
                state.savingGoals.remove(id: id)
                resetSavingGoalEditor(&state, deadline: defaultSavingGoalDeadline(from: now))
                return .none

            case let .savingGoalDeleteFailed(messageKey):
                state.isSavingGoalSaving = false
                state.savingGoalEditorErrorMessageKey = messageKey
                return .none

            case .emergencyFundGoalButtonTapped:
                guard let recommendation = state.emergencyFundRecommendation else {
                    return .none
                }

                if let goal = state.emergencyFundGoal {
                    state.editingSavingGoalID = goal.id
                    state.savingGoalNameText = goal.name
                    state.savingGoalTargetAmountText = TransactionAmountFormatter.formatForEditing(
                        goal.targetAmount.description
                    )
                    state.savingGoalCurrentAmountText = TransactionAmountFormatter.formatForEditing(
                        goal.currentAmount.description
                    )
                    state.savingGoalDeadline = goal.deadline
                } else {
                    resetSavingGoalEditor(
                        &state,
                        deadline: emergencyFundGoalDeadline(from: now)
                    )
                    state.savingGoalNameText = "Quỹ khẩn cấp"
                    state.savingGoalTargetAmountText = TransactionAmountFormatter.formatForEditing(
                        recommendation.recommendedAmount.description
                    )
                    state.savingGoalCurrentAmountText = TransactionAmountFormatter.formatForEditing(
                        recommendation.currentAmount.description
                    )
                }
                state.savingGoalEditorErrorMessageKey = nil
                state.isSavingGoalEditorPresented = true
                return .none

            case let .retirementAnnualReturnPercentTextChanged(text):
                state.retirementAnnualReturnPercentText = text
                return .none

            case let .retirementTargetMultiplierTextChanged(text):
                state.retirementTargetMultiplierText = text
                return .none

            case let .searchTextChanged(searchText):
                state.searchText = searchText
                return .none

            case let .historyScopeChanged(scope):
                state.historyScope = scope
                state.historyReferenceDate = now
                return .none

            case let .categoryFilterChanged(categoryID):
                if let categoryID,
                   state.filterCategories.contains(where: { $0.id == categoryID }) == false {
                    return .none
                }

                state.selectedCategoryID = categoryID
                return .none

            case let .customCategoriesLoaded(categories):
                state.customCategories = categories
                return .none

            case .categoryAddButtonTapped:
                resetCategoryEditor(&state)
                state.isCategoryEditorPresented = true
                return .none

            case .categoryEditorDismissed:
                resetCategoryEditor(&state)
                return .none

            case let .categoryNameTextChanged(text):
                state.categoryNameText = text
                state.categoryEditorErrorMessageKey = nil
                return .none

            case let .categoryOptionChanged(option):
                state.categoryOption = option
                state.categoryEditorErrorMessageKey = nil
                return .none

            case .categorySaveButtonTapped:
                let name = state.categoryNameText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard name.isEmpty == false else {
                    state.categoryEditorErrorMessageKey = "transactions.category.error.nameRequired"
                    return .none
                }

                let normalizedName = name.normalizedForCategoryID
                guard normalizedName.isEmpty == false else {
                    state.categoryEditorErrorMessageKey = "transactions.category.error.nameRequired"
                    return .none
                }

                let categoryID = "custom-\(normalizedName)"
                guard state.filterCategories.contains(where: { $0.id == categoryID }) == false else {
                    state.categoryEditorErrorMessageKey = "transactions.category.error.duplicate"
                    return .none
                }

                let category = TransactionCategory(
                    id: categoryID,
                    nameKey: name,
                    symbolName: state.categoryOption.symbolName,
                    colorName: state.categoryOption.colorName
                )
                let categories = (state.customCategories + [category])
                    .sorted { $0.nameKey < $1.nameKey }

                state.isCategorySaving = true
                state.categoryEditorErrorMessageKey = nil

                return .run { send in
                    do {
                        try await categoryRepository.saveCustomCategories(categories)
                        await send(.customCategoriesSaved(categories, category))
                    } catch {
                        await send(.categorySaveFailed("transactions.category.error.saveFailed"))
                    }
                }

            case let .customCategoriesSaved(categories, category):
                state.customCategories = categories
                state.draftKind = .expense
                state.draftCategory = category
                resetCategoryEditor(&state)
                return .none

            case let .categorySaveFailed(messageKey):
                state.isCategorySaving = false
                state.categoryEditorErrorMessageKey = messageKey
                return .none

            case let .receiptImageDataSelected(data):
                guard data.isEmpty == false else {
                    return .none
                }

                state.isReceiptImageSaving = true
                state.isReceiptOCRProcessing = true
                state.receiptOCRResult = nil
                state.formErrorMessageKey = nil

                return .run { send in
                    do {
                        let identifier = try await receiptImageRepository.save(data)
                        await send(.receiptImageSaved(identifier))
                    } catch {
                        await send(.receiptImageSaveFailed("transactions.add.receipt.error.saveFailed"))
                        return
                    }

                    do {
                        let result = try await receiptOCRClient.recognize(data)
                        await send(.receiptOCRRecognized(result))
                    } catch {
                        await send(.receiptOCRFailed("transactions.add.receipt.ocr.error.failed"))
                    }
                }

            case let .receiptImageSaved(identifier):
                state.isReceiptImageSaving = false
                state.draftReceiptImageIdentifier = identifier
                return .none

            case let .receiptImageSaveFailed(messageKey):
                state.isReceiptImageSaving = false
                state.isReceiptOCRProcessing = false
                state.formErrorMessageKey = messageKey
                return .none

            case let .receiptOCRRecognized(result):
                state.isReceiptOCRProcessing = false
                state.receiptOCRResult = result
                apply(result, to: &state)
                return .none

            case let .receiptOCRFailed(messageKey):
                state.isReceiptOCRProcessing = false
                state.formErrorMessageKey = messageKey
                return .none

            case .receiptImageRemoved:
                state.draftReceiptImageIdentifier = nil
                state.receiptOCRResult = nil
                state.isReceiptOCRProcessing = false
                state.formErrorMessageKey = nil
                return .none

            case .voiceInputButtonTapped:
                state.isVoiceInputRecording = true
                state.voiceInputTranscript = nil
                state.voiceInputErrorMessageKey = nil
                state.formErrorMessageKey = nil

                return .run { send in
                    do {
                        let transcript = try await voiceInputClient.recognize()
                        await send(.voiceInputTranscriptRecognized(transcript))
                    } catch {
                        await send(.voiceInputFailed("transactions.voice.error.failed"))
                    }
                }

            case let .voiceInputTranscriptRecognized(transcript):
                state.isVoiceInputRecording = false
                state.voiceInputTranscript = transcript
                guard let parseResult = VoiceTransactionParser.parse(transcript) else {
                    state.voiceInputErrorMessageKey = "transactions.voice.error.parseFailed"
                    return .none
                }

                apply(parseResult, to: &state)
                return .none

            case let .voiceInputFailed(messageKey):
                state.isVoiceInputRecording = false
                state.voiceInputErrorMessageKey = messageKey
                return .none

            case .bankStatementImportButtonTapped:
                state.isBankStatementImporterPresented = true
                state.bankStatementImportErrorMessageKey = nil
                return .none

            case .bankStatementImporterDismissed:
                state.isBankStatementImporterPresented = false
                return .none

            case let .bankStatementPDFDataSelected(data):
                guard data.isEmpty == false else {
                    return .none
                }

                state.isBankStatementImporterPresented = false
                state.isBankStatementImporting = true
                state.bankStatementImportSummary = nil
                state.bankStatementImportErrorMessageKey = nil
                state.errorMessageKey = nil

                return .run { send in
                    do {
                        let text = try await bankStatementPDFClient.extractText(data)
                        let result = BankStatementParser.parse(text: text)
                        guard result.drafts.isEmpty == false else {
                            await send(.bankStatementImportFailed("transactions.import.error.empty"))
                            return
                        }

                        var importedTransactions: [Transaction] = []
                        for draft in result.drafts {
                            let transaction = try draft.validated(id: uuid())
                            try await repository.save(transaction)
                            importedTransactions.append(transaction)
                        }

                        await send(
                            .bankStatementImported(
                                importedTransactions,
                                BankStatementImportSummary(
                                    importedCount: importedTransactions.count,
                                    skippedLineCount: result.skippedLineCount,
                                    totalLineCount: result.totalLineCount
                                )
                            )
                        )
                    } catch {
                        await send(.bankStatementImportFailed("transactions.import.error.failed"))
                    }
                }

            case let .bankStatementImported(transactions, summary):
                state.isBankStatementImporting = false
                state.bankStatementImportSummary = summary
                for transaction in transactions {
                    insert(transaction, into: &state)
                }
                updateDashboard(&state)
                return scheduleSubscriptionRenewalReminders(for: state)

            case let .bankStatementImportFailed(messageKey):
                state.isBankStatementImporting = false
                state.bankStatementImportErrorMessageKey = messageKey
                return .none

            case let .subscriptionRenewalRemindersScheduled(count):
                state.subscriptionRenewalReminderCount = count
                state.subscriptionRenewalReminderErrorMessageKey = nil
                return .none

            case let .subscriptionRenewalReminderSchedulingFailed(messageKey):
                state.subscriptionRenewalReminderErrorMessageKey = messageKey
                return .none
            }
        }
    }

    private func saveSavingGoal(state: inout State) -> Effect<Action> {
        guard let targetAmount = TransactionAmountParser.parse(state.savingGoalTargetAmountText) else {
            state.savingGoalEditorErrorMessageKey = "transactions.goal.error.invalidTarget"
            return .none
        }

        let currentAmountText = state.savingGoalCurrentAmountText
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let currentAmount = currentAmountText.isEmpty
            ? Decimal.zero
            : TransactionAmountParser.parse(currentAmountText)
        guard let currentAmount else {
            state.savingGoalEditorErrorMessageKey = "transactions.goal.error.invalidCurrent"
            return .none
        }

        let existingGoal = state.editingSavingGoal
        let goalID = existingGoal?.id ?? uuid()
        let createdAt = existingGoal?.createdAt ?? now
        let draft = SavingGoalDraft(
            name: state.savingGoalNameText,
            targetAmount: targetAmount,
            currentAmount: currentAmount,
            deadline: state.savingGoalDeadline,
            imageIdentifier: existingGoal?.imageIdentifier
        )

        do {
            let goal = try draft.validated(id: goalID, createdAt: createdAt)
            state.isSavingGoalSaving = true
            state.savingGoalEditorErrorMessageKey = nil

            return .run { send in
                do {
                    try await savingGoalRepository.save(goal)
                    await send(.savingGoalSaved(goal))
                } catch {
                    await send(.savingGoalSaveFailed("transactions.goal.error.saveFailed"))
                }
            }
        } catch let error as SavingGoalValidationError {
            state.savingGoalEditorErrorMessageKey = error.messageKey
            return .none
        } catch {
            state.savingGoalEditorErrorMessageKey = "transactions.goal.error.saveFailed"
            return .none
        }
    }

    private func scheduleSubscriptionRenewalReminders(for state: State) -> Effect<Action> {
        let reminders = SubscriptionRenewalReminderPlanner.reminders(
            for: state.subscriptionDetectionResult.subscriptions,
            referenceDate: state.historyReferenceDate
        )
        guard reminders.isEmpty == false else {
            return .none
        }

        return .run { send in
            do {
                try await subscriptionNotificationClient.scheduleRenewalReminders(reminders)
                await send(.subscriptionRenewalRemindersScheduled(reminders.count))
            } catch {
                await send(
                    .subscriptionRenewalReminderSchedulingFailed(
                        "transactions.subscription.notification.error.failed"
                    )
                )
            }
        }
    }

    private func save(
        _ draft: TransactionDraft,
        state: inout State
    ) -> Effect<Action> {
        do {
            let transaction = try draft.validated(id: uuid())
            state.isSaving = true
            state.errorMessageKey = nil
            state.formErrorMessageKey = nil

            return .run { send in
                do {
                    try await repository.save(transaction)
                    await send(.transactionSaved(transaction))
                } catch {
                    await send(.saveFailed("transactions.error.saveFailed"))
                }
            }
        } catch {
            state.errorMessageKey = "transactions.error.invalidDraft"
            state.formErrorMessageKey = "transactions.error.invalidDraft"
            return .none
        }
    }

    private func insert(
        _ transaction: Transaction,
        into state: inout State
    ) {
        var transactions = Array(state.transactions)
        transactions.removeAll { $0.id == transaction.id }
        transactions.append(transaction)
        state.transactions = IdentifiedArray(
            uniqueElements: transactions.sorted { $0.occurredAt > $1.occurredAt }
        )
    }

    private func resetForm(
        _ state: inout State,
        occurredAt: Date
    ) {
        state.amountText = ""
        state.draftKind = .expense
        state.draftCategory = TransactionCategory.defaultCategory(for: .expense)
        state.draftOccurredAt = occurredAt
        state.draftNote = ""
        state.draftReceiptImageIdentifier = nil
        state.isReceiptImageSaving = false
        state.isReceiptOCRProcessing = false
        state.receiptOCRResult = nil
        state.isVoiceInputRecording = false
        state.voiceInputTranscript = nil
        state.voiceInputErrorMessageKey = nil
        state.formErrorMessageKey = nil
    }

    private func apply(
        _ result: ReceiptOCRResult,
        to state: inout State
    ) {
        if let amount = result.amount {
            state.amountText = TransactionAmountFormatter.formatForEditing(amount.description)
        }

        if let occurredAt = result.occurredAt {
            state.draftOccurredAt = occurredAt
        }

        if let merchantName = result.merchantName,
           state.draftNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            state.draftNote = merchantName
        }
    }

    private func apply(
        _ result: VoiceTransactionParseResult,
        to state: inout State
    ) {
        state.amountText = TransactionAmountFormatter.formatForEditing(result.amount.description)
        state.draftKind = result.kind
        if state.categories(for: result.kind).contains(result.category) {
            state.draftCategory = result.category
        } else {
            state.draftCategory = TransactionCategory.defaultCategory(for: result.kind)
        }
        if let note = result.note {
            state.draftNote = note
        }
        state.voiceInputErrorMessageKey = nil
        state.formErrorMessageKey = nil
    }

    private func resetCategoryEditor(_ state: inout State) {
        state.isCategoryEditorPresented = false
        state.isCategorySaving = false
        state.categoryNameText = ""
        state.categoryOption = .coffee
        state.categoryEditorErrorMessageKey = nil
    }

    private func resetBudgetEditor(_ state: inout State) {
        state.isBudgetEditorPresented = false
        state.isBudgetSaving = false
        state.editingBudgetCategory = nil
        state.budgetLimitText = ""
        state.budgetEditorErrorMessageKey = nil
    }

    private func resetSavingGoalEditor(
        _ state: inout State,
        deadline: Date
    ) {
        state.isSavingGoalEditorPresented = false
        state.isSavingGoalSaving = false
        state.editingSavingGoalID = nil
        state.savingGoalNameText = ""
        state.savingGoalTargetAmountText = ""
        state.savingGoalCurrentAmountText = ""
        state.savingGoalDeadline = deadline
        state.savingGoalEditorErrorMessageKey = nil
    }

    private func upsert(
        _ goal: SavingGoal,
        into state: inout State
    ) {
        var goals = Array(state.savingGoals)
        goals.removeAll { $0.id == goal.id }
        goals.append(goal)
        state.savingGoals = IdentifiedArray(uniqueElements: goals.sorted { $0.deadline < $1.deadline })
    }

    private func defaultSavingGoalDeadline(from date: Date) -> Date {
        Calendar.current.date(byAdding: .month, value: 6, to: date) ?? date
    }

    private func emergencyFundGoalDeadline(from date: Date) -> Date {
        Calendar.current.date(byAdding: .month, value: 12, to: date) ?? date
    }

    private func updatingBudgets(
        _ budgets: [Budget],
        category: TransactionCategory,
        monthlyLimit: Decimal
    ) -> [Budget] {
        var updatedBudgets = budgets
        if let index = updatedBudgets.firstIndex(where: { $0.category.id == category.id }) {
            updatedBudgets[index].monthlyLimit = monthlyLimit
        } else {
            updatedBudgets.append(Budget(category: category, monthlyLimit: monthlyLimit))
        }

        return updatedBudgets.sorted { $0.category.id < $1.category.id }
    }

    private func updateDashboard(_ state: inout State) {
        state.summary = state.transactions.monthlySummary(containing: now)
        state.categorySpendings = state.transactions.monthlyCategorySpendings(containing: now)
        state.budgets = state.budgets.applyingMonthlySpending(
            from: Array(state.transactions),
            containing: now
        )
    }
}

private extension Transaction {
    func matchesSearch(_ normalizedQuery: String) -> Bool {
        let searchableValues = [
            note,
            category.id,
            category.nameKey,
            kind.rawValue,
            amount.description,
        ].compactMap { $0 }

        return searchableValues.contains {
            $0.normalizedForTransactionSearch.contains(normalizedQuery)
        }
    }
}

private extension String {
    var normalizedForTransactionSearch: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    var normalizedForCategoryID: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .unicodeScalars
            .map { CharacterSet.alphanumerics.contains($0) ? Character($0) : "-" }
            .reduce(into: "") { result, character in
                if character == "-", result.last == "-" {
                    return
                }

                result.append(character)
            }
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    var isEmergencyFundGoalName: Bool {
        let normalizedName = normalizedForTransactionSearch.lowercased()
        return normalizedName.contains("emergency")
            || normalizedName.contains("khan cap")
            || normalizedName.contains("du phong")
    }
}

private extension SavingGoalValidationError {
    var messageKey: String {
        switch self {
        case .nameRequired:
            "transactions.goal.error.nameRequired"
        case .targetAmountMustBePositive:
            "transactions.goal.error.invalidTarget"
        case .currentAmountCannotBeNegative:
            "transactions.goal.error.invalidCurrent"
        case .currentAmountCannotExceedTargetAmount:
            "transactions.goal.error.currentExceedsTarget"
        case .deadlineMustBeInFuture:
            "transactions.goal.error.deadlineMustBeFuture"
        }
    }
}

private extension Decimal {
    static func inputValue(_ text: String) -> Decimal? {
        let normalizedText = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        return Decimal(string: normalizedText, locale: Locale(identifier: "en_US_POSIX"))
    }
}
