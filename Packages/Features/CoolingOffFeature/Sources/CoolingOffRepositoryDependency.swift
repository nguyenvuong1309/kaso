import ComposableArchitecture
import CoolingOffDomain
import Foundation

private enum PurchasePlanRepositoryKey: DependencyKey {
    static let liveValue = PurchasePlanRepository.empty
    static let previewValue = PurchasePlanRepository.preview
    static let testValue = PurchasePlanRepository.empty
}

public extension PurchasePlanRepository {
    static let preview = PurchasePlanRepository(
        fetchAll: {
            let now = Date()
            return [
                PurchasePlan(
                    title: "AirPods Pro 2",
                    amount: 6_300_000,
                    category: .electronics,
                    coolingPeriod: .oneWeek,
                    status: .waiting,
                    createdAt: now.addingTimeInterval(-2 * 86_400),
                    availableAt: now.addingTimeInterval(5 * 86_400)
                ),
                PurchasePlan(
                    title: "Sneaker phối đồ",
                    amount: 2_100_000,
                    category: .fashion,
                    coolingPeriod: .threeDays,
                    status: .waiting,
                    createdAt: now.addingTimeInterval(-4 * 86_400),
                    availableAt: now.addingTimeInterval(-86_400)
                ),
                PurchasePlan(
                    title: "Console game",
                    amount: 11_000_000,
                    category: .entertainment,
                    coolingPeriod: .twoWeeks,
                    status: .cancelled,
                    createdAt: now.addingTimeInterval(-15 * 86_400),
                    availableAt: now.addingTimeInterval(-86_400),
                    decisionAt: now.addingTimeInterval(-86_400)
                ),
            ]
        },
        save: { _ in },
        delete: { _ in },
        loadPolicy: { .default },
        savePolicy: { _ in }
    )
}

public extension DependencyValues {
    var purchasePlanRepository: PurchasePlanRepository {
        get { self[PurchasePlanRepositoryKey.self] }
        set { self[PurchasePlanRepositoryKey.self] = newValue }
    }
}
