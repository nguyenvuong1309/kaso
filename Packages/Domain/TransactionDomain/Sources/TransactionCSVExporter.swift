import Foundation

public enum TransactionCSVExporter {
    public static func export(_ transactions: [Transaction]) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        let rows = transactions.map { transaction in
            [
                amountString(transaction.amount),
                transaction.kind.rawValue,
                transaction.category.id,
                transaction.category.nameKey,
                formatter.string(from: transaction.occurredAt),
                transaction.note ?? "",
                transaction.receiptImageIdentifier ?? "",
            ]
            .map(escapedField)
            .joined(separator: ",")
        }

        return ([header] + rows).joined(separator: "\n")
    }

    private static let header = [
        "amount",
        "kind",
        "category_id",
        "category_name",
        "occurred_at",
        "note",
        "receipt_id",
    ].joined(separator: ",")

    private static func amountString(_ amount: Decimal) -> String {
        NSDecimalNumber(decimal: amount).stringValue
    }

    private static func escapedField(_ field: String) -> String {
        let escapedField = field.replacingOccurrences(of: "\"", with: "\"\"")
        guard escapedField.contains(",")
            || escapedField.contains("\"")
            || escapedField.contains("\n")
            || escapedField.contains("\r")
        else {
            return escapedField
        }

        return "\"\(escapedField)\""
    }
}
