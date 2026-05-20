import Foundation
import Testing
import ComposableArchitecture
import BudgetDomain
import GoalDomain
import InsightDomain
import SubscriptionDomain
import TransactionDomain
@testable import TransactionFeature

@MainActor
@Test("loads transactions on task")
func loadsTransactionsOnTask() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let date = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26).date
    )
    let transaction = Transaction(
        amount: 45_000,
        kind: .expense,
        category: .food,
        occurredAt: date
    )
    let store = TestStore(initialState: TransactionFeature.State()) {
        TransactionFeature()
    } withDependencies: {
        $0.date.now = date
        $0.transactionRepository.fetchAll = { [transaction] }
    }

    await store.send(.task) {
        $0.historyReferenceDate = date
        $0.isLoading = true
    }
    await store.receive(\.transactionsLoaded) {
        $0.isLoading = false
        $0.transactions = IdentifiedArray(uniqueElements: [transaction])
        $0.summary = MonthlyTransactionSummary(
            income: 0,
            expense: 45_000,
            balance: -45_000
        )
        $0.categorySpendings = [
            MonthlyCategorySpending(
                category: .food,
                amount: 45_000,
                fraction: 1
            ),
        ]
    }
}

@MainActor
@Test("saves valid draft")
func savesValidDraft() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let date = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26).date
    )
    let draft = TransactionDraft(
        amount: 75_000,
        kind: .expense,
        category: .transport,
        occurredAt: date
    )
    let transactionID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
    let expectedTransaction = Transaction(
        id: transactionID,
        amount: 75_000,
        kind: .expense,
        category: .transport,
        occurredAt: date
    )
    let store = TestStore(initialState: TransactionFeature.State()) {
        TransactionFeature()
    } withDependencies: {
        $0.date.now = date
        $0.uuid = .constant(transactionID)
        $0.transactionRepository.save = { _ in }
    }

    await store.send(.saveDraft(draft)) {
        $0.isSaving = true
    }
    await store.receive(.transactionSaved(expectedTransaction)) {
        $0.isSaving = false
        $0.transactions.insert(expectedTransaction, at: 0)
        $0.draftOccurredAt = date
        $0.summary = MonthlyTransactionSummary(
            income: 0,
            expense: 75_000,
            balance: -75_000
        )
        $0.categorySpendings = [
            MonthlyCategorySpending(
                category: .transport,
                amount: 75_000,
                fraction: 1
            ),
        ]
    }
}

@MainActor
@Test("rejects invalid draft")
func rejectsInvalidDraft() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let date = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26).date
    )
    let draft = TransactionDraft(
        amount: 0,
        kind: .expense,
        category: .food,
        occurredAt: date
    )
    let store = TestStore(initialState: TransactionFeature.State()) {
        TransactionFeature()
    }

    await store.send(.saveDraft(draft)) {
        $0.errorMessageKey = "transactions.error.invalidDraft"
        $0.formErrorMessageKey = "transactions.error.invalidDraft"
    }
}

@MainActor
@Test("saves transaction from add form")
func savesTransactionFromAddForm() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let date = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26).date
    )
    let transactionID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000002"))
    let expectedTransaction = Transaction(
        id: transactionID,
        amount: 45_000,
        kind: .expense,
        category: .food,
        occurredAt: date,
        note: "Coffee"
    )
    let store = TestStore(initialState: TransactionFeature.State()) {
        TransactionFeature()
    } withDependencies: {
        $0.date.now = date
        $0.uuid = .constant(transactionID)
        $0.transactionRepository.save = { _ in }
    }

    await store.send(.addButtonTapped) {
        $0.isAddSheetPresented = true
        $0.draftOccurredAt = date
    }
    await store.send(.amountTextChanged("45.000")) {
        $0.amountText = "45.000"
    }
    await store.send(.noteChanged(" Coffee ")) {
        $0.draftNote = " Coffee "
    }
    await store.send(.saveButtonTapped) {
        $0.isSaving = true
    }
    await store.receive(.transactionSaved(expectedTransaction)) {
        $0.isSaving = false
        $0.isAddSheetPresented = false
        $0.transactions.insert(expectedTransaction, at: 0)
        $0.amountText = ""
        $0.draftOccurredAt = date
        $0.draftNote = ""
        $0.summary = MonthlyTransactionSummary(
            income: 0,
            expense: 45_000,
            balance: -45_000
        )
        $0.categorySpendings = [
            MonthlyCategorySpending(
                category: .food,
                amount: 45_000,
                fraction: 1
            ),
        ]
    }
}

@MainActor
@Test("fills transaction draft from voice input")
func fillsTransactionDraftFromVoiceInput() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let date = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26).date
    )
    let store = TestStore(initialState: TransactionFeature.State()) {
        TransactionFeature()
    } withDependencies: {
        $0.date.now = date
        $0.voiceInputClient.recognize = {
            "Grab đi làm 65k"
        }
    }

    await store.send(.addButtonTapped) {
        $0.isAddSheetPresented = true
        $0.draftOccurredAt = date
    }
    await store.send(.voiceInputButtonTapped) {
        $0.isVoiceInputRecording = true
    }
    await store.receive(.voiceInputTranscriptRecognized("Grab đi làm 65k")) {
        $0.isVoiceInputRecording = false
        $0.voiceInputTranscript = "Grab đi làm 65k"
        $0.amountText = "65.000"
        $0.draftCategory = .transport
        $0.draftNote = "Grab đi làm"
    }
}

