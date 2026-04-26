import Foundation

public struct BankStatementParseResult: Equatable, Sendable {
    public let drafts: [TransactionDraft]
    public let skippedLineCount: Int
    public let totalLineCount: Int

    public init(
        drafts: [TransactionDraft],
        skippedLineCount: Int,
        totalLineCount: Int
    ) {
        self.drafts = drafts
        self.skippedLineCount = skippedLineCount
        self.totalLineCount = totalLineCount
    }
}

public enum BankStatementParser {
    public static func parse(
        text: String,
        calendar: Calendar = .current
    ) -> BankStatementParseResult {
        let lines = text
            .components(separatedBy: .newlines)
            .map(normalizeWhitespace)
            .filter { $0.isEmpty == false }

        let drafts = lines.compactMap { line in
            parseLine(line, calendar: calendar)
        }

        return BankStatementParseResult(
            drafts: drafts,
            skippedLineCount: lines.count - drafts.count,
            totalLineCount: lines.count
        )
    }

    private static func parseLine(
        _ line: String,
        calendar: Calendar
    ) -> TransactionDraft? {
        guard let dateMatch = date(in: line, calendar: calendar) else {
            return nil
        }

        let candidates = amountCandidates(in: line)
            .filter { $0.range.overlaps(dateMatch.range) == false }
            .sorted { $0.range.lowerBound < $1.range.lowerBound }
        guard let amountCandidate = selectedAmountCandidate(
            from: candidates,
            normalizedLine: line.normalizedForBankStatement
        ) else {
            return nil
        }

        let normalizedLine = line.normalizedForBankStatement
        let kind = kind(for: amountCandidate.sign, normalizedLine: normalizedLine)
        let note = note(
            in: line,
            dateRange: dateMatch.range,
            amountCandidates: candidates,
            selectedAmountCandidate: amountCandidate
        )

        return TransactionDraft(
            amount: amountCandidate.amount,
            kind: kind,
            category: category(for: kind, normalizedLine: normalizedLine),
            occurredAt: dateMatch.date,
            note: note
        )
    }

    private static func selectedAmountCandidate(
        from candidates: [AmountCandidate],
        normalizedLine: String
    ) -> AmountCandidate? {
        if let signedCandidate = candidates.first(where: { $0.sign != nil }) {
            return signedCandidate
        }

        if containsKeyword(in: normalizedLine, keywords: incomeKeywords + expenseKeywords) {
            return candidates.first
        }

        return candidates.first
    }

    private static func kind(
        for sign: Character?,
        normalizedLine: String
    ) -> TransactionKind {
        switch sign {
        case "+":
            return .income
        case "-":
            return .expense
        default:
            if containsKeyword(in: normalizedLine, keywords: incomeKeywords) {
                return .income
            }

            return .expense
        }
    }

    private static func category(
        for kind: TransactionKind,
        normalizedLine: String
    ) -> TransactionCategory {
        switch kind {
        case .income:
            .salary
        case .expense:
            if containsKeyword(in: normalizedLine, keywords: foodKeywords) {
                .food
            } else if containsKeyword(in: normalizedLine, keywords: transportKeywords) {
                .transport
            } else if containsKeyword(in: normalizedLine, keywords: housingKeywords) {
                .housing
            } else if containsKeyword(in: normalizedLine, keywords: entertainmentKeywords) {
                .entertainment
            } else if containsKeyword(in: normalizedLine, keywords: healthKeywords) {
                .health
            } else if containsKeyword(in: normalizedLine, keywords: educationKeywords) {
                .education
            } else if containsKeyword(in: normalizedLine, keywords: shoppingKeywords) {
                .shopping
            } else {
                .other
            }
        }
    }

    private static func note(
        in line: String,
        dateRange: Range<String.Index>,
        amountCandidates: [AmountCandidate],
        selectedAmountCandidate: AmountCandidate
    ) -> String? {
        let removableAmountRanges = amountCandidates
            .filter { candidate in
                candidate == selectedAmountCandidate
                    || candidate.sign != nil
                    || candidate.hasCurrencyMarker
                    || candidate.hasGroupingSeparator
            }
            .map(\.range)
        let ranges = ([dateRange] + removableAmountRanges)
            .sorted { $0.lowerBound > $1.lowerBound }

        var note = line
        for range in ranges {
            note.removeSubrange(range)
        }

        let redactedNote = redactAccountLikeNumbers(in: normalizeWhitespace(note))
            .trimmingCharacters(in: CharacterSet(charactersIn: "-+|,;: "))

        return redactedNote.isEmpty ? nil : redactedNote
    }

    private static func date(
        in line: String,
        calendar: Calendar
    ) -> DateMatch? {
        if let match = date(
            in: line,
            pattern: #"(?<!\d)(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})(?!\d)"#,
            calendar: calendar,
            componentOrder: .dayMonthYear
        ) {
            return match
        }

        return date(
            in: line,
            pattern: #"(?<!\d)(\d{4})[/-](\d{1,2})[/-](\d{1,2})(?!\d)"#,
            calendar: calendar,
            componentOrder: .yearMonthDay
        )
    }

    private static func date(
        in line: String,
        pattern: String,
        calendar: Calendar,
        componentOrder: DateComponentOrder
    ) -> DateMatch? {
        guard let match = firstMatch(in: line, pattern: pattern) else {
            return nil
        }

        let components = match.captures.compactMap { capture -> Int? in
            guard let capture else {
                return nil
            }

            return Int(capture)
        }
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

        guard let date = DateComponents(
            calendar: calendar,
            year: year,
            month: month,
            day: day
        ).date else {
            return nil
        }

        return DateMatch(date: date, range: match.range)
    }

