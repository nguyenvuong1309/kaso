import AppIntents
import Foundation
import TransactionDomain

public struct LogExpenseIntent: AppIntent {
    public static let title: LocalizedStringResource = "Ghi chi tiêu nhanh"

    public static let description = IntentDescription(
        "Ghi nhanh một khoản chi tiêu vào Kaso bằng cách chọn danh mục và nhập số tiền."
    )

    public static let openAppWhenRun: Bool = false
    public static let isDiscoverable: Bool = true

    @Parameter(
        title: "Danh mục",
        description: "Danh mục chi tiêu",
        default: nil
    )
    public var category: TransactionCategoryEntity?

    @Parameter(
        title: "Số tiền",
        description: "Số tiền chi (VND)",
        controlStyle: .field,
        inclusiveRange: (1, 1_000_000_000_000)
    )
    public var amount: Double

    public init() {}

    public init(category: TransactionCategoryEntity?, amount: Double) {
        self.category = category
        self.amount = amount
    }

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let resolvedCategory = try await resolveCategory()
        let draft = TransactionDraft(
            amount: Decimal(amount),
            kind: .expense,
            category: resolvedCategory.toDomain(),
            occurredAt: Date()
        )
        let transaction = try draft.validated()
        try await QuickEntryIntentEnvironment.transactionRepository.save(transaction)

        let formattedAmount = transaction.amount.formatted(.currency(code: "VND"))
        let categoryTitle = String(localized: resolvedCategory.localizedName)
        let dialog = IntentDialog(
            "Đã ghi \(formattedAmount) cho \(categoryTitle)."
        )
        return .result(dialog: dialog)
    }

    private func resolveCategory() async throws -> TransactionCategoryEntity {
        if let category { return category }
        let prompt = IntentDialog("Chọn danh mục chi tiêu")
        return try await $category.requestDisambiguation(
            among: ExpenseCategoryQuery().suggestedEntities(),
            dialog: prompt
        )
    }
}
