import Foundation

enum RegretFormatters {
    static func currency(_ amount: Decimal) -> String {
        amount.formatted(.currency(code: "VND"))
    }
}