@MainActor
@Test("shows voice input parse error")
func showsVoiceInputParseError() async throws {
    let store = TestStore(initialState: TransactionFeature.State()) {
        TransactionFeature()
    } withDependencies: {
        $0.voiceInputClient.recognize = {
            "Ăn sáng ở quán quen"
        }
    }

    await store.send(.voiceInputButtonTapped) {
        $0.isVoiceInputRecording = true
    }
    await store.receive(.voiceInputTranscriptRecognized("Ăn sáng ở quán quen")) {
        $0.isVoiceInputRecording = false
        $0.voiceInputTranscript = "Ăn sáng ở quán quen"
        $0.voiceInputErrorMessageKey = "transactions.voice.error.parseFailed"
    }
}

@MainActor
@Test("saves receipt image before saving transaction")
func savesReceiptImageBeforeSavingTransaction() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let date = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26).date
    )
    let transactionID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000003"))
    let expectedTransaction = Transaction(
        id: transactionID,
        amount: 120_000,
        kind: .expense,
        category: .food,
        occurredAt: date,
        receiptImageIdentifier: "receipt-1"
    )
    let store = TestStore(initialState: TransactionFeature.State()) {
        TransactionFeature()
    } withDependencies: {
        $0.date.now = date
        $0.uuid = .constant(transactionID)
        $0.receiptImageRepository.save = { data in
            #expect(data == Data([1, 2, 3]))
            return "receipt-1"
        }
        $0.transactionRepository.save = { _ in }
    }

    await store.send(.addButtonTapped) {
        $0.isAddSheetPresented = true
        $0.draftOccurredAt = date
    }
    await store.send(.receiptImageDataSelected(Data([1, 2, 3]))) {
        $0.isReceiptImageSaving = true
        $0.isReceiptOCRProcessing = true
    }
    await store.receive(.receiptImageSaved("receipt-1")) {
        $0.isReceiptImageSaving = false
        $0.draftReceiptImageIdentifier = "receipt-1"
    }
    await store.receive(.receiptOCRRecognized(ReceiptOCRResult())) {
        $0.isReceiptOCRProcessing = false
        $0.receiptOCRResult = ReceiptOCRResult()
    }
    await store.send(.amountTextChanged("120000")) {
        $0.amountText = "120.000"
    }
    await store.send(.saveButtonTapped) {
        $0.isSaving = true
    }
    await store.receive(.transactionSaved(expectedTransaction)) {
        $0.isSaving = false
        $0.isAddSheetPresented = false
        $0.transactions.insert(expectedTransaction, at: 0)
        $0.amountText = ""
        $0.draftOccurredAt = date
        $0.draftReceiptImageIdentifier = nil
        $0.receiptOCRResult = nil
        $0.summary = MonthlyTransactionSummary(
            income: 0,
            expense: 120_000,
            balance: -120_000
        )
        $0.categorySpendings = [
            MonthlyCategorySpending(
                category: .food,
                amount: 120_000,
                fraction: 1
            ),
        ]
    }
}

@MainActor
@Test("fills transaction draft from receipt OCR")
func fillsTransactionDraftFromReceiptOCR() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let date = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26).date
    )
    let receiptDate = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 25).date
    )
    let result = ReceiptOCRResult(
        merchantName: "Kaso Coffee",
        amount: 120_000,
        occurredAt: receiptDate,
        rawText: "Kaso Coffee\nTổng cộng: 120.000 đ"
    )
    let store = TestStore(initialState: TransactionFeature.State()) {
        TransactionFeature()
    } withDependencies: {
        $0.date.now = date
        $0.receiptImageRepository.save = { data in
            #expect(data == Data([4, 5, 6]))
            return "receipt-ocr"
        }
        $0.receiptOCRClient.recognize = { data in
            #expect(data == Data([4, 5, 6]))
            return result
        }
    }

    await store.send(.addButtonTapped) {
        $0.isAddSheetPresented = true
        $0.draftOccurredAt = date
    }
    await store.send(.receiptImageDataSelected(Data([4, 5, 6]))) {
        $0.isReceiptImageSaving = true
        $0.isReceiptOCRProcessing = true
    }
    await store.receive(.receiptImageSaved("receipt-ocr")) {
        $0.isReceiptImageSaving = false
        $0.draftReceiptImageIdentifier = "receipt-ocr"
    }
    await store.receive(.receiptOCRRecognized(result)) {
        $0.isReceiptOCRProcessing = false
        $0.receiptOCRResult = result
        $0.amountText = "120.000"
        $0.draftOccurredAt = receiptDate
        $0.draftNote = "Kaso Coffee"
    }
}

@MainActor
@Test("formats amount text while typing")
func formatsAmountTextWhileTyping() async {
    let store = TestStore(initialState: TransactionFeature.State()) {
        TransactionFeature()
    }

    await store.send(.amountTextChanged("45000")) {
        $0.amountText = "45.000"
    }
    await store.send(.amountTextChanged("1234567890")) {
        $0.amountText = "1.234.567.890"
    }
}

@MainActor
@Test("shows form error for invalid amount")
func showsFormErrorForInvalidAmount() async {
    let store = TestStore(initialState: TransactionFeature.State()) {
        TransactionFeature()
    }

    await store.send(.saveButtonTapped) {
        $0.formErrorMessageKey = "transactions.add.error.invalidAmount"
    }
}

