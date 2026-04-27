import Foundation
import TransactionDomain

public enum AnonymousBenchmarkDataset {
    public static func benchmarkAmount(
        category: TransactionCategory,
        profile: AnonymousBenchmarkProfile
    ) -> Decimal {
        let baseIncome = profile.incomeBand.representativeIncome
        let share = categoryShare(category)
        let multiplier = profile.city.costMultiplier * profile.ageGroup.behaviorMultiplier(for: category)
        return roundedToThousands(baseIncome * share * multiplier)
    }

    private static func categoryShare(_ category: TransactionCategory) -> Decimal {
        switch category.id {
        case TransactionCategory.food.id:
            Decimal(string: "0.18") ?? 0.18
        case TransactionCategory.transport.id:
            Decimal(string: "0.08") ?? 0.08
        case TransactionCategory.housing.id:
            Decimal(string: "0.26") ?? 0.26
        case TransactionCategory.entertainment.id:
            Decimal(string: "0.07") ?? 0.07
        case TransactionCategory.health.id:
            Decimal(string: "0.05") ?? 0.05
        case TransactionCategory.education.id:
            Decimal(string: "0.06") ?? 0.06
        case TransactionCategory.shopping.id:
            Decimal(string: "0.10") ?? 0.10
        default:
            Decimal(string: "0.06") ?? 0.06
        }
    }

    private static func roundedToThousands(_ amount: Decimal) -> Decimal {
        let roundedValue = (NSDecimalNumber(decimal: amount).doubleValue / 1_000).rounded() * 1_000
        return Decimal(Int(roundedValue))
    }
}

private extension AnonymousBenchmarkIncomeBand {
    var representativeIncome: Decimal {
        switch self {
        case .underTenMillion:
            8_000_000
        case .tenToTwentyMillion:
            15_000_000
        case .twentyToFortyMillion:
            30_000_000
        case .overFortyMillion:
            55_000_000
        }
    }
}

private extension AnonymousBenchmarkCity {
    var costMultiplier: Decimal {
        switch self {
        case .hoChiMinh:
            Decimal(string: "1.12") ?? 1.12
        case .haNoi:
            Decimal(string: "1.06") ?? 1.06
        case .daNang:
            Decimal(string: "0.92") ?? 0.92
        case .otherUrban:
            Decimal(string: "0.84") ?? 0.84
        }
    }
}

private extension AnonymousBenchmarkAgeGroup {
    func behaviorMultiplier(for category: TransactionCategory) -> Decimal {
        switch (self, category.id) {
        case (.underTwentyFive, TransactionCategory.entertainment.id),
             (.underTwentyFive, TransactionCategory.food.id):
            Decimal(string: "1.12") ?? 1.12
        case (.twentyFiveToThirtyFour, TransactionCategory.transport.id),
             (.twentyFiveToThirtyFour, TransactionCategory.shopping.id):
            Decimal(string: "1.08") ?? 1.08
        case (.thirtyFiveToFortyFour, TransactionCategory.housing.id),
             (.thirtyFiveToFortyFour, TransactionCategory.education.id):
            Decimal(string: "1.15") ?? 1.15
        case (.fortyFivePlus, TransactionCategory.health.id):
            Decimal(string: "1.25") ?? 1.25
        default:
            1
        }
    }
}
