import Foundation

/// Parses a Vietnamese/English natural-language query into a keyword plus an
/// optional date interval. Handles common phrases like "tuần trước", "tháng 3",
/// "last week", "this month", "yesterday", and "tháng này".
///
/// Recognised phrases are stripped from the keyword so feature consumers can
/// apply both filters at once.
public enum SmartSearchParser {
    private static let datePhrases: [(patterns: [String], makeInterval: @Sendable (Date, Calendar) -> DateInterval?)] = [
        (["hôm nay", "today"], { now, calendar in
            calendar.dateInterval(of: .day, for: now)
        }),
        (["hôm qua", "yesterday"], { now, calendar in
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now) else { return nil }
            return calendar.dateInterval(of: .day, for: yesterday)
        }),
        (["tuần này", "this week"], { now, calendar in
            calendar.dateInterval(of: .weekOfYear, for: now)
        }),
        (["tuần trước", "tuần rồi", "last week"], { now, calendar in
            guard let priorDate = calendar.date(byAdding: .weekOfYear, value: -1, to: now) else {
                return nil
            }
            return calendar.dateInterval(of: .weekOfYear, for: priorDate)
        }),
        (["tháng này", "this month"], { now, calendar in
            calendar.dateInterval(of: .month, for: now)
        }),
        (["tháng trước", "last month"], { now, calendar in
            guard let priorDate = calendar.date(byAdding: .month, value: -1, to: now) else {
                return nil
            }
            return calendar.dateInterval(of: .month, for: priorDate)
        }),
        (["năm nay", "this year"], { now, calendar in
            calendar.dateInterval(of: .year, for: now)
        }),
        (["năm trước", "năm ngoái", "last year"], { now, calendar in
            guard let priorDate = calendar.date(byAdding: .year, value: -1, to: now) else {
                return nil
            }
            return calendar.dateInterval(of: .year, for: priorDate)
        }),
    ]

    public static func parse(
        _ rawText: String,
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> SmartSearchQuery {
        var working = rawText.lowercased()
        var matched: DateInterval?

        // Try named phrases first.
        for entry in datePhrases {
            for phrase in entry.patterns where working.contains(phrase) {
                matched = entry.makeInterval(referenceDate, calendar)
                working = working.replacingOccurrences(of: phrase, with: " ")
                break
            }
            if matched != nil { break }
        }

        // "tháng <n>" / "month <n>" — month within current calendar year.
        if matched == nil {
            if let monthInterval = extractMonth(
                from: &working,
                referenceDate: referenceDate,
                calendar: calendar
            ) {
                matched = monthInterval
            }
        }

        let keyword = working
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return SmartSearchQuery(
            rawText: rawText,
            keyword: keyword,
            dateRange: matched
        )
    }

    private static func extractMonth(
        from text: inout String,
        referenceDate: Date,
        calendar: Calendar
    ) -> DateInterval? {
        for prefix in ["tháng ", "month "] {
            guard let range = text.range(of: prefix) else { continue }
            let afterPrefix = text[range.upperBound...]
            let digits = afterPrefix.prefix(2).prefix { $0.isNumber }
            guard digits.isEmpty == false, let month = Int(digits), (1 ... 12).contains(month) else {
                continue
            }
            let year = calendar.component(.year, from: referenceDate)
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = 1
            guard
                let monthStart = calendar.date(from: components),
                let interval = calendar.dateInterval(of: .month, for: monthStart)
            else { continue }
            let matchedSubstring = prefix + digits
            text = text.replacingOccurrences(of: matchedSubstring, with: " ")
            return interval
        }
        return nil
    }
}