@MainActor
@Test("filters history by search category and time scope")
func filtersHistoryBySearchCategoryAndTimeScope() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26, hour: 12).date
    )
    let yesterday = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 25, hour: 8).date
    )
    let lastMonth = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 3, day: 26, hour: 9).date
    )
    let coffeeTransaction = Transaction(
        amount: 45_000,
        kind: .expense,
        category: .food,
        occurredAt: referenceDate,
        note: "Cà phê sáng"
    )
    let transportTransaction = Transaction(
        amount: 75_000,
        kind: .expense,
        category: .transport,
        occurredAt: yesterday
    )
    let salaryTransaction = Transaction(
        amount: 20_000_000,
        kind: .income,
        category: .salary,
        occurredAt: lastMonth
    )
    let store = TestStore(
        initialState: TransactionFeature.State(
            transactions: IdentifiedArray(
                uniqueElements: [
                    coffeeTransaction,
                    transportTransaction,
                    salaryTransaction,
                ]
            ),
            historyReferenceDate: referenceDate
        )
    ) {
        TransactionFeature()
    } withDependencies: {
        $0.date.now = referenceDate
    }

    #expect(store.state.filteredTransactions.map(\.id) == [
        coffeeTransaction.id,
        transportTransaction.id,
        salaryTransaction.id,
    ])

    await store.send(.searchTextChanged("ca phe")) {
        $0.searchText = "ca phe"
    }
    #expect(store.state.filteredTransactions.map(\.id) == [coffeeTransaction.id])

    await store.send(.searchTextChanged("")) {
        $0.searchText = ""
    }
    await store.send(.categoryFilterChanged(TransactionCategory.transport.id)) {
        $0.selectedCategoryID = TransactionCategory.transport.id
    }
    #expect(store.state.filteredTransactions.map(\.id) == [transportTransaction.id])

    await store.send(.categoryFilterChanged(nil)) {
        $0.selectedCategoryID = nil
    }
    await store.send(.historyScopeChanged(.month)) {
        $0.historyScope = .month
        $0.historyReferenceDate = referenceDate
    }
    #expect(store.state.filteredTransactions.map(\.id) == [
        coffeeTransaction.id,
        transportTransaction.id,
    ])
}

@MainActor
@Test("smart search natural language overrides history scope")
func smartSearchNaturalLanguageOverridesScope() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26, hour: 12).date
    )
    let yesterday = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 25, hour: 8).date
    )
    let lastMonth = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 3, day: 26, hour: 9).date
    )
    let coffeeTransaction = Transaction(
        amount: 45_000,
        kind: .expense,
        category: .food,
        occurredAt: referenceDate,
        note: "Cà phê sáng"
    )
    let coffeeYesterday = Transaction(
        amount: 50_000,
        kind: .expense,
        category: .food,
        occurredAt: yesterday,
        note: "Cà phê chiều"
    )
    let coffeeLastMonth = Transaction(
        amount: 55_000,
        kind: .expense,
        category: .food,
        occurredAt: lastMonth,
        note: "Cà phê cuối tháng"
    )
    let store = TestStore(
        initialState: TransactionFeature.State(
            transactions: IdentifiedArray(
                uniqueElements: [coffeeTransaction, coffeeYesterday, coffeeLastMonth]
            ),
            historyScope: .day,
            historyReferenceDate: referenceDate
        )
    ) {
        TransactionFeature()
    } withDependencies: {
        $0.date.now = referenceDate
    }

    // Day scope restricts to today only.
    #expect(store.state.filteredTransactions.map(\.id) == [coffeeTransaction.id])

    // "tháng trước" overrides the day scope.
    await store.send(.searchTextChanged("cà phê tháng trước")) {
        $0.searchText = "cà phê tháng trước"
    }
    #expect(store.state.filteredTransactions.map(\.id) == [coffeeLastMonth.id])

    // "hôm qua" picks just yesterday's entry.
    await store.send(.searchTextChanged("cà phê hôm qua")) {
        $0.searchText = "cà phê hôm qua"
    }
    #expect(store.state.filteredTransactions.map(\.id) == [coffeeYesterday.id])
}

@MainActor
@Test("adds custom category and selects it for draft")
func addsCustomCategoryAndSelectsItForDraft() async throws {
    let customCategory = TransactionCategory(
        id: "custom-ca-phe",
        nameKey: "Cà phê",
        symbolName: "cup.and.saucer",
        colorName: "brown"
    )
    let store = TestStore(initialState: TransactionFeature.State()) {
        TransactionFeature()
    } withDependencies: {
        $0.transactionCategoryRepository.saveCustomCategories = { categories in
            #expect(categories == [customCategory])
        }
    }

    await store.send(.categoryAddButtonTapped) {
        $0.isCategoryEditorPresented = true
    }
    await store.send(.categoryNameTextChanged("Cà phê")) {
        $0.categoryNameText = "Cà phê"
    }
    await store.send(.categorySaveButtonTapped) {
        $0.isCategorySaving = true
    }
    await store.receive(.customCategoriesSaved([customCategory], customCategory)) {
        $0.customCategories = [customCategory]
        $0.draftCategory = customCategory
        $0.isCategorySaving = false
        $0.isCategoryEditorPresented = false
        $0.categoryNameText = ""
    }
}

@MainActor
@Test("loads custom categories on task")
func loadsCustomCategoriesOnTask() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let date = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26).date
    )
    let customCategory = TransactionCategory(
        id: "custom-thu-cung",
        nameKey: "Thú cưng",
        symbolName: "pawprint",
        colorName: "orange"
    )
    let store = TestStore(initialState: TransactionFeature.State()) {
        TransactionFeature()
    } withDependencies: {
        $0.date.now = date
        $0.transactionRepository.fetchAll = { [] }
        $0.transactionCategoryRepository.fetchCustomCategories = { [customCategory] }
    }

    await store.send(.task) {
        $0.historyReferenceDate = date
        $0.isLoading = true
    }
    await store.receive(\.transactionsLoaded) {
        $0.isLoading = false
    }
    await store.receive(.customCategoriesLoaded([customCategory])) {
        $0.customCategories = [customCategory]
    }
}

