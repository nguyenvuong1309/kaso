import Foundation

public struct VoiceTransactionParseResult: Equatable, Sendable {
    public let amount: Decimal
    public let kind: TransactionKind
    public let category: TransactionCategory
    public let note: String?

    public init(
        amount: Decimal,
        kind: TransactionKind,
        category: TransactionCategory,
        note: String?
    ) {
        self.amount = amount
        self.kind = kind
        self.category = category
        self.note = note
    }
}

public enum VoiceTransactionParser {
    public static func parse(_ transcript: String) -> VoiceTransactionParseResult? {
        let normalizedTranscript = transcript.normalizedForVoiceTransaction
        guard let amountCandidate = selectedAmountCandidate(in: transcript) else {
            return nil
        }

        let kind = kind(in: normalizedTranscript)
        return VoiceTransactionParseResult(
            amount: amountCandidate.amount,
            kind: kind,
            category: category(for: kind, normalizedTranscript: normalizedTranscript),
            note: note(in: transcript, removing: amountCandidate.range)
        )
    }

    private static func selectedAmountCandidate(in transcript: String) -> AmountCandidate? {
        let candidates = amountCandidates(in: transcript)
        if let unitCandidate = candidates.first(where: { $0.hasUnit }) {
            return unitCandidate
        }

        return candidates.max { lhs, rhs in
            lhs.amount < rhs.amount
        }
    }

    private static func amountCandidates(in transcript: String) -> [AmountCandidate] {
        matches(
            in: transcript,
            pattern: #"(?<!\d)(\d+(?:[.,]\d+)?)(?:\s*(nghìn|nghin|ngàn|ngan|k|triệu|trieu|m|đồng|dong|vnd))?(?!\d)"#
        ).compactMap { match in
            guard
                let amountText = match.capture(at: 0),
                let baseAmount = decimal(from: amountText)
            else {
                return nil
            }

            let normalizedUnit = match.capture(at: 1)?.normalizedForVoiceTransaction
            let multiplier = multiplier(for: normalizedUnit)
            let amount = baseAmount * multiplier
            guard amount > 0 else {
                return nil
            }

            return AmountCandidate(
                amount: amount,
                range: match.range,
                hasUnit: normalizedUnit != nil
            )
        }
    }

    private static func kind(in normalizedTranscript: String) -> TransactionKind {
        if containsKeyword(in: normalizedTranscript, keywords: incomeKeywords) {
            return .income
        }

        return .expense
    }

    private static func category(
        for kind: TransactionKind,
        normalizedTranscript: String
    ) -> TransactionCategory {
        switch kind {
        case .income:
            .salary
        case .expense:
            if containsKeyword(in: normalizedTranscript, keywords: foodKeywords) {
                .food
            } else if containsKeyword(in: normalizedTranscript, keywords: transportKeywords) {
                .transport
            } else if containsKeyword(in: normalizedTranscript, keywords: housingKeywords) {
                .housing
            } else if containsKeyword(in: normalizedTranscript, keywords: entertainmentKeywords) {
                .entertainment
            } else if containsKeyword(in: normalizedTranscript, keywords: healthKeywords) {
                .health
            } else if containsKeyword(in: normalizedTranscript, keywords: educationKeywords) {
                .education
            } else if containsKeyword(in: normalizedTranscript, keywords: shoppingKeywords) {
                .shopping
            } else {
                .other
            }
        }
    }

    private static func note(
        in transcript: String,
        removing range: Range<String.Index>
    ) -> String? {
        var note = transcript
        note.removeSubrange(range)
        let normalizedNote = note
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-+|,;: "))

        return normalizedNote.isEmpty ? nil : normalizedNote
    }

    private static func decimal(from amountText: String) -> Decimal? {
        Decimal(
            string: amountText.replacingOccurrences(of: ",", with: "."),
            locale: Locale(identifier: "en_US_POSIX")
        )
    }

    private static func multiplier(for normalizedUnit: String?) -> Decimal {
        switch normalizedUnit {
        case "nghin", "ngan", "k":
            Decimal(1_000)
        case "trieu", "m":
            Decimal(1_000_000)
        default:
            Decimal(1)
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
        in normalizedTranscript: String,
        keywords: [String]
    ) -> Bool {
        keywords.contains { normalizedTranscript.contains($0) }
    }

    private static let incomeKeywords = [
        "luong",
        "thu nhap",
        "nhan tien",
        "duoc tra",
        "salary",
        "income",
    ]
    private static let foodKeywords = [
        "an sang",
        "an trua",
        "an toi",
        "an vat",
        "ca phe",
        "cafe",
        "coffee",
        "com",
        "pho",
        "bun",
        "tra sua",
        "grabfood",
        "shopeefood",
    ]
    private static let transportKeywords = [
        "grab",
        "taxi",
        "bike",
        "bus",
        "xang",
        "gojek",
        "di lam",
        "ve xe",
    ]
    private static let housingKeywords = [
        "tien nha",
        "dien",
        "nuoc",
        "internet",
        "wifi",
        "rent",
    ]
    private static let entertainmentKeywords = [
        "netflix",
        "spotify",
        "xem phim",
        "rap phim",
        "game",
    ]
    private static let healthKeywords = [
        "benh vien",
        "phong kham",
        "nha thuoc",
        "thuoc",
        "doctor",
        "clinic",
    ]
    private static let educationKeywords = [
        "hoc phi",
        "khoa hoc",
        "sach",
        "book",
        "course",
    ]
    private static let shoppingKeywords = [
        "shopee",
        "lazada",
        "tiki",
        "mua sam",
        "shopping",
        "winmart",
    ]
}

private struct AmountCandidate: Equatable {
    let amount: Decimal
    let range: Range<String.Index>
    let hasUnit: Bool
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

private extension String {
    var normalizedForVoiceTransaction: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "vi_VN"))
            .lowercased()
    }
}
