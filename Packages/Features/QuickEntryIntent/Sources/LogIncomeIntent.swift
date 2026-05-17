import AppIntents
import Foundation
import TransactionDomain

public struct LogIncomeIntent: AppIntent {
    public static let title: LocalizedStringResource = "Ghi thu nhập nhanh"

    public static let description = IntentDescription(
        "Ghi nhanh một khoản thu nhập vào Kaso bằng cách chọn danh mục và nhập số tiền."
    )

    public static let openAppWhenRun: Bool = false
    public static let isDiscoverable: Bool = true

    @Parameter(
        title: "Danh mục",
        description: "Danh mục thu nhập",
        default: nil
    )
    public var category: IncomeCategoryEntity?

    @Parameter(
        title: "Số tiền",
        description: "Số tiền thu (VND)",
        controlStyle: .field,
        inclusiveRange: (1, 1_000_000_000_000)
    )
    public var amount: Double

    public init() {}

    public init(category: IncomeCategoryEntity?, amount: Double) {
        self.category = category
        self.amount = amount
    }

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let resolvedCategory = try await resolveCategory()
        let draft = TransactionDraft(
            amount: Decimal(amount),
            kind: .income,
            category: resolvedCategory.toDomain(),
            occurredAt: Date()
        )
        let transaction = try draft.validated()
        try await QuickEntryIntentEnvironment.transactionRepository.save(transaction)

        let formattedAmount = transaction.amount.formatted(.currency(code: "VND"))
        let categoryTitle = String(localized: resolvedCategory.localizedName)
        let dialog = IntentDialog(
            "Đã ghi thu nhập \(formattedAmount) — \(categoryTitle)."
        )
        return .result(dialog: dialog)
    }

    private func resolveCategory() async throws -> IncomeCategoryEntity {
        if let category { return category }
        let prompt = IntentDialog("Chọn danh mục thu nhập")
        return try await $category.requestDisambiguation(
            among: IncomeCategoryQuery().suggestedEntities(),
            dialog: prompt
        )
    }
}