@MainActor
@Test("rejects duplicate custom category names")
func rejectsDuplicateCustomCategoryNames() async throws {
    let customCategory = TransactionCategory(
        id: "custom-ca-phe",
        nameKey: "Cà phê",
        symbolName: "cup.and.saucer",
        colorName: "brown"
    )
    let store = TestStore(
        initialState: TransactionFeature.State(
            customCategories: [customCategory],
            categoryNameText: "Ca phe"
        )
    ) {
        TransactionFeature()
    }

    await store.send(.categorySaveButtonTapped) {
        $0.categoryEditorErrorMessageKey = "transactions.category.error.duplicate"
    }
}

@MainActor
@Test("edits and persists category budget")
func editsAndPersistsCategoryBudget() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let date = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26).date
    )
    let transaction = Transaction(
        amount: 250_000,
        kind: .expense,
        category: .food,
        occurredAt: date
    )
    let store = TestStore(
        initialState: TransactionFeature.State(
            transactions: IdentifiedArray(uniqueElements: [transaction]),
            budgets: [
                Budget(category: .food, monthlyLimit: 1_000_000, spent: 250_000),
            ]
        )
    ) {
        TransactionFeature()
    } withDependencies: {
        $0.date.now = date
        $0.budgetRepository.saveAll = { budgets in
            #expect(budgets == [
                Budget(category: .food, monthlyLimit: 2_000_000),
            ])
        }
    }

    await store.send(.budgetEditButtonTapped(Budget(
        category: .food,
        monthlyLimit: 1_000_000,
        spent: 250_000
    ))) {
        $0.editingBudgetCategory = .food
        $0.budgetLimitText = "1.000.000"
        $0.isBudgetEditorPresented = true
    }
    await store.send(.budgetLimitTextChanged("2000000")) {
        $0.budgetLimitText = "2.000.000"
    }
    await store.send(.budgetSaveButtonTapped) {
        $0.isBudgetSaving = true
    }
    await store.receive(.budgetsSaved([
        Budget(category: .food, monthlyLimit: 2_000_000),
    ])) {
        $0.isBudgetSaving = false
        $0.budgets = [
            Budget(category: .food, monthlyLimit: 2_000_000, spent: 250_000),
        ]
        $0.isBudgetEditorPresented = false
        $0.editingBudgetCategory = nil
        $0.budgetLimitText = ""
    }
}

@MainActor
@Test("updates budget spending from loaded transactions")
func updatesBudgetSpendingFromLoadedTransactions() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let date = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26).date
    )
    let transaction = Transaction(
        amount: 250_000,
        kind: .expense,
        category: .food,
        occurredAt: date
    )
    let store = TestStore(
        initialState: TransactionFeature.State(
            transactions: IdentifiedArray(uniqueElements: [transaction])
        )
    ) {
        TransactionFeature()
    } withDependencies: {
        $0.date.now = date
    }

    await store.send(
        .budgetsUpdated([
            Budget(category: .food, monthlyLimit: 1_000_000),
            Budget(category: .transport, monthlyLimit: 500_000),
        ])
    ) {
        $0.budgets = [
            Budget(
                category: .food,
                monthlyLimit: 1_000_000,
                spent: 250_000
            ),
            Budget(
                category: .transport,
                monthlyLimit: 500_000
            ),
        ]
    }
}

@MainActor
@Test("loads saving goals on task")
func loadsSavingGoalsOnTask() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let date = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26).date
    )
    let goal = SavingGoal(
        name: "Emergency fund",
        targetAmount: 30_000_000,
        currentAmount: 5_000_000,
        deadline: try #require(
            DateComponents(calendar: calendar, year: 2026, month: 12, day: 31).date
        ),
        createdAt: date
    )
    let store = TestStore(initialState: TransactionFeature.State()) {
        TransactionFeature()
    } withDependencies: {
        $0.date.now = date
        $0.transactionRepository.fetchAll = { [] }
        $0.savingGoalRepository.fetchAll = { [goal] }
    }

    await store.send(.task) {
        $0.historyReferenceDate = date
        $0.isLoading = true
    }
    await store.receive(.transactionsLoaded([])) {
        $0.isLoading = false
    }
    await store.receive(.savingGoalsLoaded([goal])) {
        $0.savingGoals = IdentifiedArray(uniqueElements: [goal])
    }
}

