import ComposableArchitecture
import FreelancerDomain

private enum FreelancerProfileRepositoryKey: DependencyKey {
    static let liveValue = FreelancerProfileRepository.empty
    static let previewValue = FreelancerProfileRepository.preview
    static let testValue = FreelancerProfileRepository.empty
}

public extension FreelancerProfileRepository {
    static let preview = FreelancerProfileRepository(
        load: {
            FreelancerProfile(
                monthlyIncomes: [
                    MonthlyIncome(month: YearMonth(year: 2026, month: 1), grossAmount: 12_000_000),
                    MonthlyIncome(month: YearMonth(year: 2026, month: 2), grossAmount: 18_000_000),
                    MonthlyIncome(month: YearMonth(year: 2026, month: 3), grossAmount: 14_000_000),
                    MonthlyIncome(month: YearMonth(year: 2026, month: 4), grossAmount: 26_000_000),
                ],
                bufferBalance: 28_000_000,
                bufferTargetMultiplier: 2,
                workType: .freelancer,
                taxRate: 0.1
            )
        },
        save: { _ in }
    )
}

public extension DependencyValues {
    var freelancerProfileRepository: FreelancerProfileRepository {
        get { self[FreelancerProfileRepositoryKey.self] }
        set { self[FreelancerProfileRepositoryKey.self] = newValue }
    }
}
