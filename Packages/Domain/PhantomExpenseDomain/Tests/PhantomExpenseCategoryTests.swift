import Foundation
import Testing
@testable import PhantomExpenseDomain

@Test("category exposes all seven cases")
func categoryAllCases() {
    #expect(PhantomExpenseCategory.allCases.count == 7)
    #expect(Set(PhantomExpenseCategory.allCases) == [
        .cart,
        .trip,
        .subscription,
        .shopping,
        .foodDrink,
        .entertainment,
        .other,
    ])
}

@Test("category id equals raw value")
func categoryIdEqualsRawValue() {
    for category in PhantomExpenseCategory.allCases {
        #expect(category.id == category.rawValue)
    }
}

@Test("category nameKey is namespaced by raw value")
func categoryNameKey() {
    #expect(PhantomExpenseCategory.cart.nameKey == "phantom.category.cart")
    #expect(PhantomExpenseCategory.foodDrink.nameKey == "phantom.category.foodDrink")
    #expect(PhantomExpenseCategory.other.nameKey == "phantom.category.other")
}

@Test("category symbolName maps each case")
func categorySymbolName() {
    #expect(PhantomExpenseCategory.cart.symbolName == "cart.badge.minus")
    #expect(PhantomExpenseCategory.trip.symbolName == "airplane.departure")
    #expect(PhantomExpenseCategory.subscription.symbolName == "repeat.circle")
    #expect(PhantomExpenseCategory.shopping.symbolName == "bag")
    #expect(PhantomExpenseCategory.foodDrink.symbolName == "cup.and.saucer")
    #expect(PhantomExpenseCategory.entertainment.symbolName == "gamecontroller")
    #expect(PhantomExpenseCategory.other.symbolName == "sparkles")
}

@Test("category colorName maps each case")
func categoryColorName() {
    #expect(PhantomExpenseCategory.cart.colorName == "blue")
    #expect(PhantomExpenseCategory.trip.colorName == "mint")
    #expect(PhantomExpenseCategory.subscription.colorName == "purple")
    #expect(PhantomExpenseCategory.shopping.colorName == "pink")
    #expect(PhantomExpenseCategory.foodDrink.colorName == "orange")
    #expect(PhantomExpenseCategory.entertainment.colorName == "indigo")
    #expect(PhantomExpenseCategory.other.colorName == "green")
}

@Test("category survives Codable round-trip via raw value")
func categoryCodableRoundTrip() throws {
    for category in PhantomExpenseCategory.allCases {
        let data = try JSONEncoder().encode(category)
        let decoded = try JSONDecoder().decode(PhantomExpenseCategory.self, from: data)
        #expect(decoded == category)
    }
}

@Test("category decodes from known raw value")
func categoryDecodesRawValue() throws {
    let data = Data("\"subscription\"".utf8)
    let decoded = try JSONDecoder().decode(PhantomExpenseCategory.self, from: data)
    #expect(decoded == .subscription)
}
