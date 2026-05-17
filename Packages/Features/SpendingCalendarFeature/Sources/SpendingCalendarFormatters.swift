import Foundation

enum SpendingCalendarFormatters {
    static func currency(_ amount: Decimal) -> String {
        amount.formatted(.currency(code: "VND"))
    }
}
