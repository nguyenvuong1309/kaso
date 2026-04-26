import Foundation
import Testing
import ComposableArchitecture
import BudgetDomain
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
