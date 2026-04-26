import Foundation

public extension Decimal {
    func kasoCurrencyFormatted(
        code: String = "VND",
        locale: Locale = .current
    ) -> String {
        formatted(.currency(code: code).locale(locale))
    }
}
