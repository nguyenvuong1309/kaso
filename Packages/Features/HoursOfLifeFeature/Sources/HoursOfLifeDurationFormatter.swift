import Foundation
import WellnessDomain

enum HoursOfLifeDurationFormatter {
    static func duration(for conversion: HoursOfLifeConversion) -> String {
        let hours = conversion.wholeHours
        let minutes = conversion.remainingMinutes

        if hours == 0, minutes == 0 {
            let formatString = String(
                localized: "hoursOfLife.duration.minutes",
                defaultValue: "%lld phút",
                bundle: .module
            )
            return String(format: formatString, locale: .current, 0)
        }

        if hours == 0 {
            let formatString = String(
                localized: "hoursOfLife.duration.minutes",
                defaultValue: "%lld phút",
                bundle: .module
            )
            return String(format: formatString, locale: .current, minutes)
        }

        if minutes == 0 {
            let formatString = String(
                localized: "hoursOfLife.duration.hours",
                defaultValue: "%lld giờ",
                bundle: .module
            )
            return String(format: formatString, locale: .current, hours)
        }

        let formatString = String(
            localized: "hoursOfLife.duration.hoursMinutes",
            defaultValue: "%lld giờ %lld phút",
            bundle: .module
        )
        return String(format: formatString, locale: .current, hours, minutes)
    }

    static func hoursPerMonth(_ hours: Decimal) -> String {
        let value = NSDecimalNumber(decimal: hours)
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        let formatted = formatter.string(from: value) ?? value.stringValue
        let formatString = String(
            localized: "hoursOfLife.rate.workHours.format",
            defaultValue: "%@ giờ/tháng",
            bundle: .module
        )
        return String(format: formatString, locale: .current, formatted)
    }
}
