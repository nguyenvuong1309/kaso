import Foundation
import PhantomExpenseDomain

extension PhantomExpenseValidationError {
    var messageKey: String {
        switch self {
        case .titleRequired:
            "phantom.error.titleRequired"
        case .amountMustBePositive:
            "phantom.error.amountMustBePositive"
        }
    }
}

enum PhantomExpenseFeatureFormatters {
    static func parseAmount(_ text: String) -> Decimal? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
        guard normalized.isEmpty == false else {
            return nil
        }
        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }

    static func amountText(_ amount: Decimal) -> String {
        NSDecimalNumber(decimal: amount).stringValue
    }
}
