import Foundation

public enum ReceiptOCRParser {
    public static func parse(
        lines: [String],
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> ReceiptOCRResult {
        let normalizedLines = lines
            .map(normalizeWhitespace)
            .filter { $0.isEmpty == false }

        return ReceiptOCRResult(
            merchantName: merchantName(in: normalizedLines),
            amount: amount(in: normalizedLines),
            occurredAt: occurredAt(
                in: normalizedLines,
                referenceDate: referenceDate,
                calendar: calendar
            ),
            rawText: normalizedLines.joined(separator: "\n")
        )
    }

    private static func merchantName(in lines: [String]) -> String? {
        lines.first { line in
            let normalizedLine = line.normalizedForReceiptOCR
            return normalizedLine.count >= 3
                && containsAmountKeyword(normalizedLine) == false
                && containsDate(line) == false
                && containsCurrencyMarker(normalizedLine) == false
                && line.filter(\.isNumber).count < 4
        }
    }

    private static func amount(in lines: [String]) -> Decimal? {
        lines.enumerated()
            .flatMap { index, line in
                amountCandidates(in: line, lineIndex: index)
            }
            .max { lhs, rhs in
                if lhs.score == rhs.score {
                    lhs.amount < rhs.amount
                } else {
                    lhs.score < rhs.score
                }
            }?
            .amount
    }

    private static func amountCandidates(
        in line: String,
        lineIndex: Int
    ) -> [AmountCandidate] {
        let normalizedLine = line.normalizedForReceiptOCR
        let hasAmountKeyword = containsAmountKeyword(normalizedLine)
        let hasCurrencyMarker = containsCurrencyMarker(normalizedLine)
        let matches = matches(
            in: line,
            pattern: #"(?<!\d)(?:\d{1,3}(?:[.,]\d{3})+|\d{4,9})(?:\s?(?:₫|đ|d|vnd))?"#
        )

        return matches.compactMap { match in
            guard let amount = TransactionAmountParser.parse(match), amount > 0 else {
                return nil
            }

            var score = min(lineIndex, 100) * -1
            if hasAmountKeyword {
                score += 10_000
            }
            if hasCurrencyMarker || containsCurrencyMarker(match.normalizedForReceiptOCR) {
                score += 1_000
            }

            let amountScore = min((NSDecimalNumber(decimal: amount).intValue / 1_000), 500)
            score += amountScore

            return AmountCandidate(amount: amount, score: score)
        }
    }

    private static func occurredAt(
        in lines: [String],
        referenceDate: Date,
        calendar: Calendar
    ) -> Date? {
        for line in lines {
            if let date = date(from: line, calendar: calendar) {
                return date
            }
        }

        return calendar.startOfDay(for: referenceDate)
    }

    private static func date(
        from line: String,
        calendar: Calendar
    ) -> Date? {
        if let date = date(
            from: line,
            pattern: #"(?<!\d)(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})(?!\d)"#,
            calendar: calendar,
            componentOrder: .dayMonthYear
        ) {
            return date
        }

        return date(
            from: line,
            pattern: #"(?<!\d)(\d{4})[/-](\d{1,2})[/-](\d{1,2})(?!\d)"#,
            calendar: calendar,
            componentOrder: .yearMonthDay
        )
    }

    private static func date(
        from line: String,
        pattern: String,
        calendar: Calendar,
        componentOrder: DateComponentOrder
    ) -> Date? {
        guard let match = firstMatch(in: line, pattern: pattern) else {
            return nil
        }

        let components = match.compactMap(Int.init)
        guard components.count == 3 else {
            return nil
        }

        let day: Int
        let month: Int
        let year: Int
        switch componentOrder {
        case .dayMonthYear:
            day = components[0]
            month = components[1]
            year = normalizedYear(components[2])
        case .yearMonthDay:
            year = normalizedYear(components[0])
            month = components[1]
            day = components[2]
        }

        return DateComponents(
            calendar: calendar,
            year: year,
            month: month,
            day: day
        ).date
    }

    private static func containsDate(_ line: String) -> Bool {
        date(from: line, calendar: Calendar(identifier: .gregorian)) != nil
    }

    private static func containsAmountKeyword(_ normalizedLine: String) -> Bool {
        amountKeywords.contains {
            normalizedLine.contains($0)
        }
    }

    private static func containsCurrencyMarker(_ normalizedLine: String) -> Bool {
        currencyMarkers.contains {
            normalizedLine.contains($0)
        }
    }

    private static func normalizedYear(_ year: Int) -> Int {
        year < 100 ? 2_000 + year : year
    }

    private static func normalizeWhitespace(_ input: String) -> String {
        input
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func matches(
        in input: String,
        pattern: String
    ) -> [String] {
        guard let regularExpression = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive]
        ) else {
            return []
        }

        let range = NSRange(input.startIndex ..< input.endIndex, in: input)
        return regularExpression.matches(in: input, range: range).compactMap { match in
            guard let range = Range(match.range, in: input) else {
                return nil
            }

            return String(input[range])
        }
    }

    private static func firstMatch(
        in input: String,
        pattern: String
    ) -> [String]? {
        guard let regularExpression = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let range = NSRange(input.startIndex ..< input.endIndex, in: input)
        guard let match = regularExpression.firstMatch(in: input, range: range) else {
            return nil
        }

        return (1 ..< match.numberOfRanges).compactMap { index in
            guard let range = Range(match.range(at: index), in: input) else {
                return nil
            }

            return String(input[range])
        }
    }

    private static let amountKeywords = [
        "tong",
        "total",
        "amount",
        "thanh toan",
        "payment",
        "cong",
    ]
    private static let currencyMarkers = ["₫", "đ", " vnd", "vnd"]
}

private struct AmountCandidate: Equatable {
    var amount: Decimal
    var score: Int
}

private enum DateComponentOrder {
    case dayMonthYear
    case yearMonthDay
}

private extension String {
    var normalizedForReceiptOCR: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
    }
}
