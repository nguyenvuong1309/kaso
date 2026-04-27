import Foundation

enum FreelancerFeatureFormatters {
    static func parseDecimal(_ text: String) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            return nil
        }

        let normalized = trimmed
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")

        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }

    static func parseDouble(_ text: String) -> Double? {
        guard let decimal = parseDecimal(text) else {
            return nil
        }
        return NSDecimalNumber(decimal: decimal).doubleValue
    }

    static func amountText(_ amount: Decimal) -> String {
        NSDecimalNumber(decimal: amount).stringValue
    }

    static func percentText(_ rate: Double?) -> String {
        guard let rate else {
            return ""
        }
        return NSDecimalNumber(value: rate * 100).stringValue
    }

    static func currency(_ amount: Decimal) -> String {
        amount.formatted(.currency(code: "VND"))
    }

    static func months(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(1)))
    }
}
