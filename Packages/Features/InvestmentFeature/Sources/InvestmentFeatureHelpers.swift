import Foundation
import InvestmentDomain

extension HoldingValidationError {
    var messageKey: String {
        switch self {
        case .symbolRequired:
            "investment.error.symbolRequired"
        case .nameRequired:
            "investment.error.nameRequired"
        case .lotsRequired:
            "investment.error.lotsRequired"
        case .lotQuantityMustBePositive:
            "investment.error.quantityMustBePositive"
        case .lotCostBasisCannotBeNegative:
            "investment.error.costBasisCannotBeNegative"
        }
    }
}

extension TargetAllocationValidationError {
    var messageKey: String {
        switch self {
        case .sumMustEqual100Percent:
            "investment.target.error.sumMustEqual100"
        case .fractionMustBeNonNegative:
            "investment.target.error.fractionMustBeNonNegative"
        }
    }
}

enum InvestmentFeatureFormatters {
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

    static func parseOptionalDecimal(_ text: String) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : parseDecimal(trimmed)
    }

    static func parsePercentFraction(_ text: String) -> Double? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard normalized.isEmpty == false, let value = Double(normalized) else {
            return nil
        }
        return value / 100
    }

    static func decimalText(_ amount: Decimal) -> String {
        NSDecimalNumber(decimal: amount).stringValue
    }

    static func percentText(_ fraction: Double) -> String {
        let percent = fraction * 100
        if percent.rounded() == percent {
            return String(Int(percent))
        }
        return String(format: "%.1f", percent)
    }
}
