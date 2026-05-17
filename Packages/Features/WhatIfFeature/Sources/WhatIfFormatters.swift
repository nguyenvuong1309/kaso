import Foundation

enum WhatIfFormatters {
    static func currency(_ amount: Decimal) -> String {
        amount.formatted(.currency(code: "VND"))
    }

    static func signedCurrency(_ amount: Decimal) -> String {
        let prefix: String = if amount > 0 {
            "+"
        } else if amount < 0 {
            "−"
        } else {
            ""
        }
        let magnitude = amount < 0 ? -amount : amount
        return "\(prefix)\(currency(magnitude))"
    }
}
