import Foundation

enum CoolingOffFormatters {
    static func currency(_ amount: Decimal) -> String {
        amount.formatted(.currency(code: "VND"))
    }

    static func duration(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds.rounded())
        let days = totalSeconds / 86_400
        let hours = (totalSeconds % 86_400) / 3_600
        let minutes = (totalSeconds % 3_600) / 60

        if days > 0 {
            return "\(days)d \(hours)h"
        }
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(max(minutes, 1))m"
    }
}
