import Foundation

public enum TransactionAmountFormatter {
    public static func formatForEditing(
        _ input: String,
        groupingSeparator: String = "."
    ) -> String {
        let digits = input
            .compactMap(\.wholeNumberValue)
            .map(String.init)
            .joined()
        guard digits.isEmpty == false else {
            return ""
        }

        let normalizedDigits = digits.drop(while: { $0 == "0" })
        let amountDigits = normalizedDigits.isEmpty ? "0" : String(normalizedDigits)

        return grouped(
            amountDigits,
            separator: groupingSeparator
        )
    }

    private static func grouped(
        _ digits: String,
        separator: String
    ) -> String {
        var groups: [Substring] = []
        var endIndex = digits.endIndex

        while endIndex > digits.startIndex {
            let startIndex = digits.index(
                endIndex,
                offsetBy: -3,
                limitedBy: digits.startIndex
            ) ?? digits.startIndex

            groups.append(digits[startIndex ..< endIndex])
            endIndex = startIndex
        }

        return groups.reversed().joined(separator: separator)
    }
}
