import Foundation
import Testing
import TransactionDomain
@testable import SubscriptionDomain

@Test("merchant value type round-trips through Codable")
func merchantCodableRoundTrip() throws {
    let merchant = SubscriptionMerchant(
        name: "Netflix Premium",
        normalizedKey: "note:netflix premium",
        source: .note
    )
    let encoded = try JSONEncoder().encode(merchant)
    let decoded = try JSONDecoder().decode(SubscriptionMerchant.self, from: encoded)
    #expect(decoded == merchant)
}

@Test("merchant source raw values are stable")
func merchantSourceRawValues() {
    #expect(SubscriptionMerchantSource.note.rawValue == "note")
    #expect(SubscriptionMerchantSource.category.rawValue == "category")
}

@Test("extractor derives merchant from note tokens and drops stop words and digits")
func extractorDerivesMerchantFromNote() throws {
    let transaction = expense(note: "Netflix Premium Jan 2026")
    let merchant = SubscriptionMerchantExtractor.merchant(from: transaction)

    #expect(merchant.source == .note)
    // "Premium", "Jan", and "2026" are stop words / digit tokens; only "Netflix" remains.
    #expect(merchant.name == "Netflix")
    #expect(merchant.normalizedKey == "note:netflix")
}

@Test("extractor keeps up to four meaningful tokens in the display name")
func extractorLimitsDisplayNameTokens() {
    let transaction = expense(note: "Adobe Creative Cloud Photography Plan Pro")
    let merchant = SubscriptionMerchantExtractor.merchant(from: transaction)

    #expect(merchant.source == .note)
    // None of these are stop words; prefix(4) limits the display name to four tokens.
    #expect(merchant.name == "Adobe Creative Cloud Photography")
    #expect(merchant.normalizedKey == "note:adobe creative cloud photography plan pro")
}

@Test("extractor folds diacritics and lowercases the normalized key")
func extractorFoldsDiacritics() {
    let transaction = expense(note: "Spotify Cá Nhân")
    let merchant = SubscriptionMerchantExtractor.merchant(from: transaction)

    #expect(merchant.source == .note)
    #expect(merchant.name == "Spotify Cá Nhân")
    #expect(merchant.normalizedKey == "note:spotify ca nhan")
}

@Test("extractor groups two notes with same normalized key despite casing and punctuation")
func extractorNormalizationGroupsEquivalentNotes() {
    let first = SubscriptionMerchantExtractor.merchant(from: expense(note: "Netflix"))
    let second = SubscriptionMerchantExtractor.merchant(from: expense(note: "netflix!"))

    #expect(first.normalizedKey == second.normalizedKey)
}

@Test("extractor falls back to raw note when only stop words remain")
func extractorFallsBackToRawNoteWhenAllStopWords() {
    let transaction = expense(note: "Monthly Subscription Payment")
    let merchant = SubscriptionMerchantExtractor.merchant(from: transaction)

    #expect(merchant.source == .note)
    // All tokens are stop words, so normalizedKey collapses; fallback keeps the raw note.
    #expect(merchant.name == "Monthly Subscription Payment")
    #expect(merchant.normalizedKey == "note:monthly subscription payment")
}

@Test("extractor uses category when note is nil")
func extractorUsesCategoryWhenNoteIsNil() {
    let transaction = expense(category: .housing, note: nil)
    let merchant = SubscriptionMerchantExtractor.merchant(from: transaction)

    #expect(merchant.source == .category)
    #expect(merchant.name == TransactionCategory.housing.nameKey)
    #expect(merchant.normalizedKey == "category:housing")
}

@Test("extractor uses category when note is blank whitespace")
func extractorUsesCategoryWhenNoteIsBlank() {
    let transaction = expense(category: .entertainment, note: "   \n  ")
    let merchant = SubscriptionMerchantExtractor.merchant(from: transaction)

    #expect(merchant.source == .category)
    #expect(merchant.normalizedKey == "category:entertainment")
}

@Test("extractor uses category when note has only punctuation")
func extractorUsesCategoryWhenNoteHasOnlyPunctuation() {
    let transaction = expense(category: .food, note: "!!! ??? ---")
    let merchant = SubscriptionMerchantExtractor.merchant(from: transaction)

    #expect(merchant.source == .category)
    #expect(merchant.normalizedKey == "category:food")
}

private func expense(
    category: TransactionCategory = .entertainment,
    note: String?
) -> Transaction {
    Transaction(
        amount: 100_000,
        kind: .expense,
        category: category,
        occurredAt: Date(timeIntervalSince1970: 0),
        note: note
    )
}
