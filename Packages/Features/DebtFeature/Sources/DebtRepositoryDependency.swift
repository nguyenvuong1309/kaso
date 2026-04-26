import ComposableArchitecture
import DebtDomain

private enum DebtRepositoryKey: DependencyKey {
    static let liveValue = DebtRepository.empty
    static let previewValue = DebtRepository.preview
    static let testValue = DebtRepository.empty
}

public extension DebtRepository {
    static let preview = DebtRepository(
        fetchAll: {
            [
                Debt(
                    name: "Vay mua nhà",
                    type: .mortgage,
                    principal: 1_000_000_000,
                    annualInterestRatePercent: 8,
                    termMonths: 240,
                    startDate: .now,
                    paymentDay: 5
                ),
            ]
        },
        save: { _ in },
        delete: { _ in }
    )
}

public extension DependencyValues {
    var debtRepository: DebtRepository {
        get { self[DebtRepositoryKey.self] }
        set { self[DebtRepositoryKey.self] = newValue }
    }
}