    private static func amountCandidates(in line: String) -> [AmountCandidate] {
        matches(
            in: line,
            pattern: #"(?<![\d/])([+-])?\s*(\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{1,2})?|\d{4,12}(?:[.,]\d{1,2})?)(?:\s*(₫|đ|d|vnd))?(?![\d/])"#
        ).compactMap { match in
            guard
                let amountText = match.capture(at: 1),
                let amount = TransactionAmountParser.parse(amountText),
                amount > 0
            else {
                return nil
            }

            let sign = match.capture(at: 0)?.first
            return AmountCandidate(
                amount: amount,
                sign: sign,
                range: match.range,
                hasCurrencyMarker: match.capture(at: 2) != nil,
                hasGroupingSeparator: amountText.contains(".") || amountText.contains(",")
            )
        }
    }

    private static func matches(
        in input: String,
        pattern: String
    ) -> [RegularExpressionMatch] {
        guard let regularExpression = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive]
        ) else {
            return []
        }

        let range = NSRange(input.startIndex ..< input.endIndex, in: input)
        return regularExpression.matches(in: input, range: range).compactMap { match in
            regularExpressionMatch(match, in: input)
        }
    }

    private static func firstMatch(
        in input: String,
        pattern: String
    ) -> RegularExpressionMatch? {
        guard let regularExpression = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let range = NSRange(input.startIndex ..< input.endIndex, in: input)
        guard let match = regularExpression.firstMatch(in: input, range: range) else {
            return nil
        }

        return regularExpressionMatch(match, in: input)
    }

    private static func regularExpressionMatch(
        _ match: NSTextCheckingResult,
        in input: String
    ) -> RegularExpressionMatch? {
        guard let range = Range(match.range, in: input) else {
            return nil
        }

        let captures = (1 ..< match.numberOfRanges).map { index -> String? in
            guard let range = Range(match.range(at: index), in: input) else {
                return nil
            }

            return String(input[range])
        }

        return RegularExpressionMatch(range: range, captures: captures)
    }

    private static func containsKeyword(
        in normalizedLine: String,
        keywords: [String]
    ) -> Bool {
        keywords.contains { normalizedLine.contains($0) }
    }

    private static func normalizeWhitespace(_ input: String) -> String {
        input
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func redactAccountLikeNumbers(in input: String) -> String {
        guard let regularExpression = try? NSRegularExpression(pattern: #"\d{6,}"#) else {
            return input
        }

        let range = NSRange(input.startIndex ..< input.endIndex, in: input)
        return regularExpression.stringByReplacingMatches(
            in: input,
            range: range,
            withTemplate: "••••"
        )
    }

    private static func normalizedYear(_ year: Int) -> Int {
        year < 100 ? 2_000 + year : year
    }

    private static let incomeKeywords = [
        "ghi co",
        "bao co",
        "credit",
        "nhan",
        "luong",
        "salary",
        "payroll",
        "refund",
        "hoan tien",
        "interest",
        "lai tien gui",
    ]
    private static let expenseKeywords = [
        "ghi no",
        "debit",
        "thanh toan",
        "payment",
        "purchase",
        "rut tien",
        "chuyen tien",
        "pos",
        "phi ",
        "fee",
    ]
    private static let foodKeywords = [
        "an uong",
        "ca phe",
        "cafe",
        "coffee",
        "highlands",
        "phuc long",
        "starbucks",
        "restaurant",
        "nha hang",
        "grabfood",
        "shopeefood",
        "befood",
        "food",
    ]
    private static let transportKeywords = [
        "grab",
        "taxi",
        "bike",
        "bus",
        "xang",
        "be ",
        "gojek",
        "ve xe",
    ]
    private static let housingKeywords = [
        "tien nha",
        "rent",
        "dien",
        "nuoc",
        "internet",
        "wifi",
    ]
    private static let entertainmentKeywords = [
        "netflix",
        "spotify",
        "cinema",
        "movie",
        "rap phim",
        "game",
    ]
    private static let healthKeywords = [
        "benh vien",
        "phong kham",
        "nha thuoc",
        "doctor",
        "clinic",
        "medicine",
        "health",
    ]
    private static let educationKeywords = [
        "hoc phi",
        "school",
        "course",
        "education",
        "book",
        "sach",
    ]
    private static let shoppingKeywords = [
        "shopee",
        "lazada",
        "tiki",
        "shopping",
        "mua sam",
        "store",
        "mall",
        "winmart",
    ]
}

private struct AmountCandidate: Equatable {
    let amount: Decimal
    let sign: Character?
    let range: Range<String.Index>
    let hasCurrencyMarker: Bool
    let hasGroupingSeparator: Bool
}

private struct DateMatch {
    let date: Date
    let range: Range<String.Index>
}

private struct RegularExpressionMatch {
    let range: Range<String.Index>
    let captures: [String?]

    func capture(at index: Int) -> String? {
        guard captures.indices.contains(index) else {
            return nil
        }

        return captures[index]
    }
}

private enum DateComponentOrder {
    case dayMonthYear
    case yearMonthDay
}

private extension String {
    var normalizedForBankStatement: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
    }
}