@MainActor
@Test("saves saving goal from editor")
func savesSavingGoalFromEditor() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let date = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26).date
    )
    let defaultDeadline = try #require(Calendar.current.date(byAdding: .month, value: 6, to: date))
    let deadline = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 12, day: 31).date
    )
    let goalID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000005"))
    let expectedGoal = SavingGoal(
        id: goalID,
        name: "Emergency fund",
        targetAmount: 30_000_000,
        currentAmount: 5_000_000,
        deadline: deadline,
        createdAt: date
    )
    let recorder = SavingGoalRecorder()
    let store = TestStore(initialState: TransactionFeature.State()) {
        TransactionFeature()
    } withDependencies: {
        $0.date.now = date
        $0.uuid = .constant(goalID)
        $0.savingGoalRepository.save = { goal in
            await recorder.save(goal)
        }
    }

    await store.send(.savingGoalAddButtonTapped) {
        $0.isSavingGoalEditorPresented = true
        $0.savingGoalDeadline = defaultDeadline
    }
    await store.send(.savingGoalNameTextChanged(" Emergency fund ")) {
        $0.savingGoalNameText = " Emergency fund "
    }
    await store.send(.savingGoalTargetAmountTextChanged("30000000")) {
        $0.savingGoalTargetAmountText = "30.000.000"
    }
    await store.send(.savingGoalCurrentAmountTextChanged("5000000")) {
        $0.savingGoalCurrentAmountText = "5.000.000"
    }
    await store.send(.savingGoalDeadlineChanged(deadline)) {
        $0.savingGoalDeadline = deadline
    }
    await store.send(.savingGoalSaveButtonTapped) {
        $0.isSavingGoalSaving = true
    }
    await store.receive(.savingGoalSaved(expectedGoal)) {
        $0.isSavingGoalSaving = false
        $0.savingGoals = IdentifiedArray(uniqueElements: [expectedGoal])
        $0.isSavingGoalEditorPresented = false
        $0.editingSavingGoalID = nil
        $0.savingGoalNameText = ""
        $0.savingGoalTargetAmountText = ""
        $0.savingGoalCurrentAmountText = ""
        $0.savingGoalDeadline = defaultDeadline
    }

    #expect(await recorder.goals() == [expectedGoal])
}

@MainActor
@Test("deletes saving goal from editor")
func deletesSavingGoalFromEditor() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let date = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26).date
    )
    let defaultDeadline = try #require(Calendar.current.date(byAdding: .month, value: 6, to: date))
    let goal = SavingGoal(
        name: "Emergency fund",
        targetAmount: 30_000_000,
        currentAmount: 5_000_000,
        deadline: try #require(
            DateComponents(calendar: calendar, year: 2026, month: 12, day: 31).date
        ),
        createdAt: date
    )
    let recorder = SavingGoalDeleteRecorder()
    let store = TestStore(
        initialState: TransactionFeature.State(
            savingGoals: IdentifiedArray(uniqueElements: [goal])
        )
    ) {
        TransactionFeature()
    } withDependencies: {
        $0.date.now = date
        $0.savingGoalRepository.delete = { id in
            await recorder.save(id)
        }
    }

    await store.send(.savingGoalEditButtonTapped(goal)) {
        $0.editingSavingGoalID = goal.id
        $0.savingGoalNameText = "Emergency fund"
        $0.savingGoalTargetAmountText = "30.000.000"
        $0.savingGoalCurrentAmountText = "5.000.000"
        $0.savingGoalDeadline = goal.deadline
        $0.isSavingGoalEditorPresented = true
    }
    await store.send(.savingGoalDeleteButtonTapped(goal)) {
        $0.isSavingGoalSaving = true
    }
    await store.receive(.savingGoalDeleted(goal.id)) {
        $0.isSavingGoalSaving = false
        $0.savingGoals = []
        $0.isSavingGoalEditorPresented = false
        $0.editingSavingGoalID = nil
        $0.savingGoalNameText = ""
        $0.savingGoalTargetAmountText = ""
        $0.savingGoalCurrentAmountText = ""
        $0.savingGoalDeadline = defaultDeadline
    }

    #expect(await recorder.ids() == [goal.id])
}

@Test("derives goal impact from exceeded budget")
func derivesGoalImpactFromExceededBudget() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 1).date
    )
    let goal = SavingGoal(
        name: "Emergency fund",
        targetAmount: 30_000_000,
        currentAmount: 25_000_000,
        deadline: try #require(
            DateComponents(calendar: calendar, year: 2026, month: 4, day: 30).date
        ),
        createdAt: try #require(
            DateComponents(calendar: calendar, year: 2026, month: 1, day: 1).date
        )
    )
    let budget = Budget(
        category: .food,
        monthlyLimit: 2_000_000,
        spent: 2_500_000
    )
    let state = TransactionFeature.State(
        budgets: [budget],
        savingGoals: IdentifiedArray(uniqueElements: [goal]),
        historyReferenceDate: referenceDate
    )

    let impact = try #require(state.savingGoalSpendingImpacts.first)
    #expect(state.savingGoalSpendingImpacts.count == 1)
    #expect(impact.goal == goal)
    #expect(impact.budget == budget)
    #expect(impact.overageAmount == 500_000)
    #expect(impact.delayedDayCount == 3)
}

@Test("derives emergency fund recommendation from spending history")
func derivesEmergencyFundRecommendationFromSpendingHistory() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26).date
    )
    let goal = SavingGoal(
        name: "Quỹ khẩn cấp",
        targetAmount: 60_000_000,
        currentAmount: 15_000_000,
        deadline: try #require(
            DateComponents(calendar: calendar, year: 2026, month: 12, day: 31).date
        ),
        createdAt: try #require(
            DateComponents(calendar: calendar, year: 2026, month: 1, day: 1).date
        )
    )
    let transactions = [
        Transaction(
            amount: 10_000_000,
            kind: .expense,
            category: .food,
            occurredAt: try #require(
                DateComponents(calendar: calendar, year: 2026, month: 2, day: 10).date
            )
        ),
        Transaction(
            amount: 12_000_000,
            kind: .expense,
            category: .food,
            occurredAt: try #require(
                DateComponents(calendar: calendar, year: 2026, month: 3, day: 10).date
            )
        ),
        Transaction(
            amount: 8_000_000,
            kind: .expense,
            category: .food,
            occurredAt: try #require(
                DateComponents(calendar: calendar, year: 2026, month: 4, day: 10).date
            )
        ),
    ]
    let state = TransactionFeature.State(
        transactions: IdentifiedArray(uniqueElements: transactions),
        savingGoals: IdentifiedArray(uniqueElements: [goal]),
        historyReferenceDate: referenceDate
    )
    let recommendation = try #require(state.emergencyFundRecommendation)

    #expect(recommendation.monthlyExpense == 10_000_000)
    #expect(recommendation.recommendedAmount == 60_000_000)
    #expect(recommendation.currentAmount == 15_000_000)
    #expect(recommendation.remainingAmount == 45_000_000)
}

