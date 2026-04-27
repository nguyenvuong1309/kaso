import Foundation
import SwiftUI
import WellnessDomain

extension View {
    @ViewBuilder
    func kasoDecimalKeyboard() -> some View {
        #if os(iOS)
        keyboardType(.decimalPad)
        #else
        self
        #endif
    }
}

extension HoursOfLifeConfigurationValidationError {
    var messageKey: String {
        switch self {
        case .incomeMustBePositive:
            "hoursOfLife.error.incomeMustBePositive"
        case .workHoursMustBePositive:
            "hoursOfLife.error.workHoursMustBePositive"
        case .workHoursTooHigh:
            "hoursOfLife.error.workHoursTooHigh"
        }
    }
}

enum HoursOfLifeFeatureFormatters {
    static let standardMonthlyWorkHours: Decimal = 160

    static func parseDecimal(_ text: String) -> Decimal? {
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

    static func hoursText(_ hours: Decimal) -> String {
        NSDecimalNumber(decimal: hours).stringValue
    }
}
