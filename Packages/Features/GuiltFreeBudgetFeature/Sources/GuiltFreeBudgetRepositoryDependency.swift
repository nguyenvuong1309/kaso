import ComposableArchitecture
import GuiltFreeBudgetDomain

private enum GuiltFreeBudgetRepositoryKey: DependencyKey {
    static let liveValue = GuiltFreeBudgetRepository.empty
    static let previewValue = GuiltFreeBudgetRepository.preview
    static let testValue = GuiltFreeBudgetRepository.empty
}

public extension GuiltFreeBudgetRepository {
    static let preview = GuiltFreeBudgetRepository(
        load: {
            GuiltFreeBudgetConfiguration(
                monthlyIncome: 25_000_000,
                monthlySavingsTarget: 5_000_000,
                emergencyFundMonthlyContribution: 1_000_000,
                fixedCosts: [
                    GuiltFreeFixedCost(name: "Tiền nhà", amount: 8_000_000, kind: .housing),
                    GuiltFreeFixedCost(name: "Điện nước", amount: 1_200_000, kind: .utilities),
                    GuiltFreeFixedCost(name: "Internet", amount: 250_000, kind: .utilities),
                ]
            )
        },
        save: { _ in }
    )
}

public extension DependencyValues {
    var guiltFreeBudgetRepository: GuiltFreeBudgetRepository {
        get { self[GuiltFreeBudgetRepositoryKey.self] }
        set { self[GuiltFreeBudgetRepositoryKey.self] = newValue }
    }
}