@MainActor
@Test("prefills emergency fund goal from recommendation")
func prefillsEmergencyFundGoalFromRecommendation() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26).date
    )
    let deadline = try #require(Calendar.current.date(byAdding: .month, value: 12, to: referenceDate))
    let transactions = [
        Transaction(
            amount: 10_000_000,
            kind: .expense,
            category: .food,
            occurredAt: referenceDate
        ),
    ]
    let store = TestStore(
        initialState: TransactionFeature.State(
            transactions: IdentifiedArray(uniqueElements: transactions),
            historyReferenceDate: referenceDate
        )
    ) {
        TransactionFeature()
    } withDependencies: {
        $0.date.now = referenceDate
    }

    await store.send(.emergencyFundGoalButtonTapped) {
        $0.isSavingGoalEditorPresented = true
        $0.savingGoalNameText = "Quỹ khẩn cấp"
        $0.savingGoalTargetAmountText = "60.000.000"
        $0.savingGoalCurrentAmountText = "0"
        $0.savingGoalDeadline = deadline
    }
}

@Test("derives retirement simulation from cashflow history")
func derivesRetirementSimulationFromCashflowHistory() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26).date
    )
    let goal = SavingGoal(
        name: "Portfolio",
        targetAmount: 1,
        currentAmount: 100_000_000,
        deadline: try #require(
            DateComponents(calendar: calendar, year: 2026, month: 12, day: 31).date
        )
    )
    let transactions = [
        Transaction(
            amount: 30_000_000,
            kind: .income,
            category: .salary,
            occurredAt: referenceDate
        ),
        Transaction(
            amount: 10_000_000,
            kind: .expense,
            category: .food,
            occurredAt: referenceDate
        ),
    ]
    let state = TransactionFeature.State(
        transactions: IdentifiedArray(uniqueElements: transactions),
        savingGoals: IdentifiedArray(uniqueElements: [goal]),
        historyReferenceDate: referenceDate,
        retirementAnnualReturnPercentText: "0",
        retirementTargetMultiplierText: "25"
    )
    let simulation = try #require(state.retirementSimulation)

    #expect(simulation.targetAmount == 3_000_000_000)
    #expect(simulation.monthlyContribution == 20_000_000)
    #expect(simulation.projectedMonthCount == 145)
}

@Test("derives spending comparison report from transaction history")
func derivesSpendingComparisonReportFromTransactionHistory() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26).date
    )
    let transactions = [
        Transaction(
            amount: 3_000_000,
            kind: .expense,
            category: .food,
            occurredAt: try #require(
                DateComponents(calendar: calendar, year: 2026, month: 4, day: 10).date
            )
        ),
        Transaction(
            amount: 2_000_000,
            kind: .expense,
            category: .food,
            occurredAt: try #require(
                DateComponents(calendar: calendar, year: 2026, month: 3, day: 10).date
            )
        ),
    ]
    let state = TransactionFeature.State(
        transactions: IdentifiedArray(uniqueElements: transactions),
        historyReferenceDate: referenceDate
    )

    #expect(state.spendingComparisonReport.month.currentExpense == 3_000_000)
    #expect(state.spendingComparisonReport.month.previousExpense == 2_000_000)
    #expect(state.spendingComparisonReport.month.trend == .increased)
}

@Test("derives subscription dashboard from transactions")
func derivesSubscriptionDashboardFromTransactions() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26).date
    )
    let transactions = try [
        DateComponents(calendar: calendar, year: 2026, month: 1, day: 1).date,
        DateComponents(calendar: calendar, year: 2026, month: 2, day: 1).date,
        DateComponents(calendar: calendar, year: 2026, month: 3, day: 1).date,
    ]
    .map { date -> Transaction in
        let billingDate = try #require(date)
        return Transaction(
            amount: 129_000,
            kind: .expense,
            category: .entertainment,
            occurredAt: billingDate,
            note: "Netflix Premium"
        )
    }
    let state = TransactionFeature.State(
        transactions: IdentifiedArray(uniqueElements: transactions),
        historyReferenceDate: referenceDate
    )

    #expect(state.subscriptionDetectionResult.monthlyTotal == 129_000)
    #expect(state.subscriptionDetectionResult.subscriptions.map(\.name) == ["Netflix"])
}

@MainActor
@Test("schedules subscription renewal reminders after loading transactions")
func schedulesSubscriptionRenewalRemindersAfterLoadingTransactions() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26, hour: 9).date
    )
    let expectedNotificationDate = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 28).date
    )
    let transactions = try [
        DateComponents(calendar: calendar, year: 2026, month: 1, day: 1).date,
        DateComponents(calendar: calendar, year: 2026, month: 2, day: 1).date,
        DateComponents(calendar: calendar, year: 2026, month: 3, day: 1).date,
    ]
    .map { date -> Transaction in
        let billingDate = try #require(date)
        return Transaction(
            amount: 129_000,
            kind: .expense,
            category: .entertainment,
            occurredAt: billingDate,
            note: "Netflix Premium"
        )
    }
    let recorder = SubscriptionReminderRecorder()
    let store = TestStore(
        initialState: TransactionFeature.State(historyReferenceDate: referenceDate)
    ) {
        TransactionFeature()
    } withDependencies: {
        $0.date.now = referenceDate
        $0.subscriptionNotificationClient.scheduleRenewalReminders = { reminders in
            await recorder.save(reminders)
        }
    }

    await store.send(.transactionsLoaded(transactions)) {
        $0.transactions = IdentifiedArray(
            uniqueElements: transactions.sorted { $0.occurredAt > $1.occurredAt }
        )
    }
    await store.receive(.subscriptionRenewalRemindersScheduled(1)) {
        $0.subscriptionRenewalReminderCount = 1
    }

    let reminders = await recorder.reminders()
    let reminder = try #require(reminders.first)
    #expect(reminders.count == 1)
    #expect(reminder.notificationDate == expectedNotificationDate)
    #expect(reminder.dayCountUntilRenewal == 5)
}

