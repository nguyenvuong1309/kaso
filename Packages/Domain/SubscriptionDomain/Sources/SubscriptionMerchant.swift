import Foundation
import TransactionDomain

public enum SubscriptionMerchantSource: String, Codable, Equatable, Hashable, Sendable {
    case note
    case category
}

public struct SubscriptionMerchant: Codable, Equatable, Hashable, Sendable {
    public var name: String
    public var normalizedKey: String
    public var source: SubscriptionMerchantSource

    public init(
        name: String,
        normalizedKey: String,
        source: SubscriptionMerchantSource
    ) {
        self.name = name
        self.normalizedKey = normalizedKey
        self.source = source
    }
}

enum SubscriptionMerchantExtractor {
    static func merchant(from transaction: Transaction) -> SubscriptionMerchant {
        if let note = transaction.note?.trimmingCharacters(in: .whitespacesAndNewlines),
           !note.isEmpty,
           let merchant = merchant(fromNote: note) {
            return merchant
        }

        return SubscriptionMerchant(
            name: transaction.category.nameKey,
            normalizedKey: "category:\(transaction.category.id)",
            source: .category
        )
    }

    private static func merchant(fromNote note: String) -> SubscriptionMerchant? {
        let tokenInfos = noteTokens(from: note)
        let meaningfulTokens = tokenInfos.filter { tokenInfo in
            !isStopWord(tokenInfo.normalized)
                && !tokenInfo.normalized.isEmpty
                && !tokenInfo.containsDigit
        }

        let normalizedTokens = meaningfulTokens.map(\.normalized)
        let normalizedKey = normalizedTokens.joined(separator: " ")

        guard !normalizedKey.isEmpty else {
            let fallbackKey = normalized(note)
            guard !fallbackKey.isEmpty else {
                return nil
            }

            return SubscriptionMerchant(
                name: note,
                normalizedKey: "note:\(fallbackKey)",
                source: .note
            )
        }

        let displayName = meaningfulTokens
            .prefix(4)
            .map(\.raw)
            .joined(separator: " ")

        return SubscriptionMerchant(
            name: displayName,
            normalizedKey: "note:\(normalizedKey)",
            source: .note
        )
    }

    private static func noteTokens(from note: String) -> [NoteToken] {
        note
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .compactMap { component -> NoteToken? in
                let rawToken = component.trimmingCharacters(in: .whitespacesAndNewlines)

                guard !rawToken.isEmpty else {
                    return nil
                }

                let normalizedToken = normalized(rawToken)

                guard !normalizedToken.isEmpty else {
                    return nil
                }

                return NoteToken(
                    raw: rawToken,
                    normalized: normalizedToken,
                    containsDigit: rawToken.rangeOfCharacter(from: .decimalDigits) != nil
                )
            }
    }

    private static func normalized(_ string: String) -> String {
        string
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "vi_VN"))
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func isStopWord(_ token: String) -> Bool {
        stopWords.contains(token)
    }

    private static let stopWords: Set<String> = [
        "annual",
        "auto",
        "autopay",
        "bill",
        "charged",
        "dang",
        "dich",
        "dinh",
        "fee",
        "gia",
        "goi",
        "han",
        "hang",
        "hoi",
        "membership",
        "monthly",
        "nam",
        "paid",
        "pay",
        "payment",
        "premium",
        "renew",
        "renewal",
        "sub",
        "subscription",
        "thanh",
        "thang",
        "tien",
        "tru",
        "tuan",
        "vien",
        "vnd",
        "vu",
        "weekly",
        "yearly",
        "jan",
        "january",
        "feb",
        "february",
        "mar",
        "march",
        "apr",
        "april",
        "may",
        "jun",
        "june",
        "jul",
        "july",
        "aug",
        "august",
        "sep",
        "september",
        "oct",
        "october",
        "nov",
        "november",
        "dec",
        "december",
    ]
}

private struct NoteToken: Equatable, Sendable {
    var raw: String
    var normalized: String
    var containsDigit: Bool
}
