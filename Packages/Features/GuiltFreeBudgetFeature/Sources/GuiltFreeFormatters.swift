import Foundation

enum GuiltFreeFormatters {
    static func currency(_ amount: Decimal) -> String {
        amount.formatted(.currency(code: "VND"))
    }
}