@Test("derives spending anomalies from transaction history")
func derivesSpendingAnomaliesFromTransactionHistory() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26).date
    )
    let historicalDates = try [
        DateComponents(calendar: calendar, year: 2026, month: 1, day: 10).date,
        DateComponents(calendar: calendar, year: 2026, month: 2, day: 10).date,
        DateComponents(calendar: calendar, year: 2026, month: 3, day: 10).date,
    ]
    .map { try #require($0) }
    let currentDate = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 25).date
    )
    let transactions = historicalDates.map { date in
        Transaction(
            amount: 50_000,
            kind: .expense,
            category: .food,
            occurredAt: date
        )
    } + [
        Transaction(
            amount: 250_000,
            kind: .expense,
            category: .food,
            occurredAt: currentDate
        ),
    ]
    let state = TransactionFeature.State(
        transactions: IdentifiedArray(uniqueElements: transactions),
        historyReferenceDate: referenceDate
    )

    #expect(state.spendingAnomalies.contains { $0.kind == .largeTransaction })
    #expect(state.spendingAnomalies.contains { $0.kind == .categorySpike })
}

@Test("derives spending reduction suggestions from transaction history")
func derivesSpendingReductionSuggestionsFromTransactionHistory() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26).date
    )
    let historicalDates = try [
        DateComponents(calendar: calendar, year: 2026, month: 1, day: 10).date,
        DateComponents(calendar: calendar, year: 2026, month: 2, day: 10).date,
        DateComponents(calendar: calendar, year: 2026, month: 3, day: 10).date,
    ]
    .map { try #require($0) }
    let transactions = historicalDates.map { date in
        Transaction(
            amount: 1_000_000,
            kind: .expense,
            category: .food,
            occurredAt: date
        )
    } + [
        Transaction(
            amount: 1_600_000,
            kind: .expense,
            category: .food,
            occurredAt: referenceDate
        ),
    ]
    let state = TransactionFeature.State(
        transactions: IdentifiedArray(uniqueElements: transactions),
        historyReferenceDate: referenceDate
    )

    #expect(state.spendingReductionSuggestions.first?.suggestedMonthlySaving == 300_000)
}

@Test("derives monthly balance forecast from transaction history")
func derivesMonthlyBalanceForecastFromTransactionHistory() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 15).date
    )
    let transactions = [
        Transaction(
            amount: 10_000_000,
            kind: .income,
            category: .salary,
            occurredAt: referenceDate
        ),
        Transaction(
            amount: 3_000_000,
            kind: .expense,
            category: .food,
            occurredAt: referenceDate
        ),
    ]
    let state = TransactionFeature.State(
        transactions: IdentifiedArray(uniqueElements: transactions),
        historyReferenceDate: referenceDate
    )

    #expect(state.monthlyBalanceForecast.projectedBalance == 4_000_000)
    #expect(state.monthlyBalanceForecast.status == .safe)
}

@Test("derives time spending analysis from transaction history")
func derivesTimeSpendingAnalysisFromTransactionHistory() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26, hour: 12).date
    )
    let fridayNight = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 3, hour: 21).date
    )
    let fridayWeekday = calendar.component(.weekday, from: fridayNight)
    let transactions = [
        Transaction(amount: 500_000, kind: .expense, category: .food, occurredAt: fridayNight),
        Transaction(
            amount: 300_000,
            kind: .expense,
            category: .food,
            occurredAt: try #require(
                DateComponents(calendar: calendar, year: 2026, month: 4, day: 10, hour: 20).date
            )
        ),
        Transaction(
            amount: 450_000,
            kind: .expense,
            category: .shopping,
            occurredAt: try #require(
                DateComponents(calendar: calendar, year: 2026, month: 4, day: 4, hour: 21).date
            )
        ),
        Transaction(
            amount: 80_000,
            kind: .expense,
            category: .transport,
            occurredAt: try #require(
                DateComponents(calendar: calendar, year: 2026, month: 4, day: 6, hour: 9).date
            )
        ),
        Transaction(
            amount: 70_000,
            kind: .expense,
            category: .food,
            occurredAt: try #require(
                DateComponents(calendar: calendar, year: 2026, month: 4, day: 7, hour: 12).date
            )
        ),
    ]
    let state = TransactionFeature.State(
        transactions: IdentifiedArray(uniqueElements: transactions),
        historyReferenceDate: referenceDate
    )

    #expect(state.timeSpendingAnalysis.peakWeekdays.first?.weekday == fridayWeekday)
    #expect(state.timeSpendingAnalysis.peakHours.first?.hour == 21)
    #expect(state.timeSpendingAnalysis.eveningSpike?.amount == 1_250_000)
}

