import Foundation

enum RoundUpFormatters {
    static func currency(_ amount: Decimal) -> String {
        amount.formatted(.currency(code: "VND"))
    }

    static func accessibilityCurrency(_ amount: Decimal) -> String {
        amount.formatted(.currency(code: "VND").presentation(.fullName))
    }
}