@Test("derives no-spend tracker summary")
func derivesNoSpendTrackerSummary() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26).date
    )
    let firstExpenseDate = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 21).date
    )
    let secondExpenseDate = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 24).date
    )
    let transactions = [
        Transaction(
            amount: 45_000,
            kind: .expense,
            category: .food,
            occurredAt: firstExpenseDate
        ),
        Transaction(
            amount: 75_000,
            kind: .expense,
            category: .transport,
            occurredAt: secondExpenseDate
        ),
    ]
    let state = TransactionFeature.State(
        transactions: IdentifiedArray(uniqueElements: transactions),
        historyReferenceDate: referenceDate
    )

    #expect(state.noSpendSummary.currentStreak == 2)
    #expect(state.noSpendSummary.noSpendDaysInMonth == 24)
    #expect(state.noSpendSummary.longestStreak == 20)
}

@Test("derives CSV export payload")
func derivesCSVExportPayload() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26).date
    )
    let transactionDate = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 25).date
    )
    let transaction = Transaction(
        amount: 45_000,
        kind: .expense,
        category: .food,
        occurredAt: transactionDate,
        note: "Cà phê, sáng"
    )
    let state = TransactionFeature.State(
        transactions: IdentifiedArray(uniqueElements: [transaction]),
        historyReferenceDate: referenceDate
    )

    #expect(state.csvExport.fileName == "kaso-transactions-2026-04-26.csv")
    #expect(state.csvExport.transactionCount == 1)
    #expect(state.csvExport.csvText.hasPrefix("amount,kind,category_id,category_name,occurred_at,note,receipt_id"))
    #expect(state.csvExport.csvText.contains("\"Cà phê, sáng\""))
}

@MainActor
@Test("imports PDF bank statement transactions")
func importsPDFBankStatementTransactions() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let date = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26).date
    )
    let transactionID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000004"))
    let expectedTransaction = Transaction(
        id: transactionID,
        amount: 120_000,
        kind: .expense,
        category: .food,
        occurredAt: date,
        note: "Highlands Coffee"
    )
    let expectedSummary = BankStatementImportSummary(
        importedCount: 1,
        skippedLineCount: 0,
        totalLineCount: 1
    )
    let recorder = TransactionSaveRecorder()
    let store = TestStore(initialState: TransactionFeature.State()) {
        TransactionFeature()
    } withDependencies: {
        $0.date.now = date
        $0.uuid = .constant(transactionID)
        $0.bankStatementPDFClient.extractText = { data in
            #expect(data == Data([9, 8, 7]))
            return "26/04/2026 Highlands Coffee -120.000 VND"
        }
        $0.transactionRepository.save = { transaction in
            await recorder.save(transaction)
        }
    }

    await store.send(.bankStatementImportButtonTapped) {
        $0.isBankStatementImporterPresented = true
        $0.bankStatementImportErrorMessageKey = nil
    }
    await store.send(.bankStatementPDFDataSelected(Data([9, 8, 7]))) {
        $0.isBankStatementImporterPresented = false
        $0.isBankStatementImporting = true
        $0.bankStatementImportSummary = nil
        $0.bankStatementImportErrorMessageKey = nil
        $0.errorMessageKey = nil
    }
    await store.receive(.bankStatementImported([expectedTransaction], expectedSummary)) {
        $0.isBankStatementImporting = false
        $0.bankStatementImportSummary = expectedSummary
        $0.transactions.insert(expectedTransaction, at: 0)
        $0.summary = MonthlyTransactionSummary(
            income: 0,
            expense: 120_000,
            balance: -120_000
        )
        $0.categorySpendings = [
            MonthlyCategorySpending(
                category: .food,
                amount: 120_000,
                fraction: 1
            ),
        ]
    }

    #expect(await recorder.transactions() == [expectedTransaction])
}

@MainActor
@Test("shows PDF bank statement import error for empty parse result")
func showsPDFBankStatementImportErrorForEmptyParseResult() async throws {
    let store = TestStore(initialState: TransactionFeature.State()) {
        TransactionFeature()
    } withDependencies: {
        $0.bankStatementPDFClient.extractText = { _ in "Ngày GD Nội dung Số tiền" }
    }

    await store.send(.bankStatementPDFDataSelected(Data([1]))) {
        $0.isBankStatementImporting = true
        $0.bankStatementImportSummary = nil
        $0.bankStatementImportErrorMessageKey = nil
        $0.errorMessageKey = nil
    }
    await store.receive(.bankStatementImportFailed("transactions.import.error.empty")) {
        $0.isBankStatementImporting = false
        $0.bankStatementImportErrorMessageKey = "transactions.import.error.empty"
    }
}

private actor TransactionSaveRecorder {
    private var savedTransactions: [Transaction] = []

    func save(_ transaction: Transaction) {
        savedTransactions.append(transaction)
    }

    func transactions() -> [Transaction] {
        savedTransactions
    }
}

private actor SubscriptionReminderRecorder {
    private var savedReminders: [SubscriptionRenewalReminder] = []

    func save(_ reminders: [SubscriptionRenewalReminder]) {
        savedReminders = reminders
    }

    func reminders() -> [SubscriptionRenewalReminder] {
        savedReminders
    }
}

private actor SavingGoalRecorder {
    private var savedGoals: [SavingGoal] = []

    func save(_ goal: SavingGoal) {
        savedGoals.append(goal)
    }

    func goals() -> [SavingGoal] {
        savedGoals
    }
}

private actor SavingGoalDeleteRecorder {
    private var deletedIDs: [UUID] = []

    func save(_ id: UUID) {
        deletedIDs.append(id)
    }

    func ids() -> [UUID] {
        deletedIDs
    }
}
